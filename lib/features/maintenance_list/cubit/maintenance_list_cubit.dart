import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/features/maintenance_list/services/maintenance_list_services.dart';

part 'maintenance_list_state.dart';

class MaintenanceListCubit extends Cubit<MaintenanceListState> {
  MaintenanceListCubit() : super(MaintenanceListInitial());
  final MaintenanceListServices maintenanceListServices =
      MaintenanceListServices();

  /// Archives a device (staff-wide, reversible). Rethrows on failure —
  /// deliberately not the swallow-and-emit-an-unlistened-state pattern the
  /// older methods below use (see BACKLOG.md item 14); this and the two
  /// methods below let the calling confirmation dialog's own try/catch
  /// actually show a real error instead of failing silently, which matters
  /// most for Permanent Delete.
  Future<void> archiveDevice(String deviceId, String actingUid) async {
    try {
      await maintenanceListServices.archiveDevice(deviceId, actingUid);
      debugPrint('✅ Device archived: $deviceId');
    } catch (e) {
      debugPrint('❌ Error archiving device: $e');
      rethrow;
    }
  }

  /// Restores an archived device (Admin-only, enforced by Firestore rules).
  Future<void> restoreDevice(String deviceId, String actingUid) async {
    try {
      await maintenanceListServices.restoreDevice(deviceId, actingUid);
      debugPrint('✅ Device restored: $deviceId');
    } catch (e) {
      debugPrint('❌ Error restoring device: $e');
      rethrow;
    }
  }

  /// Permanently deletes an archived device via the permanentlyDeleteDevice
  /// Cloud Function. Curates the function's error codes into user-facing
  /// text here — the domain boundary, matching AuthCubit's pattern for
  /// FirebaseAuthException — rather than showing a raw technical message.
  Future<void> permanentlyDeleteDevice(String deviceId) async {
    try {
      await maintenanceListServices.permanentlyDeleteDevice(deviceId);
      debugPrint('✅ Device permanently deleted: $deviceId');
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ permanentlyDeleteDevice failed: ${e.code} ${e.message}');
      throw Exception(_permanentDeleteErrorMessage(e));
    } catch (e) {
      debugPrint('❌ Error permanently deleting device: $e');
      rethrow;
    }
  }

  String _permanentDeleteErrorMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Please sign in again and retry.';
      case 'permission-denied':
        return 'Only an active Admin account may permanently delete a device.';
      case 'failed-precondition':
        return 'This device must be archived before it can be permanently deleted.';
      case 'not-found':
        return 'This device no longer exists.';
      case 'invalid-argument':
        return 'Could not identify which device to delete.';
      default:
        return 'Could not permanently delete this device. Please try again.';
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
