import 'package:flutter/cupertino.dart';

import '../../../data_source/firebase.dart';
import '../../shared/model/productModel.dart';

class NewProductState extends ChangeNotifier{
  bool loading = false;

  Future<void> addProduct(ProductModel productModel) async {

    changeLoadingState();

     await FirebaseDataSource().addProduct(productModel);

    changeLoadingState();

  }
  Future<void> editProduct(String productId, ProductModel productModel) async {
    changeLoadingState();

    await FirebaseDataSource().editProduct(productId, productModel);

    changeLoadingState();
  }
  void changeLoadingState(){
    loading ? loading = false : loading = true;
    refresh();
  }

  void refresh() {
    notifyListeners();
  }
}