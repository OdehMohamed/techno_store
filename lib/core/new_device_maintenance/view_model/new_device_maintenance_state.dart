import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

import '../../shared/model/maintenance_device_model.dart';

class NewDeviceMaintenanceState extends ChangeNotifier {
  bool loading = false;

  Future<bool> addDeviceToMaintenance(
      MaintenanceDeviceModel maintenanceDeviceModel) async {
    changeLoadingState(isLoading: true);

    bool response = await FirebaseDataSource()
        .addDeviceToMaintenance(maintenanceDeviceModel);

    changeLoadingState();

    return response;
  }

  Future<bool> editDeviceInMaintenance(
      String deviceID, MaintenanceDeviceModel maintenanceDeviceModel) async {
    changeLoadingState(isLoading: true);

    bool response = await FirebaseDataSource()
        .editDeviceInMaintenance(deviceID, maintenanceDeviceModel);

    changeLoadingState();

    return response;
  }

  void changeLoadingState({bool? isLoading}) {
    if (isLoading != null) {
      loading = isLoading;
    } else {
      loading ? loading = false : loading = true;
    }
    refresh();
  }

  void refresh() {
    notifyListeners();
  }
}
