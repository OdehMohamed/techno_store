import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/services/firebase_storage_services.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';
import 'package:techno_store/core/model/maintenance_device_sensitive_data.dart';
import 'package:techno_store/features/new_device_maintenance/services/new_device_services.dart';

part 'new_device_state.dart';

class NewDeviceCubit extends Cubit<NewDeviceState> {
  NewDeviceCubit() : super(NewDeviceInitial());

  final NewDeviceServices newDeviceServices = NewDeviceServices();
  final FirebaseStorageServices _storageServices =
      FirebaseStorageServices.instance;

  /// إضافة جهاز جديد
  Future<void> addNewDevice(
    MaintenanceDeviceModel device, {
    MaintenanceDeviceSensitiveData? sensitiveData,
  }) async {
    try {
      emit(NewDeviceLoading());

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        emit(NewDeviceError(error: 'User not authenticated'));
        return;
      }
      final deviceId = await newDeviceServices.addNewDevice(
        device,
        sensitiveData: sensitiveData,
      );
      emit(NewDeviceSuccess(deviceId: deviceId));
    } catch (e) {
      debugPrint('❌ Error in addNewDevice: $e');
      emit(NewDeviceError(error: e.toString()));
    }
  }

  /// تحديث جهاز موجود
  Future<void> updateDevice(
    String deviceId,
    MaintenanceDeviceModel device, {
    MaintenanceDeviceSensitiveData? sensitiveData,
  }) async {
    try {
      emit(NewDeviceLoading());

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        emit(NewDeviceError(error: 'User not authenticated'));
        return;
      }
      await newDeviceServices.updateDevice(
        deviceId,
        device,
        sensitiveData: sensitiveData,
      );
      emit(NewDeviceSuccess(deviceId: deviceId));
    } catch (e) {
      debugPrint('❌ Error in updateDevice: $e');
      emit(NewDeviceError(error: e.toString()));
    }
  }
}
