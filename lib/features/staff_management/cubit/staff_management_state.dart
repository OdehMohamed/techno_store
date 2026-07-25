part of 'staff_management_cubit.dart';

sealed class StaffManagementState {}

final class StaffManagementInitial extends StaffManagementState {}

final class StaffManagementLoading extends StaffManagementState {}

final class StaffManagementLoaded extends StaffManagementState {
  final List<StaffMember> staff;
  StaffManagementLoaded(this.staff);
}

final class StaffManagementError extends StaffManagementState {
  final String message;
  StaffManagementError(this.message);
}
