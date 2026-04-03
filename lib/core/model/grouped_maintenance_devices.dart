import 'package:techno_store/core/model/maintenance_device_model.dart';

class GroupedMaintenanceDevices {
  final List<MaintenanceDeviceModel> inMaintenance;
  final List<MaintenanceDeviceModel> fixed;
  final List<MaintenanceDeviceModel> delivered;

  GroupedMaintenanceDevices({
    required this.inMaintenance,
    required this.fixed,
    required this.delivered,
  });

  int get totalCount => inMaintenance.length + fixed.length + delivered.length;
}
