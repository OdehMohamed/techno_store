import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/core/model/device_tab_page.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';
import 'package:techno_store/core/model/maintenance_device_sensitive_data.dart';
import 'package:techno_store/core/services/firebase_storage_services.dart';
import 'package:techno_store/core/services/firestore_services.dart';
import 'package:techno_store/core/services/maintenance_device_sensitive_data_service.dart';
import 'package:techno_store/core/utils/firestore_api_path.dart';
import 'package:techno_store/core/utils/storage_api_path.dart';

// Constants for device status
class DeviceStatus {
  static const String inMaintenance = 'In Maintenance';
  static const String fixed = 'Fixed';
  static const String delivered = 'Delivered';
}

class MaintenanceListServices {
  final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;
  final firestoreServices = FirestoreServices.instance;
  final FirebaseStorageServices _storageServices =
      FirebaseStorageServices.instance;

  bool _isRemoteImageUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  Future<List<String>> _prepareImagesForSave({
    required String deviceId,
    required List<String> images,
    required String folder,
  }) async {
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

  DateTime? _parseDateField(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  /// Applies the shared filter set (status + at most one of
  /// brand/maintenanceEmployee/date-range, plus optional customer [uid]
  /// scoping) used by both [streamDevicesForTab] and
  /// [fetchMoreDevicesForTab]. See
  /// docs/ai-workflow/SEARCH_FILTER_IMPLEMENTATION_PLAN.md.
  ///
  /// [uid] scopes to one customer's own devices via the `userId` field on
  /// the real `maintenanceDevices` collection — NOT the dormant
  /// `users/{uid}/devices` subcollection (nothing in this app populates
  /// that; see BACKLOG.md item 4). Getting this wrong silently returns an
  /// empty result for every customer, which is exactly the bug this
  /// replaces (the old `fetchDevicesByStatus` queried that subcollection).
  ///
  /// `receivedAt` is stored as an ISO 8601 string, not a Firestore
  /// Timestamp, so the date-range filter compares strings — this only
  /// sorts/matches correctly because every write in this codebase already
  /// uses `DateTime.toIso8601String()` consistently (same local-time
  /// format, no timezone offset mixed in). The range reuses the
  /// status+receivedAt composite index; no separate index is needed for it.
  Query<Map<String, dynamic>> _deviceTabQuery({
    required String status,
    String? uid,
    String? brand,
    String? maintenanceEmployee,
    DateTime? receivedFrom,
    DateTime? receivedTo,
  }) {
    Query<Map<String, dynamic>> query = _firestoreInstance
        .collection(FirestoreApiPath.maintenanceDevices())
        .where('status', isEqualTo: status);

    if (uid != null) {
      query = query.where('userId', isEqualTo: uid);
    }
    if (brand != null) {
      query = query.where('brand', isEqualTo: brand);
    }
    if (maintenanceEmployee != null) {
      query =
          query.where('maintenanceEmployee', isEqualTo: maintenanceEmployee);
    }
    if (receivedFrom != null) {
      query = query.where(
        'receivedAt',
        isGreaterThanOrEqualTo: receivedFrom.toIso8601String(),
      );
    }
    if (receivedTo != null) {
      query = query.where(
        'receivedAt',
        isLessThanOrEqualTo: receivedTo.toIso8601String(),
      );
    }

    return query;
  }

  DeviceTabPage _toDeviceTabPage(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return DeviceTabPage(
      devices: snapshot.docs
          .map((doc) => MaintenanceDeviceModel.fromMap(doc.data(), doc.id))
          .toList(),
      lastDocument: snapshot.docs.isEmpty ? null : snapshot.docs.last,
    );
  }

  /// Bounded, real-time listener for one status tab, optionally narrowed by
  /// at most one structured filter (brand, maintenanceEmployee, or a
  /// receivedAt date range) — replaces the old unbounded
  /// `streamMaintenanceDevices` staff path: only the active tab/filter
  /// combination is listened to, capped at [limit], instead of the entire
  /// collection (see docs/ai-workflow/SEARCH_FILTER_IMPLEMENTATION_PLAN.md,
  /// BACKLOG.md item 1g).
  Stream<DeviceTabPage> streamDevicesForTab({
    required String status,
    String? uid,
    String? brand,
    String? maintenanceEmployee,
    DateTime? receivedFrom,
    DateTime? receivedTo,
    int limit = 50,
  }) {
    final query = _deviceTabQuery(
      status: status,
      uid: uid,
      brand: brand,
      maintenanceEmployee: maintenanceEmployee,
      receivedFrom: receivedFrom,
      receivedTo: receivedTo,
    ).orderBy('receivedAt', descending: true).limit(limit);

    return query.snapshots().map(_toDeviceTabPage);
  }

  /// One-time paginated fetch for "Load more" beyond
  /// [streamDevicesForTab]'s live window. Same filter shape; [startAfter]
  /// is the last document already loaded for this tab/filter combination
  /// (see [DeviceTabPage.lastDocument]).
  Future<DeviceTabPage> fetchMoreDevicesForTab({
    required String status,
    required QueryDocumentSnapshot<Map<String, dynamic>> startAfter,
    String? uid,
    String? brand,
    String? maintenanceEmployee,
    DateTime? receivedFrom,
    DateTime? receivedTo,
    int limit = 50,
  }) async {
    final query = _deviceTabQuery(
      status: status,
      uid: uid,
      brand: brand,
      maintenanceEmployee: maintenanceEmployee,
      receivedFrom: receivedFrom,
      receivedTo: receivedTo,
    ).orderBy('receivedAt', descending: true).startAfterDocument(startAfter).limit(limit);

    final snapshot = await query.get();
    return _toDeviceTabPage(snapshot);
  }

  /// Fetches a device's sensitive fields (pin, patternLock, notesHidden),
  /// checking the new private subdocument first and falling back to legacy
  /// inline fields for devices not yet migrated. See
  /// MaintenanceDeviceSensitiveDataService and
  /// docs/ai-workflow/ADR-001-sensitive-data-separation.md. Call only from
  /// staff-facing UI — never for a customer viewing their own device.
  Future<MaintenanceDeviceSensitiveData?> fetchSensitiveData(
    String deviceId,
  ) {
    return MaintenanceDeviceSensitiveDataService.instance.fetch(deviceId);
  }

  /// Deletes a device and everything associated with it: Storage images,
  /// the private/sensitive subdocument, and the parent document — in that
  /// order. See docs/ai-workflow/PHASE1_IMPLEMENTATION_PLAN.md "Cascade
  /// deletion behavior" for the rationale behind this ordering (a partial
  /// failure should leave only non-sensitive orphaned images, never an
  /// orphaned document containing customer data) and for why each step
  /// must be idempotent (safe to retry) rather than silently succeeding
  /// when something has already been removed.
  ///
  /// Images are deleted by their stored download URLs (read from the parent
  /// document, which is deleted last so these URLs remain retrievable on a
  /// retry) rather than by listing the device's Storage folder: Firebase
  /// Storage has no folder-delete primitive, and the "list then delete each"
  /// alternative needs a `list` permission that cannot be authorized for
  /// staff — staff detection requires a cross-service Firestore role lookup
  /// that does not resolve during `list`-operation rule evaluation. See
  /// FirebaseStorageServices.deleteFileByUrl. A consequence is that an
  /// orphaned image not referenced by the document (e.g. from a failed
  /// upload) is not discoverable here and would remain — tracked in
  /// docs/ai-workflow/BACKLOG.md.
  ///
  /// Deliberately does NOT catch-and-swallow errors: per the approved plan,
  /// a caller must know a deletion was incomplete so it can retry, rather
  /// than the UI reporting success when cleanup was only partial.
  Future<void> deleteDevice(String deviceId) async {
    final deviceSnapshot = await _firestoreInstance
        .collection(FirestoreApiPath.maintenanceDevices())
        .doc(deviceId)
        .get();
    final deviceData = deviceSnapshot.data();

    if (deviceData != null) {
      final imageUrls = <String>[
        ...?(deviceData['imagesBeforeReceiving'] as List<dynamic>?)
            ?.map((e) => e.toString()),
        ...?(deviceData['imagesAfterDelivery'] as List<dynamic>?)
            ?.map((e) => e.toString()),
      ].where((url) => url.trim().isNotEmpty);

      for (final url in imageUrls) {
        await _storageServices.deleteFileByUrl(url);
      }
    }

    await _firestoreInstance
        .doc(FirestoreApiPath.maintenanceDeviceSensitiveData(deviceId))
        .delete();

    await _firestoreInstance
        .collection(FirestoreApiPath.maintenanceDevices())
        .doc(deviceId)
        .delete();

    debugPrint('✅ Device deleted successfully (cascade): $deviceId');
  }

  Future<void> updateDeviceStatus(String deviceId, String status) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
      };

      if (status.toLowerCase() == DeviceStatus.delivered.toLowerCase()) {
        updateData['deliveredAt'] = DateTime.now().toIso8601String();
      }

      await _firestoreInstance
          .collection(FirestoreApiPath.maintenanceDevices())
          .doc(deviceId)
          .update(updateData);
      debugPrint('✅ Device status updated successfully: $deviceId to $status');
    } catch (e) {
      debugPrint('❌ Error updating device status: $e');
      rethrow;
    }
  }

  Future<void> updateDeviceAsFixed({
    required String deviceId,
    required String maintenanceEmployee,
    required double? price,
    required List<String> installedPartCodes,
  }) async {
    try {
      final deviceRef = _firestoreInstance
          .collection(FirestoreApiPath.maintenanceDevices())
          .doc(deviceId);

      final deviceSnapshot = await deviceRef.get();
      final data = deviceSnapshot.data();
      final receivedAt = _parseDateField(data?['receivedAt']);
      final fixedAt = DateTime.now();

      DateTime? timeToFix;
      if (receivedAt != null) {
        final diff = fixedAt.difference(receivedAt);
        final safeDiff = diff.isNegative ? Duration.zero : diff;

        // Store elapsed time as a DateTime anchored to Unix epoch.
        timeToFix = DateTime.fromMillisecondsSinceEpoch(
          safeDiff.inMilliseconds,
          isUtc: true,
        );
      }

      await deviceRef.update({
        'status': DeviceStatus.fixed,
        'maintenanceEmployee': maintenanceEmployee,
        'price': price,
        'installedPartCodes': installedPartCodes,
        'fixedAt': fixedAt.toIso8601String(),
        'timeToFix': timeToFix?.toIso8601String(),
      });

      debugPrint('✅ Device moved to Fixed with employee and price: $deviceId');
    } catch (e) {
      debugPrint('❌ Error updating fixed data: $e');
      rethrow;
    }
  }

  Future<void> updateFixedDeviceDetails({
    required String deviceId,
    required String maintenanceEmployee,
    required double? price,
    required List<String> installedPartCodes,
  }) async {
    try {
      await _firestoreInstance
          .collection(FirestoreApiPath.maintenanceDevices())
          .doc(deviceId)
          .update({
        'maintenanceEmployee': maintenanceEmployee,
        'price': price,
        'installedPartCodes': installedPartCodes,
      });

      debugPrint('✅ Fixed device details updated: $deviceId');
    } catch (e) {
      debugPrint('❌ Error updating fixed details: $e');
      rethrow;
    }
  }

  Future<void> deliverDevice({
    required String deviceId,
    required String deliveredByEmployee,
    required double price,
    required List<String> imagesAfterDelivery,
  }) async {
    try {
      final preparedImages = await _prepareImagesForSave(
        deviceId: deviceId,
        images: imagesAfterDelivery,
        folder: 'after_delivery',
      );

      await _firestoreInstance
          .collection(FirestoreApiPath.maintenanceDevices())
          .doc(deviceId)
          .update({
        'status': DeviceStatus.delivered,
        'deliveredAt': DateTime.now().toIso8601String(),
        'deliveredByEmployee': deliveredByEmployee,
        'price': price,
        'imagesAfterDelivery': preparedImages,
      });

      debugPrint('✅ Device delivered successfully: $deviceId');
    } catch (e) {
      debugPrint('❌ Error delivering device: $e');
      rethrow;
    }
  }
}
