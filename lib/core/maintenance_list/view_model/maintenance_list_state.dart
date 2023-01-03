import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

import '../../shared/model/maintenance_device_model.dart';

class MaintenanceListState extends ChangeNotifier {
  bool loading = false;

  Future<List<MaintenanceDeviceModel>> getDevicesInMaintenance(
      String status) async {
    changeLoadingState(isLoading: true);

    List<MaintenanceDeviceModel> devices = [];
    try {
      devices = await FirebaseDataSource().getDevicesInMaintenance(status);
    } catch (e) {}

    changeLoadingState(isLoading: false);

    return devices;
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
