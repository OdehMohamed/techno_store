part of 'maintenance_list_cubit.dart';

sealed class MaintenanceListState {}

final class MaintenanceListInitial extends MaintenanceListState {}

final class MaintenanceListLoading extends MaintenanceListState {}

final class MaintenanceListLoaded extends MaintenanceListState {
  final GroupedMaintenanceDevices groupedDevices;

  MaintenanceListLoaded({required this.groupedDevices});
}

/// Bounded, single-tab result — see
/// docs/ai-workflow/SEARCH_FILTER_IMPLEMENTATION_PLAN.md. [devices] is
/// exactly what Firestore returned for the active tab/filter combination;
/// [visibleDevices] is that same list after the client-side search
/// substring filter (identical to [devices] when the search box is empty).
final class MaintenanceListTabLoaded extends MaintenanceListState {
  final List<MaintenanceDeviceModel> devices;
  final List<MaintenanceDeviceModel> visibleDevices;
  final bool hasMore;
  final bool isLoadingMore;

  MaintenanceListTabLoaded({
    required this.devices,
    required this.visibleDevices,
    required this.hasMore,
    this.isLoadingMore = false,
  });
}

final class MaintenanceListError extends MaintenanceListState {
  final String error;
  MaintenanceListError({required this.error});
}
