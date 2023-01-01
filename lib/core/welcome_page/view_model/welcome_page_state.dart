import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

class WelcomePageState extends ChangeNotifier {
  bool loading = false;

  Future<bool> signOut() async {

    changeLoadingState(isLoading : true);

      bool response = await FirebaseDataSource().signOut();

    changeLoadingState();

    return response;
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
