import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

class WelcomePageState extends ChangeNotifier {
  bool loading = false;

  Future<void> signOut() async {

    changeLoadingState(isLoading : true);

    try {
      await FirebaseDataSource().signOut();
    } catch (e) {
      print("EEEEEEEEEEERRRRRRRRROOOOOOOORRRRRRRRRR");
    }

    changeLoadingState();
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
