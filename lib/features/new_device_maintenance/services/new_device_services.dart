import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:techno_store/core2/services/firebase_storage_services.dart';
import 'package:techno_store/core2/services/firestore_services.dart';
import 'package:techno_store/core2/utils/firestore_api_path.dart';
import 'package:techno_store/core2/utils/storage_api_path.dart';
import 'package:techno_store/features/new_device_maintenance/model/new_device_maintenance_model.dart';

class NewDeviceServices {
  final FirestoreServices _firestoreServices = FirestoreServices.instance;
  final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;
  final FirebaseStorageServices _storageServices =
      FirebaseStorageServices.instance;

  Future<String> addNewDevice(NewDeviceMaintenanceModel device) async {
    try {
      final docRef = _firestoreInstance.collection('maintenanceDevices').doc();

      final deviceId = docRef.id;

      if (device.imagesBeforeReceiving != null) {
        for (int i = 0; i < device.imagesBeforeReceiving!.length; i++) {
          final imageUrl = await _storageServices.uploadFile(
            file: File(device.imagesBeforeReceiving![i]),
            folderPath:
                StorageApiPath.maintenanceImages(deviceId, 'before_receiving'),
          );

          device.imagesBeforeReceiving![i] = imageUrl!;
        }
      }
      if (device.imagesAfterDelivery != null) {
        for (int i = 0; i < device.imagesAfterDelivery!.length; i++) {
          final imageUrl = await _storageServices.uploadFile(
            file: File(device.imagesAfterDelivery![i]),
            folderPath:
                StorageApiPath.maintenanceImages(deviceId, 'after_delivery'),
          );
          device.imagesAfterDelivery![i] = imageUrl!;
        }
      }
      final userID = await getUserIdByPhoneNumber(device.phoneNumber);
      device = device.copyWith(userId: userID);

      await _firestoreServices.setData(
        path: FirestoreApiPath.maintenanceDevice(deviceId),
        data: device.toJson(),
      );
      if (device.userId != null) {
        await _firestoreServices.setData(
          path: FirestoreApiPath.userDevice(device.userId!, deviceId),
          data: device.toJson(),
        );
      }
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
}
