import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';
import '../../shared/model/productModel.dart';

class ProductDetailsState extends ChangeNotifier {
  bool loading = false;

  Future<bool> deleteProduct(ProductModel productModel) async {
    changeLoadingState(isLoading: true);

    bool response = false;

    try {
      response = await FirebaseDataSource().deleteProduct(productModel);
    } catch (e) {}

    changeLoadingState(isLoading: false);

    return response;
  }

  Future<bool> updateFavorites(
      String productID, List<String> favoriteList) async {
    changeLoadingState(isLoading: true);

    bool response = false;
    try {
      response =
          await FirebaseDataSource().updateFavorites(productID, favoriteList);
    } catch (e) {}

    changeLoadingState(isLoading: false);

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
    Future.delayed(Duration.zero, notifyListeners);
    //notifyListeners();
  }
}
