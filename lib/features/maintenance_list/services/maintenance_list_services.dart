import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
        .where('status', isEqualTo: status)
        // Normal staff tabs and the customer's own view only ever show
        // active records — an archived device is not part of normal
        // product truth for either. See ADR-005. Requires every existing
        // document to have been backfilled with recordState first (see
        // scripts/migration/migrate-recordstate.js) — Firestore equality
        // filters don't match documents where the field is absent.
        .where('recordState', isEqualTo: 'active');

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

  /// Archives a device: sets recordState to 'archived' and writes a
  /// lifecycleEvents entry recording who did it and when. Staff-wide.
  /// Deliberately does NOT touch Storage images or the private/sensitive
  /// subdocument — the whole point is that nothing is destroyed. See
  /// docs/ai-workflow/ADR-005-device-lifecycle-archive-deletion.md.
  Future<void> archiveDevice(String deviceId, String actingUid) async {
    final deviceRef = _firestoreInstance
        .collection(FirestoreApiPath.maintenanceDevices())
        .doc(deviceId);
    final batch = _firestoreInstance.batch();
    batch.update(deviceRef, {
      'recordState': 'archived',
      'updatedAt': DateTime.now().toIso8601String(),
    });
    batch.set(deviceRef.collection('lifecycleEvents').doc(), {
      'type': 'archived',
      'actingUid': actingUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    debugPrint('✅ Device archived: $deviceId');
  }

  /// Restores an archived device back to active. Admin-only — enforced by
  /// Firestore rules, not just by this method's caller being an Admin-only
  /// screen. Writes a matching lifecycleEvents entry.
  Future<void> restoreDevice(String deviceId, String actingUid) async {
    final deviceRef = _firestoreInstance
        .collection(FirestoreApiPath.maintenanceDevices())
        .doc(deviceId);
    final batch = _firestoreInstance.batch();
    batch.update(deviceRef, {
      'recordState': 'active',
      'updatedAt': DateTime.now().toIso8601String(),
    });
    batch.set(deviceRef.collection('lifecycleEvents').doc(), {
      'type': 'restored',
      'actingUid': actingUid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    debugPrint('✅ Device restored: $deviceId');
  }

  /// Live list of archived devices for the Admin-only Archived Devices
  /// screen. No status/brand/employee/date filtering — the Archived view is
  /// intentionally simple for v1 (ADR-005).
  Stream<List<MaintenanceDeviceModel>> streamArchivedDevices() {
    return _firestoreInstance
        .collection(FirestoreApiPath.maintenanceDevices())
        .where('recordState', isEqualTo: 'archived')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaintenanceDeviceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Permanently deletes an archived device via the server-side
  /// permanentlyDeleteDevice Cloud Function — the only path for this
  /// action; the client has no direct delete permission on
  /// maintenanceDevices at all (see firestore.rules). Admin-only and
  /// archive-only, enforced inside the function itself; this call just
  /// surfaces whatever it decides. Error curation happens at the cubit
  /// layer, not here — matches AuthCubit's pattern for FirebaseAuthException.
  Future<void> permanentlyDeleteDevice(String deviceId) async {
    await FirebaseFunctions.instance
        .httpsCallable('permanentlyDeleteDevice')
        .call({'deviceId': deviceId});
    debugPrint('✅ Device permanently deleted: $deviceId');
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
