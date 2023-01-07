import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

import '../../shared/model/maintenance_device_model.dart';

class NewDeviceMaintenanceState extends ChangeNotifier {
  bool loading = false;

  Future<bool> addDeviceToMaintenance(
      MaintenanceDeviceModel maintenanceDeviceModel) async {
    changeLoadingState(isLoading: true);

    bool response = false;
    try {
      response = await FirebaseDataSource()
          .addDeviceToMaintenance(maintenanceDeviceModel);
    } catch (e) {}
    changeLoadingState(isLoading: false);

    return response;
  }

  Future<bool> editDeviceInMaintenance(
      String deviceID, MaintenanceDeviceModel maintenanceDeviceModel) async {
    changeLoadingState(isLoading: true);

    bool response = false;

    try {
      response = await FirebaseDataSource()
          .editDeviceInMaintenance(deviceID, maintenanceDeviceModel);
    } catch (e) {}

    changeLoadingState(isLoading: false);

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
    Future.delayed(Duration.zero, notifyListeners);
    //notifyListeners();
  }
}
