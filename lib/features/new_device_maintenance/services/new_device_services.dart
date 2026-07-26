import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:techno_store/core/services/firebase_storage_services.dart';
import 'package:techno_store/core/utils/firestore_api_path.dart';
import 'package:techno_store/core/utils/storage_api_path.dart';
import 'package:techno_store/core/model/device_model.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';
import 'package:techno_store/core/model/maintenance_device_sensitive_data.dart';
import 'package:techno_store/features/new_device_maintenance/services/device_services.dart';

/// The canonical-Device attributes needed to create a brand-new
/// `devices/{id}` record atomically alongside its first Visit — see
/// NewDeviceServices.addNewDevice. Not a full DeviceModel: id/timestamps
/// are resolved by the write itself, not supplied by the caller.
class NewDeviceInput {
  final String? brand;
  final String model;
  final String colorHex;
  final String? imeiNumber;

  NewDeviceInput({
    this.brand,
    required this.model,
    required this.colorHex,
    this.imeiNumber,
  });
}

class NewDeviceServices {
  final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;
  final FirebaseStorageServices _storageServices =
      FirebaseStorageServices.instance;

  bool _isRemoteImageUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<List<String>?> _prepareImagesForSave({
    required String deviceId,
    required List<String>? images,
    required String folder,
  }) async {
    if (images == null) return null;

    final preparedImages = <String>[];

    for (final imagePath in images) {
      final normalizedPath = imagePath.trim();
      if (normalizedPath.isEmpty) continue;

      if (_isRemoteImageUrl(normalizedPath)) {
        preparedImages.add(normalizedPath);
        continue;
      }

      final file = File(normalizedPath);
      if (!file.existsSync()) {
        debugPrint('⚠️ Skipping missing local image: $normalizedPath');
        continue;
      }

      final uploadedUrl = await _storageServices.uploadFile(
        file: file,
        folderPath: StorageApiPath.maintenanceImages(deviceId, folder),
      );

      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        throw Exception('Failed to upload image: $normalizedPath');
      }

      preparedImages.add(uploadedUrl);
    }

