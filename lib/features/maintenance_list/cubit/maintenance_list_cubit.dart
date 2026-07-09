import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/features/maintenance_list/services/maintenance_list_services.dart';

part 'maintenance_list_state.dart';

class MaintenanceListCubit extends Cubit<MaintenanceListState> {
  MaintenanceListCubit() : super(MaintenanceListInitial());
  final MaintenanceListServices maintenanceListServices =
      MaintenanceListServices();

  /// Delete a device
  Future<void> deleteDevice(String deviceId) async {
    try {
      await maintenanceListServices.deleteDevice(deviceId);
      debugPrint('✅ Device deleted successfully: $deviceId');
    } catch (e) {
      debugPrint('❌ Error deleting device: $e');
      emit(MaintenanceListError(error: e.toString()));
    }
  }

  /// Update device status
  Future<void> updateDeviceStatus(String deviceId, String newStatus) async {
    try {
      await maintenanceListServices.updateDeviceStatus(deviceId, newStatus);
      debugPrint(
          '✅ Device status updated successfully: $deviceId to $newStatus');
    } catch (e) {
      debugPrint('❌ Error updating device status: $e');
      emit(MaintenanceListError(error: e.toString()));
    }
  }

  Future<void> updateDeviceAsFixed({
    required String deviceId,
    required String maintenanceEmployee,
    required double? price,
    required List<String> installedPartCodes,
  }) async {
    try {
      await maintenanceListServices.updateDeviceAsFixed(
        deviceId: deviceId,
        maintenanceEmployee: maintenanceEmployee,
        price: price,
        installedPartCodes: installedPartCodes,
      );
      debugPrint('✅ Device fixed update saved successfully: $deviceId');
    } catch (e) {
      debugPrint('❌ Error saving fixed update: $e');
      emit(MaintenanceListError(error: e.toString()));
    }
  }

  Future<void> updateFixedDeviceDetails({
    required String deviceId,
    required String maintenanceEmployee,
    required double? price,
    required List<String> installedPartCodes,
  }) async {
    try {
      await maintenanceListServices.updateFixedDeviceDetails(
        deviceId: deviceId,
        maintenanceEmployee: maintenanceEmployee,
        price: price,
        installedPartCodes: installedPartCodes,
      );
      debugPrint('✅ Fixed device details edited successfully: $deviceId');
    } catch (e) {
      debugPrint('❌ Error editing fixed details: $e');
      emit(MaintenanceListError(error: e.toString()));
    }
  }

  Future<void> deliverDevice({
    required String deviceId,
    required String deliveredByEmployee,
    required double price,
    required List<String> imagesAfterDelivery,
  }) async {
    try {
      await maintenanceListServices.deliverDevice(
        deviceId: deviceId,
        deliveredByEmployee: deliveredByEmployee,
        price: price,
        imagesAfterDelivery: imagesAfterDelivery,
      );
      debugPrint('✅ Device delivered successfully: $deviceId');
    } catch (e) {
      debugPrint('❌ Error delivering device: $e');
      emit(MaintenanceListError(error: e.toString()));
    }
  }
}
