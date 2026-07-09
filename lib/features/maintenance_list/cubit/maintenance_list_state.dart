part of 'maintenance_list_cubit.dart';

sealed class MaintenanceListState {}

final class MaintenanceListInitial extends MaintenanceListState {}

final class MaintenanceListError extends MaintenanceListState {
  final String error;
  MaintenanceListError({required this.error});
}
