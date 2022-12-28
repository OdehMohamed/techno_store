import 'package:flutter/cupertino.dart';
import 'package:techno_store/core/shared/model/create_user_account_model.dart';
import 'package:techno_store/data_source/firebase.dart';

import '../../../data_source/user_info.dart';

class MainScreenState extends ChangeNotifier {
  bool loading = false;

  Future<void> signIn(String email, String password) async {
    changeLoadingState(isLoading: true);
    try {
      await FirebaseDataSource().signIn(email, password);

      if (FirebaseDataSource().firebaseAuth.currentUser != null) {
        print("dgbdghdgbdgbdxfvsbnhgfdsdf");
        CreateUserAccountModel? createUserAccountModel =
            await FirebaseDataSource().getUserInfo(
                FirebaseDataSource().firebaseAuth.currentUser!.uid);

        if(createUserAccountModel != null){
          UserInfo.userId = FirebaseDataSource().firebaseAuth.currentUser?.uid;
          UserInfo.userName = createUserAccountModel.name;
          UserInfo.userPhoto = createUserAccountModel.photo;
          UserInfo.userType = createUserAccountModel.type;
        }
      }

      print(UserInfo.userName);
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
