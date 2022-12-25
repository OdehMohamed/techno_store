import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';
import '../../shared/model/productModel.dart';

class ProductDetailsState extends ChangeNotifier {
  bool loading = false;

  Future<void> editProduct(String productId, ProductModel productModel) async {
    changeLoadingState();

    await FirebaseDataSource().editProduct(productId, productModel);

    changeLoadingState();
  }

  Future<void> deleteProduct(String productId) async {
    changeLoadingState();

    FirebaseDataSource().deleteProduct(productId);

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
