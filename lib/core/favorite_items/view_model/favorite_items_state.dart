import 'package:flutter/cupertino.dart';
import 'package:techno_store/core/shared/model/productModel.dart';
import 'package:techno_store/data_source/firebase.dart';

class FavoriteItemsState extends ChangeNotifier {
  bool loading = false;

  Future<List<ProductModel>> getProducts() async {
    loading = true;

    List<ProductModel> products = [];

    try {
      products = await FirebaseDataSource().getFavorites();
    } catch (e) {}

    changeLoadingState(isLoading: false);

    return products;
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
