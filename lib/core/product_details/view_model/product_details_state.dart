import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';
import '../../shared/model/productModel.dart';

class ProductDetailsState extends ChangeNotifier {
  bool loading = false;

  Future<void> deleteProduct(String productId) async {
    loading = true;

    FirebaseDataSource().deleteProduct(productId);

    changeLoadingState();
  }
  Future<void> updateFavorites(
      String productID, List<String> favoriteList) async {
    loading = true;

    await FirebaseDataSource().updateFavorites(productID, favoriteList);

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
