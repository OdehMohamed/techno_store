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
    changeLoadingState(isLoading: true);

    try {
      if (createUserAccountModel == null) {
        createUserAccountModel = await FirebaseDataSource().getUserInfo(uid);
      }

      if (createUserAccountModel != null) {
        userId = FirebaseDataSource().firebaseAuth.currentUser?.uid;
        userName = createUserAccountModel.name;
        userPhoto = createUserAccountModel.photo;
        userType = createUserAccountModel.type;
      }
    } catch (e) {}

    changeLoadingState(isLoading: false);
  }

  Future<void> signUp(String email, String password,
      CreateUserAccountModel createUserAccountModel) async {
    changeLoadingState(isLoading: true);

    try {
      await FirebaseDataSource()
          .signUp(email, password, createUserAccountModel)
          .then((value) {
        updateUserInfo(FirebaseDataSource().firebaseAuth.currentUser!.uid,
            createUserAccountModel: createUserAccountModel);
      });
    } catch (e) {}

    changeLoadingState(isLoading: false);
  }

  Future<bool> createNewUserFromAdmin(String email, String password,
      CreateUserAccountModel createUserAccountModel) async {
    changeLoadingState(isLoading: true);

    bool response = false;
    try {
      response = await FirebaseDataSource()
          .sinUpByAdmin(email, password, createUserAccountModel);
    } catch (e) {}

    changeLoadingState(isLoading: false);

    return response;
  }

  Future<List<CategoriesAndSubCategoryModel>> getCategories() async {
    changeLoadingState(isLoading: true);

    List<CategoriesAndSubCategoryModel> categories = [];

    try {
      categories = await FirebaseDataSource().getCategories();
    } catch (e) {}

    changeLoadingState(isLoading: false);

    return categories;
  }

  Future<List<CategoriesAndSubCategoryModel>> getSubCategories(
      String categoryID) async {
    changeLoadingState(isLoading: true);

    List<CategoriesAndSubCategoryModel> subCategories = [];

    try {
      subCategories = await FirebaseDataSource().getSubCategories(categoryID);
    } catch (e) {}

    changeLoadingState(isLoading: false);

    return subCategories;
  }

  Future<List<BrandModel>> getBrands() async {
    changeLoadingState(isLoading: true);

    List<BrandModel> brands = [];

    try {
      brands = await FirebaseDataSource().getBrands();
    } catch (e) {}

    changeLoadingState(isLoading: false);

    return brands;
  }

  Future<BrandModel?> getBrand(String brandID) async {
    changeLoadingState(isLoading: true);

    BrandModel? brands;

    try {
      brands = await FirebaseDataSource().getBrand(brandID);
    } catch (e) {}

    changeLoadingState(isLoading: false);

    return brands;
  }

  Future<bool> isTesting() async {
    changeLoadingState(isLoading: true);

    bool b = false;

    try{
      b =  await FirebaseDataSource().isTesting();
    }catch(e){}

    changeLoadingState(isLoading: false);

    return b;
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
