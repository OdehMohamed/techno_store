import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:techno_store/core/services/firebase_storage_services.dart';
import 'package:techno_store/core/utils/firestore_api_path.dart';
import 'package:techno_store/core/utils/storage_api_path.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';
import 'package:techno_store/core/model/maintenance_device_sensitive_data.dart';

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

  Future<String> addNewDevice(
    MaintenanceDeviceModel device, {
    MaintenanceDeviceSensitiveData? sensitiveData,
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

      // Sensitive fields (pin, patternLock, notesHidden) go to a separate
      // subdocument, never inline on the device document — see
      // docs/ai-workflow/ADR-001-sensitive-data-separation.md. Written in
      // the same batch as the parent document so a device is never left in
      // a partially-written state.
      final batch = _firestoreInstance.batch();
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
