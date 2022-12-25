import 'package:flutter/cupertino.dart';
import 'package:techno_store/core/shared/model/category_and_sub_category_model.dart';
import 'package:techno_store/data_source/firebase.dart';

import '../model/brand_model.dart';
import '../model/create_user_account_model.dart';

class SharedState extends ChangeNotifier {
  bool loading = false;

  Future<void> signUp(String email, String password,
      CreateUserAccountModel createUserAccountModel) async {
    changeLoadingState();

    await FirebaseDataSource().signUp(email, password).then(
        (value) => FirebaseDataSource().saveUserInfo(createUserAccountModel));

    changeLoadingState();
  }

  Future<List<CategoriesAndSubCategoryModel>> getCategories() async {
    changeLoadingState();

    List<CategoriesAndSubCategoryModel> categories =
        await FirebaseDataSource().getCategories();

    changeLoadingState();

    return categories;
  }

  Future<void> updateFavorites(
      String productID, List<String> favoriteList) async {
    changeLoadingState();

    await FirebaseDataSource().updateFavorites(productID, favoriteList);

    changeLoadingState();
  }

  Future<List<BrandModel>> getBrands() async {

    changeLoadingState();

    List<BrandModel> brands = await FirebaseDataSource().getBrands();

    changeLoadingState();

    return brands;
  }

  Future<BrandModel> getBrand(String brandID) async {

    changeLoadingState();

    BrandModel brands = await FirebaseDataSource().getBrand(brandID);

    changeLoadingState();

    return brands;
  }

  void changeLoadingState() {
    loading ? loading = false : loading = true;
    refresh();
  }

  void refresh() {
    notifyListeners();
  }
}
