import 'package:flutter/cupertino.dart';

import '../../../data_source/firebase.dart';
import '../../shared/model/productModel.dart';

class NewProductState extends ChangeNotifier {
  bool loading = false;

  Future<bool> addProduct(ProductModel productModel) async {
    changeLoadingState(isLoading: true);

    bool response = await FirebaseDataSource().addProduct(productModel);

    changeLoadingState();

    return response;
  }

  Future<bool> editProduct(ProductModel productModel) async {
    changeLoadingState(isLoading: true);

    bool response = await FirebaseDataSource().editProduct(productModel);

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
