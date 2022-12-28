import 'package:flutter/cupertino.dart';

import '../../../data_source/firebase.dart';
import '../../shared/model/productModel.dart';

class NewProductState extends ChangeNotifier{
  bool loading = false;

  Future<void> addProduct(ProductModel productModel) async {

    changeLoadingState(isLoading : true);

     await FirebaseDataSource().addProduct(productModel);

    changeLoadingState();

  }
  Future<void> editProduct(ProductModel productModel) async {
    changeLoadingState(isLoading : true);

    await FirebaseDataSource().editProduct(productModel);

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