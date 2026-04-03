import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/core/model/grouped_maintenance_devices.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';
import 'package:techno_store/core/services/firebase_storage_services.dart';
import 'package:techno_store/core/services/firestore_services.dart';
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

  int _compareDateDesc(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  void _sortGroupedLists({
    required List<MaintenanceDeviceModel> fixed,
    required List<MaintenanceDeviceModel> delivered,
  }) {
    fixed.sort((a, b) => _compareDateDesc(a.fixedAt, b.fixedAt));
    delivered.sort((a, b) => _compareDateDesc(a.deliveredAt, b.deliveredAt));
  }

  DateTime? _parseDateField(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// METHOD 1: fetchMaintenanceDevices (الطريقة الأساسية)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// 📌 متى تستخدمها:
  /// - عدد الأجهزة قليل (أقل من 100 جهاز)
  /// - تريد جلب جميع الأجهزة مرة واحدة
  /// - تريد تصنيفها حسب الحالة (In Maintenance, Fixed, Delivered)
  /// - الاستخدام الأساسي في معظم الصفحات
  ///
  /// ✅ مثال الاستخدام:
  /// ```dart
  /// final devices = await service.fetchMaintenanceDevices(userId);
  /// print(devices.inMaintenance.length); // الأجهزة قيد الصيانة
  /// print(devices.fixed.length);         // الأجهزة المصلحة
  /// print(devices.delivered.length);     // الأجهزة المسلمة
  /// ```
  ///
  /// ⚠️ لا تستخدمها إذا:
  /// - عدد الأجهزة كبير جداً (أكثر من 500 جهاز)
  /// - تريد فقط حالة واحدة محددة
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<GroupedMaintenanceDevices> fetchMaintenanceDevices(String? uid) async {
    try {
      final querySnapshot = uid == null
          ? await _firestoreInstance
              .collection('maintenanceDevices')
              .orderBy('receivedAt', descending: true)
              .get()
          : await _firestoreInstance
              .collection('users')
              .doc(uid)
              .collection('devices')
              .orderBy('receivedAt', descending: true)
              .get();

      final List<MaintenanceDeviceModel> inMaintenance = [];
      final List<MaintenanceDeviceModel> fixed = [];
      final List<MaintenanceDeviceModel> delivered = [];

      for (var doc in querySnapshot.docs) {
        final device = MaintenanceDeviceModel.fromMap(doc.data(), doc.id);

        switch (device.status.toLowerCase()) {
          case 'in maintenance':
          case 'pending':
          case 'received':
            inMaintenance.add(device);
            break;
          case 'fixed':
            fixed.add(device);
            break;
          case 'delivered':
          case 'derived': // Keep for backward compatibility
            delivered.add(device);
            break;
          default:
            debugPrint(
                '⚠️ Unknown status: ${device.status} for device ${device.id}');
            inMaintenance.add(device); // Default to inMaintenance
            break;
        }
      }

      _sortGroupedLists(fixed: fixed, delivered: delivered);

      debugPrint('✅ Fetched ${querySnapshot.docs.length} devices: '
          '${inMaintenance.length} in maintenance, '
          '${fixed.length} fixed, '
          '${delivered.length} delivered');

      return GroupedMaintenanceDevices(
        inMaintenance: inMaintenance,
        fixed: fixed,
        delivered: delivered,
      );
    } catch (e) {
      debugPrint('❌ Error fetching maintenance devices: $e');
      return GroupedMaintenanceDevices(
        inMaintenance: [],
        fixed: [],
        delivered: [],
      );
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// METHOD 2: fetchMaintenanceDevicesPaginated (للبيانات الكبيرة)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// 📌 متى تستخدمها:
  /// - عدد الأجهزة كبير جداً (أكثر من 500 جهاز)
  /// - تريد تحميل البيانات تدريجياً (Lazy Loading)
  /// - تريد Infinite Scroll في القائمة
  /// - لتحسين الأداء وتقليل استهلاك البيانات
  ///
  /// ✅ مثال الاستخدام:
  /// ```dart
  /// // جلب أول 50 جهاز
  /// final firstPage = await service.fetchMaintenanceDevicesPaginated(
  ///   uid: userId,
  ///   limit: 50,
  /// );
  ///
  /// // جلب الصفحة التالية
  /// final nextPage = await service.fetchMaintenanceDevicesPaginated(
  ///   uid: userId,
  ///   limit: 50,
  ///   lastDocument: lastDocument, // آخر document من الصفحة السابقة
  /// );
  /// ```
  ///
  /// 💡 نصيحة: استخدمها في ListView مع scroll listener
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Future<GroupedMaintenanceDevices> fetchMaintenanceDevicesPaginated({
    String? uid,
    int limit = 50,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = uid == null
          ? _firestoreInstance.collection('maintenanceDevices')
          : _firestoreInstance
              .collection('users')
              .doc(uid)
              .collection('devices');

      query = query.orderBy('receivedAt', descending: true).limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();

      final List<MaintenanceDeviceModel> inMaintenance = [];
      final List<MaintenanceDeviceModel> fixed = [];
      final List<MaintenanceDeviceModel> delivered = [];

      for (var doc in querySnapshot.docs) {
        final device = MaintenanceDeviceModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);

        switch (device.status.toLowerCase()) {
          case 'in maintenance':
          case 'pending':
          case 'received':
            inMaintenance.add(device);
            break;
          case 'fixed':
            fixed.add(device);
            break;
          case 'delivered':
          case 'derived':
            delivered.add(device);
            break;
          default:
            inMaintenance.add(device);
            break;
        }
      }

      _sortGroupedLists(fixed: fixed, delivered: delivered);

      debugPrint('✅ Fetched ${querySnapshot.docs.length} devices (paginated)');

      return GroupedMaintenanceDevices(
        inMaintenance: inMaintenance,
        fixed: fixed,
        delivered: delivered,
      );
    } catch (e) {
      debugPrint('❌ Error fetching paginated devices: $e');
      return GroupedMaintenanceDevices(
        inMaintenance: [],
        fixed: [],
        delivered: [],
      );
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// METHOD 3: fetchDevicesByStatus (استعلام محدد بالحالة)
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// 📌 متى تستخدمها:
  /// - تريد فقط الأجهزة في حالة معينة (مثلاً: Fixed فقط)
  /// - لا تحتاج لتصنيف الأجهزة
  /// - صفحة مخصصة لحالة واحدة (مثلاً: صفحة "الأجهزة المسلمة")
  /// - الأداء مهم وتريد استعلام سريع
  ///
  /// ✅ مثال الاستخدام:
  /// ```dart
  /// // جلب الأجهزة المصلحة فقط
  /// final fixedDevices = await service.fetchDevicesByStatus(
  ///   status: DeviceStatus.fixed,
  ///   uid: userId,
  ///   limit: 50,
  /// );
  ///
  /// // جلب الأجهزة المسلمة فقط
  /// final deliveredDevices = await service.fetchDevicesByStatus(
  ///   status: DeviceStatus.delivered,
  ///   uid: userId,
  /// );
  /// ```
  ///
  /// 🚀 ميزة: أسرع من METHOD 1 لأنه يستعلم مباشرة بالـ WHERE
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Stream<List<MaintenanceDeviceModel>> fetchDevicesByStatus({
    required String status,
    String? uid,
    int limit = 50,
  }) {
    try {
      final Stream<List<MaintenanceDeviceModel>> devicesStream =
          firestoreServices.collectionsStream<MaintenanceDeviceModel>(
        path: (uid == null)
            ? FirestoreApiPath.maintenanceDevices()
            : FirestoreApiPath.userDevices(uid),
        builder: (data, docId) => MaintenanceDeviceModel.fromMap(
          data ?? {},
          docId,
        ),
        queryBuilder: (query) => query
            .where('status', isEqualTo: status)
            .orderBy('receivedAt', descending: true)
            .limit(limit),
      );
      debugPrint(
          '✅ Fetching devices with status: $status for uid: $uid with length: ${devicesStream.length} ');
      return devicesStream;
      // Query query = (uid == null)
      //     ? _firestoreInstance.collection('maintenanceDevices')
      //     : _firestoreInstance
      //         .collection('users')
      //         .doc(uid)
      //         .collection('devices');

      // final querySnapshot = await query
      //     .where('status', isEqualTo: status)
      //     .orderBy('receivedAt', descending: true)
      //     .limit(limit)
      //     .get();

      // final devices = querySnapshot.docs
      //     .map((doc) => MaintenanceDeviceModel.fromMap(
      //         doc.data() as Map<String, dynamic>, doc.id))
      //     .toList();

      // debugPrint('✅ Fetched ${devices.length} devices with status: $status');
      // return devices;
    } catch (e) {
      debugPrint('❌ Error fetching devices by status: $e');
      return Stream.value([]);
    }
  }

  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /// METHOD 4: streamMaintenanceDevices (للتحديثات الفورية) 🔥
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ///
  /// 📌 متى تستخدمها:
  /// - تريد تحديثات فورية (Realtime) لجميع المستخدمين
  /// - عند إضافة/تعديل/حذف جهاز، التحديث يظهر تلقائياً للجميع
  /// - الاستخدام المثالي للصفحات التي تتطلب مزامنة فورية
  ///
  /// ✅ مثال الاستخدام:
  /// ```dart
  /// // الاستماع للتحديثات
  /// final subscription = service.streamMaintenanceDevices(userId).listen(
  ///   (devices) {
  ///     print('تحديث جديد: ${devices.inMaintenance.length} أجهزة');
  ///   },
  ///   onError: (error) => print('خطأ: $error'),
  /// );
  ///
  /// // إيقاف الاستماع عند الخروج
  /// subscription.cancel();
  /// ```
  ///
  /// 🎯 الفوائد:
  /// - تحديثات فورية بدون refresh يدوي
  /// - جميع المستخدمين يرون التغييرات في نفس اللحظة
  /// - كفاءة عالية (Firebase يرسل فقط التغييرات)
  ///
  /// ⚠️ تذكر: cancel الـ subscription عند dispose
  /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Stream<GroupedMaintenanceDevices> streamMaintenanceDevices(String? uid) {
    debugPrint('🔥 streamMaintenanceDevices called with uid: $uid');

    final stream = uid == null
        ? _firestoreInstance
            .collection(FirestoreApiPath.maintenanceDevices())
            .orderBy('receivedAt', descending: true)
            .snapshots()
        : _firestoreInstance
            .collection(FirestoreApiPath.maintenanceDevices())
            .orderBy('receivedAt', descending: true)
            .where('userId', isEqualTo: uid)
            .snapshots();

    debugPrint(
        '📡 Listening to: ${uid == null ? "maintenanceDevices" : "maintenanceDevices (userId: $uid)"}');

    return stream.map((snapshot) {
      debugPrint(
          '🔄 Stream snapshot received: ${snapshot.docs.length} documents');

      final List<MaintenanceDeviceModel> inMaintenance = [];
      final List<MaintenanceDeviceModel> fixed = [];
      final List<MaintenanceDeviceModel> delivered = [];

      for (var doc in snapshot.docs) {
        final device = MaintenanceDeviceModel.fromMap(doc.data(), doc.id);

        switch (device.status.toLowerCase()) {
          case 'in maintenance':
          case 'pending':
          case 'received':
            inMaintenance.add(device);
            break;
          case 'fixed':
            fixed.add(device);
            break;
          case 'delivered':
          case 'derived':
            delivered.add(device);
            break;
          default:
            debugPrint(
                '⚠️ Unknown status: ${device.status} for device ${device.id}');
            inMaintenance.add(device);
            break;
        }
      }

      _sortGroupedLists(fixed: fixed, delivered: delivered);

      debugPrint('✅ Stream mapped: '
          '${inMaintenance.length} in maintenance, '
          '${fixed.length} fixed, '
          '${delivered.length} delivered');

      return GroupedMaintenanceDevices(
        inMaintenance: inMaintenance,
        fixed: fixed,
        delivered: delivered,
      );
    });
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      await _firestoreInstance
          .collection(FirestoreApiPath.maintenanceDevices())
          .doc(deviceId)
          .delete();
      debugPrint('✅ Device deleted successfully: $deviceId');
    } catch (e) {
      debugPrint('❌ Error deleting device: $e');
      rethrow;
    }
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
