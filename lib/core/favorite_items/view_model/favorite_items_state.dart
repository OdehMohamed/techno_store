import 'package:flutter/cupertino.dart';
import 'package:techno_store/core/shared/model/productModel.dart';
import 'package:techno_store/data_source/firebase.dart';

class FavoriteItemsState extends ChangeNotifier{
  bool loading = false;

  Future<List<ProductModel>> getProducts(String subCategoryId) async {
    changeLoadingState();

    // List<ProductModel> products =  await FirebaseDataSource().getProducts(subCategoryId);
    // products.removeWhere((element) => !element.favoriteList!.contains(FirebaseDataSource().firebaseAuth.currentUser!.uid));

    List<ProductModel> products =  await FirebaseDataSource().getFavorites();

    changeLoadingState();

    return products;
  }

  void changeLoadingState(){
    loading ? loading = false : loading = true;
    refresh();
  }

  void refresh() {
    notifyListeners();
  }
}