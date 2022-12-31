import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:techno_store/core/shared/model/category_and_sub_category_model.dart';
import 'package:techno_store/data_source/firebase.dart';

import '../model/brand_model.dart';
import '../model/create_user_account_model.dart';

class SharedState extends ChangeNotifier {
  bool loading = false;

  String? _userId;
  String? _userName;
  String? _userPhoto;
  int? _userType;

  String? get userId => _userId;
  set userId(String? userId) => _userId = userId;

  String? get userName => _userName;
  set userName(String? userName) => _userName = userName;

  String? get userPhoto => _userPhoto;
  set userPhoto(String? userPhoto) => _userPhoto = userPhoto;

  int? get userType => _userType;
  set userType(int? userType) => _userType = userType;

  Future<void> updateUserInfo(String uid,
      {CreateUserAccountModel? createUserAccountModel}) async {
    print(uid);
    if (createUserAccountModel == null) {
      createUserAccountModel = await FirebaseDataSource().getUserInfo(uid);
    }

    if (createUserAccountModel != null) {
      userId = FirebaseDataSource().firebaseAuth.currentUser?.uid;
      userName = createUserAccountModel.name;
      userPhoto = createUserAccountModel.photo;
      userType = createUserAccountModel.type;
    }

    refresh();
  }

  Future<void> signUp(String email, String password,
      CreateUserAccountModel createUserAccountModel) async {
    changeLoadingState(isLoading: true);

    await FirebaseDataSource()
        .signUp(email, password, createUserAccountModel)
        .then((value) {
      updateUserInfo(FirebaseDataSource().firebaseAuth.currentUser!.uid,
          createUserAccountModel: createUserAccountModel);
    });

    changeLoadingState();
  }

  Future<void> createNewUserFromAdmin(String email, String password,
      CreateUserAccountModel createUserAccountModel) async {
    changeLoadingState(isLoading: true);

    FirebaseDataSource().sinUpByAdmin(email, password, createUserAccountModel);

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
