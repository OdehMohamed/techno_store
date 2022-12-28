import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';
import '../../shared/model/productModel.dart';

class ProductDetailsState extends ChangeNotifier {
  bool loading = false;

  Future<void> deleteProduct(String productId) async {
    changeLoadingState(isLoading : true);

    FirebaseDataSource().deleteProduct(productId);

    changeLoadingState();
  }
  Future<void> updateFavorites(
      String productID, List<String> favoriteList) async {
    changeLoadingState(isLoading : true);

    await FirebaseDataSource().updateFavorites(productID, favoriteList);

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
