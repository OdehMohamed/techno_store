import 'package:flutter/cupertino.dart';
import 'package:techno_store/core/shared/model/create_user_account_model.dart';
import 'package:techno_store/data_source/firebase.dart';

class MainScreenState extends ChangeNotifier {
  bool loading = false;

  Future<bool> signIn(String email, String password) async {
    changeLoadingState(isLoading: true);

    bool b = false;

    try{
       b =  await FirebaseDataSource().signIn(email, password);
    }catch(e){}

    changeLoadingState(isLoading: false);

    return b;
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
