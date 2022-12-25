import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

import '../../shared/model/maintenance_device_model.dart';

class NewDeviceMaintenanceState extends ChangeNotifier{
  bool loading = false;


  Future<void> addDeviceToMaintenance(
      MaintenanceDeviceModel maintenanceDeviceModel) async {

    changeLoadingState();

    await FirebaseDataSource().addDeviceToMaintenance(maintenanceDeviceModel);

    changeLoadingState();
  }

  void changeLoadingState(){
    loading ? loading = false : loading = true;
    refresh();
  }

  void refresh() {
    notifyListeners();
  }
}