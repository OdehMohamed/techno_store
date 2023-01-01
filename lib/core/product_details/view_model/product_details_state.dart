import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';
import '../../shared/model/productModel.dart';

class ProductDetailsState extends ChangeNotifier {
  bool loading = false;

  Future<bool> deleteProduct(String productId) async {
    changeLoadingState(isLoading: true);

    bool response = await FirebaseDataSource().deleteProduct(productId);

    changeLoadingState();

    return response;
  }

  Future<bool> updateFavorites(
      String productID, List<String> favoriteList) async {
    changeLoadingState(isLoading: true);

    bool response =
        await FirebaseDataSource().updateFavorites(productID, favoriteList);

    changeLoadingState();

    return response;
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
