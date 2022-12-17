import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

class WelcomePageState extends ChangeNotifier {
  bool loading = false;

  Future<void> signOut() async {
    print("dsgbdfgbfgbhdfgndfndf");
    loading = true;
    refresh();

    try {
      await FirebaseDataSource().signOut();
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
