import 'package:flutter/cupertino.dart';
import 'package:techno_store/core/shared/model/productModel.dart';
import 'package:techno_store/data_source/firebase.dart';

class StoreState extends ChangeNotifier {
  bool loading = false;

  Future<List<ProductModel>> getProducts(String subCategoryId) async {
    changeLoadingState(isLoading: true);

    List<ProductModel> products = [];

    try {
      products = await FirebaseDataSource().getProducts(subCategoryId);
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
    Future.delayed(Duration.zero, notifyListeners);
    //notifyListeners();
  }
}
