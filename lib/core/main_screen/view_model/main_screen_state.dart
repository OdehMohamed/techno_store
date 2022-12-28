import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

class MainScreenState extends ChangeNotifier {
  bool loading = false;

  Future<void> signIn(String email, String password) async {
    loading = true;
    try {
      await FirebaseDataSource().signIn(email, password);
    } catch (e) {
      print("EEEEEEEEEEERRRRRRRRROOOOOOOORRRRRRRRRR");
    }

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
