import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

class WelcomePageState extends ChangeNotifier {
  bool loading = false;

  Future<void> signOut() async {
    loading = true;

    try {
      await FirebaseDataSource().signOut();
    } catch (e) {
      print("EEEEEEEEEEERRRRRRRRROOOOOOOORRRRRRRRRR");
    }

    changeLoadingState();
  }

  void changeLoadingState() {
    loading ? loading = false : loading = true;
    refresh();
  }

  void refresh() {
    notifyListeners();
  }
}
