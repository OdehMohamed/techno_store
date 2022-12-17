import 'package:flutter/cupertino.dart';
import 'package:techno_store/core/create_user_account/model/create_user_account_model.dart';
import 'package:techno_store/data_source/firebase.dart';

class CreateUserAccountState extends ChangeNotifier {
  bool loading = false;

  Future<void> signUp(String email, String password,
      CreateUserAccountModel createUserAccountModel) async {
    loading = true;
    refresh();

    await FirebaseDataSource().signUp(email, password).then(
        (value) => FirebaseDataSource().saveUserInfo(createUserAccountModel));

    loading = false;
    refresh();
  }

  void refresh() {
    notifyListeners();
  }
}
