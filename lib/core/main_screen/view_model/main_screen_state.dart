import 'package:flutter/cupertino.dart';
import 'package:techno_store/core/shared/model/create_user_account_model.dart';
import 'package:techno_store/data_source/firebase.dart';

class MainScreenState extends ChangeNotifier {
  bool loading = false;

  Future<void> signIn(String email, String password) async {
    changeLoadingState(isLoading: true);
    try {
      await FirebaseDataSource().signIn(email, password);

    } catch (e) {
      print("EEEEEEEEEEERRRRRRRRROOOOOOOORRRRRRRRRR");
    }

    changeLoadingState();
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
