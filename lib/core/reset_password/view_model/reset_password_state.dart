import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

class ResetPasswordState extends ChangeNotifier{
  bool loading = false;

  Future<void> resetPassword(String email) async {

    changeLoadingState();

    await FirebaseDataSource().resetPassword(email);

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