    return preparedImages;
  }

  /// [existingDeviceId] and [newDeviceInput] are mutually exclusive — at
  /// most one should be provided by the caller (the intake screen's Save
  /// validation enforces that staff has made an explicit Existing/Create
  /// New choice before this is ever called; this method doesn't
  /// re-validate that itself). When [newDeviceInput] is given, the new
  /// `devices/{id}` document is generated and written in the *same*
  /// WriteBatch as the Visit (and sensitive-data subdocument, if any) —
  /// ADR-007's `deviceId` is set only at Visit creation, so this is the
  /// one place a genuinely new Device and its first Visit can be created
  /// together; two independent commits here would risk a real orphaned
  /// Device if the second one failed after the first succeeded. Neither
  /// the `devices` nor the `maintenanceDevices` create rule depends on
  /// reading the other collection, so a plain batch (not a transaction —
  /// nothing here needs to be read back mid-write) is sufficient for true
  /// atomicity.
  Future<String> addNewDevice(
    MaintenanceDeviceModel device, {
    MaintenanceDeviceSensitiveData? sensitiveData,
    String? existingDeviceId,
    NewDeviceInput? newDeviceInput,
  }) async {
    try {
      final docRef = _firestoreInstance.collection('maintenanceDevices').doc();

      final deviceId = docRef.id;

      final beforeReceivingImages = await _prepareImagesForSave(
        deviceId: deviceId,
        images: device.imagesBeforeReceiving,
        folder: 'before_receiving',
      );
      final afterDeliveryImages = await _prepareImagesForSave(
        deviceId: deviceId,
        images: device.imagesAfterDelivery,
        folder: 'after_delivery',
      );

      final userID = await getUserIdByPhoneNumber(device.phoneNumber);
      device = device.copyWith(
        userId: userID,
        imagesBeforeReceiving: beforeReceivingImages,
        imagesAfterDelivery: afterDeliveryImages,
      );

      final batch = _firestoreInstance.batch();

      String? linkedDeviceId = existingDeviceId;
      if (existingDeviceId == null && newDeviceInput != null) {
        final deviceRef =
            _firestoreInstance.collection(FirestoreApiPath.devices()).doc();
        linkedDeviceId = deviceRef.id;
        batch.set(deviceRef, {
          if (newDeviceInput.brand != null &&
              newDeviceInput.brand!.trim().isNotEmpty)
            'brand': newDeviceInput.brand!.trim(),
          'model': newDeviceInput.model,
          'colorHex': newDeviceInput.colorHex,
          ...DeviceServices.buildImeiFields(newDeviceInput.imeiNumber),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      if (linkedDeviceId != null) {
        device = device.copyWith(deviceId: linkedDeviceId);
      }

      // Sensitive fields (pin, patternLock, notesHidden) go to a separate
      // subdocument, never inline on the device document — see
      // docs/ai-workflow/ADR-001-sensitive-data-separation.md. Written in
      // the same batch as the parent document so a device is never left in
      // a partially-written state.
      batch.set(docRef, device.toJson());
      if (sensitiveData != null && sensitiveData.hasAnyValue) {
        final sensitiveRef = _firestoreInstance.doc(
          FirestoreApiPath.maintenanceDeviceSensitiveData(deviceId),
        );
        batch.set(sensitiveRef, sensitiveData.toMap());
      }
      await batch.commit();

      // if (device.userId != null) {
      //   await _firestoreServices.setData(
      //     path: FirestoreApiPath.userDevice(device.userId!, deviceId),
      //     data: device.toJson(),
      //   );
      // }
      debugPrint('✅ Device added successfully with ID: $deviceId');
      return deviceId;
    } catch (e) {
      debugPrint('❌ Error adding device: $e');
      rethrow;
    }
  }

  /// ADR-007 Device Matching Policy's customer-known-Devices pathway.
  /// Two reads: this customer's Visits (any recordState — device history
  /// is a historical fact independent of active-workflow visibility, and
  /// omitting that filter also keeps this a single-field equality query
  /// needing no composite index), then a batch-fetch of the distinct
  /// linked Devices, chunked to Firestore's 30-value `in` limit — chunking
  /// is explicit, not assumed unnecessary, since silently dropping
  /// candidates past the 30th would be a real correctness bug.
  Future<List<DeviceModel>> getKnownDevicesForCustomer(String userId) async {
    final visitsSnapshot = await _firestoreInstance
        .collection(FirestoreApiPath.maintenanceDevices())
        .where('userId', isEqualTo: userId)
        // Defensive bound against a pathological case, mirroring
        // streamDevicesForTab's own limit(50) — not a business rule.
        .limit(200)
        .get();

    final deviceIds = <String>{};
    for (final doc in visitsSnapshot.docs) {
      final deviceId = doc.data()['deviceId'] as String?;
      if (deviceId != null) deviceIds.add(deviceId);
    }
    if (deviceIds.isEmpty) return [];

    final devices = <DeviceModel>[];
    for (final chunk in chunkIds(deviceIds.toList())) {
      final snapshot = await _firestoreInstance
          .collection(FirestoreApiPath.devices())
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      devices.addAll(
        snapshot.docs.map((doc) => DeviceModel.fromMap(doc.data(), doc.id)),
      );
    }
    return devices;
  }

  /// Splits into groups of at most [chunkSize] (Firestore's `whereIn`/`in`
  /// limit, 30 by default) — extracted as a pure function so this
  /// explicitly-required chunking (see ADR-007 Addendum, Read 2) has a
  /// direct unit test, not just implicit coverage buried inside a
  /// Firestore-calling method.
  static List<List<String>> chunkIds(List<String> ids, {int chunkSize = 30}) {
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize < ids.length) ? i + chunkSize : ids.length;
      chunks.add(ids.sublist(i, end));
    }
    return chunks;
  }

  Future<String?> getUserIdByPhoneNumber(String phoneNumber) async {
    try {
      final querySnapshot = await _firestoreInstance
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      } else {
        debugPrint('⚠️ No user found with phone number: $phoneNumber');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching user ID: $e');
      return null;
    }
  }

  Future<void> updateDevice(
    String deviceId,
    MaintenanceDeviceModel device, {
    MaintenanceDeviceSensitiveData? sensitiveData,
  }) async {
    try {
      final beforeReceivingImages = await _prepareImagesForSave(
        deviceId: deviceId,
        images: device.imagesBeforeReceiving,
        folder: 'before_receiving',
      );
      final afterDeliveryImages = await _prepareImagesForSave(
        deviceId: deviceId,
        images: device.imagesAfterDelivery,
        folder: 'after_delivery',
      );

      final userID = await getUserIdByPhoneNumber(device.phoneNumber);
      device = device.copyWith(
        userId: userID,
        imagesBeforeReceiving: beforeReceivingImages,
        imagesAfterDelivery: afterDeliveryImages,
      );

      final docRef = _firestoreInstance.collection('maintenanceDevices').doc(deviceId);

      final batch = _firestoreInstance.batch();
      // IMPORTANT: merge, not overwrite. MaintenanceDeviceModel.toJson() no
      // longer includes pin/patternLock/notesHidden (see ADR-001). A device
      // that hasn't been migrated to the new sensitive-data subdocument yet
      // (Phase 1C, not run) still has those fields inline on this parent
      // document. A plain `.set()` here would silently wipe them, since
      // Firestore's non-merge `set` replaces the whole document with
      // exactly what's provided. `merge: true` leaves any field not present
      // in `device.toJson()` untouched, which is what protects that legacy
      // data until the migration formally moves it.
      batch.set(docRef, device.toJson(), SetOptions(merge: true));
      if (sensitiveData != null) {
        final sensitiveRef = _firestoreInstance.doc(
          FirestoreApiPath.maintenanceDeviceSensitiveData(deviceId),
        );
        batch.set(sensitiveRef, sensitiveData.toMap());
      }
      await batch.commit();

      debugPrint('✅ Device updated successfully with ID: $deviceId');
    } catch (e) {
      debugPrint('❌ Error updating device: $e');
      rethrow;
    }
  }
}
