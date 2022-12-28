import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

import '../../shared/model/maintenance_device_model.dart';

class TrackPhonePageState extends ChangeNotifier{

  bool loading = false;
  Future<List<MaintenanceDeviceModel>> checkDeviceStatus(
      String phoneNumber) async {

    changeLoadingState(isLoading : true);

    List<MaintenanceDeviceModel> devices = await FirebaseDataSource().checkDeviceStatus(phoneNumber);

    changeLoadingState();

    return devices;
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