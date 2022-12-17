import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

class MainScreenState extends ChangeNotifier {
  bool loading = false;

  Future<void> signIn(String email, String password) async {
    loading = true;
    refresh();


    try {
      await FirebaseDataSource().signIn(email, password);
    } catch (e) {
      print("EEEEEEEEEEERRRRRRRRROOOOOOOORRRRRRRRRR");
    }

    loading = false;
    refresh();
  }

  void refresh() {
    notifyListeners();
  }
}
