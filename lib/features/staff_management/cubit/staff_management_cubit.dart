import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/features/staff_management/model/staff_member.dart';
import 'package:techno_store/features/staff_management/services/staff_management_services.dart';

part 'staff_management_state.dart';

class StaffManagementCubit extends Cubit<StaffManagementState> {
  StaffManagementCubit() : super(StaffManagementInitial());

  final StaffManagementServices staffManagementServices =
      StaffManagementServices();

  Future<void> loadStaff() async {
    emit(StaffManagementLoading());
    try {
      final staff = await staffManagementServices.fetchStaff();
      emit(StaffManagementLoaded(staff));
    } catch (e) {
      debugPrint('❌ Error loading staff: $e');
      emit(StaffManagementError(
        'Could not load staff accounts. Please try again.',
      ));
    }
  }

  /// Creates a staff account. Rethrows on failure (curated into
  /// user-facing text here, matching MaintenanceListCubit's pattern for
  /// permanentlyDeleteDevice) so the calling form's own error handling
  /// fires instead of showing a false success. Reloads the list on success
  /// so the new account appears immediately.
  Future<String> createStaffAccount({
    required String requestId,
    required String name,
    required String email,
    required String password,
    required int type,
  }) async {
    try {
      final uid = await staffManagementServices.createStaffAccount(
        requestId: requestId,
        name: name,
        email: email,
        password: password,
        type: type,
      );
      debugPrint('✅ Staff account created: $uid');
      await loadStaff();
      return uid;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ createStaffAccount failed: ${e.code} ${e.message}');
      throw Exception(_createStaffAccountErrorMessage(e));
    } catch (e) {
      debugPrint('❌ Error creating staff account: $e');
      rethrow;
    }
  }

  String _createStaffAccountErrorMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Please sign in again and retry.';
      case 'permission-denied':
        return 'Only an active Admin account may create staff accounts.';
      case 'already-exists':
        return 'An account with this email already exists.';
      case 'invalid-argument':
        return e.message ?? 'Please check the account details and try again.';
      case 'failed-precondition':
        return 'Could not complete this request. Please start over with a new account.';
      default:
        return 'Could not create this account. Please try again.';
    }
  }

  /// Activates/deactivates a staff account via the already-shipped
  /// setStaffStatus. Rethrows on failure; reloads the list on success.
  Future<void> setStaffStatus({
    required String uid,
    required String status,
  }) async {
    try {
      await staffManagementServices.setStaffStatus(uid: uid, status: status);
      debugPrint('✅ Staff status set: $uid -> $status');
      await loadStaff();
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ setStaffStatus failed: ${e.code} ${e.message}');
      throw Exception(_setStaffStatusErrorMessage(e));
    } catch (e) {
      debugPrint('❌ Error setting staff status: $e');
      rethrow;
    }
  }

  String _setStaffStatusErrorMessage(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Please sign in again and retry.';
      case 'permission-denied':
        return 'Only an active Admin account may change staff status.';
      case 'not-found':
        return 'This account no longer exists.';
      case 'failed-precondition':
        return 'Status can only be changed for staff accounts.';
      default:
        return 'Could not update this account\'s status. Please try again.';
    }
  }
}
