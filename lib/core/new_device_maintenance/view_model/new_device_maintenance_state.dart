import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

import '../../shared/model/maintenance_device_model.dart';

class NewDeviceMaintenanceState extends ChangeNotifier{
  bool loading = false;


  Future<void> addDeviceToMaintenance(
      MaintenanceDeviceModel maintenanceDeviceModel) async {

    changeLoadingState(isLoading : true);

    await FirebaseDataSource().addDeviceToMaintenance(maintenanceDeviceModel);

    changeLoadingState();
  }
  Future<void> editDeviceInMaintenance(
      String deviceID, MaintenanceDeviceModel maintenanceDeviceModel) async {

    changeLoadingState(isLoading : true);

    await FirebaseDataSource().editDeviceInMaintenance(deviceID, maintenanceDeviceModel);

    changeLoadingState();
  }
  void changeLoadingState({bool? isLoading}) {
    if(isLoading != null){
      loading = isLoading;
    }
    else{
      loading ? loading = false : loading = true;
    }
    refresh();
  }

  void refresh() {
    notifyListeners();
  }
}