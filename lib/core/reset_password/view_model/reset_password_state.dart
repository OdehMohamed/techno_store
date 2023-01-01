import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

class ResetPasswordState extends ChangeNotifier{
  bool loading = false;

  Future<bool> resetPassword(String email) async {

    changeLoadingState(isLoading : true);

    bool response = await FirebaseDataSource().resetPassword(email);

    changeLoadingState();

    return response;
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