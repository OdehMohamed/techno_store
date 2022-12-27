import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

import '../../shared/model/maintenance_device_model.dart';

class MaintenanceListState extends ChangeNotifier{
  bool loading = false;

  Future<List<MaintenanceDeviceModel>> getDevicesInMaintenance(
      String status) async {

    loading=true;
    List<MaintenanceDeviceModel> devices = await FirebaseDataSource().getDevicesInMaintenance(status);

    changeLoadingState();

    return devices;
  }

  void changeLoadingState(){
    loading ? loading = false : loading = true;
    refresh();
  }

  void refresh() {
    notifyListeners();
  }
}