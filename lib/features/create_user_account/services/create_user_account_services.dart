import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/core2/services/firestore_services.dart';
import 'package:techno_store/core2/utils/firestore_api_path.dart';
import 'package:techno_store/features/new_device_maintenance/model/new_device_maintenance_model.dart';

class CreateUserAccountServices {
  final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;
  final FirestoreServices _firestoreServices = FirestoreServices.instance;

  Future<void> findUserDevices(String phoneNumber) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final querySnapshot = await _firestoreInstance
          .collection('maintenanceDevices')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final devices = querySnapshot.docs
            .map((doc) => NewDeviceMaintenanceModel.fromMap(doc.data(), doc.id))
            .toList();
        for (int i = 0; i < devices.length; i++) {
          final device = devices[i].copyWith(userId: user!.uid);
          await updateDeviceInfo(device);
          debugPrint('✅ Device ${i + 1}: ${device.toJson()}');
        }
        debugPrint(
            '✅ Found ${devices.length} devices for phone number: $phoneNumber');
      } else {
        debugPrint('⚠️ No devices found for phone number: $phoneNumber');
        return;
      }
    } catch (e) {
      debugPrint('❌ Error fetching devices: $e');
      return;
    }
  }

  Future<void> updateDeviceInfo(NewDeviceMaintenanceModel device) async {
    try {
      final docRef =
          _firestoreInstance.collection('maintenanceDevices').doc(device.id);

      docRef.update({
        'userId': device.userId,
      });
      final deviceId = docRef.id;

      if (device.userId != null) {
        await _firestoreServices.setData(
          path: FirestoreApiPath.userDevice(device.userId!, deviceId),
          data: device.toJson(),
        );
      }
      debugPrint('✅ Device added successfully with ID: $deviceId');
      return;
    } catch (e) {
      debugPrint('❌ Error adding device: $e');
      rethrow;
    }
  }
}
