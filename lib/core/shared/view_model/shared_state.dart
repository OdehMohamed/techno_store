import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:techno_store/core/shared/model/category_and_sub_category_model.dart';
import 'package:techno_store/data_source/firebase.dart';

import '../../../data_source/user_info.dart';
import '../model/brand_model.dart';
import '../model/create_user_account_model.dart';

class SharedState extends ChangeNotifier {
  bool loading = false;

  Future<void> signUp(String email, String password,
      CreateUserAccountModel createUserAccountModel) async {

    changeLoadingState(isLoading: true);

    await FirebaseDataSource().signUp(email, password, createUserAccountModel).then((value) {
      UserInfo.userId = FirebaseDataSource().firebaseAuth.currentUser?.uid;
      UserInfo.userName = createUserAccountModel.name;
      UserInfo.userPhoto = createUserAccountModel.photo;
      UserInfo.userType = createUserAccountModel.type;
    });

    changeLoadingState();
  }

  Future<List<CategoriesAndSubCategoryModel>> getCategories() async {
    changeLoadingState(isLoading: true);

    List<CategoriesAndSubCategoryModel> categories =
        await FirebaseDataSource().getCategories();

    changeLoadingState();

    return categories;
  }


  Future<List<CategoriesAndSubCategoryModel>> getSubCategories(
      String categoryID) async {
    changeLoadingState(isLoading: true);

    List<CategoriesAndSubCategoryModel> subCategories =
    await FirebaseDataSource().getSubCategories(categoryID);

    changeLoadingState();

    return subCategories;
  }

  Future<List<BrandModel>> getBrands() async {

    changeLoadingState(isLoading: true);

    List<BrandModel> brands = await FirebaseDataSource().getBrands();

    changeLoadingState();

    return brands;
  }

  Future<BrandModel> getBrand(String brandID) async {

    changeLoadingState(isLoading: true);

    BrandModel brands = await FirebaseDataSource().getBrand(brandID);

    changeLoadingState();

    return brands;
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
