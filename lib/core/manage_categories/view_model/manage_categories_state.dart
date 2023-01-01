import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

import '../../shared/model/category_and_sub_category_model.dart';

class ManageCategories extends ChangeNotifier {
  bool loading = false;

  Future<bool> addCategory(
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    changeLoadingState(isLoading: true);

    bool response =
        await FirebaseDataSource().addCategory(categoriesAndSubCategoryModel);

    changeLoadingState();

    return response;
  }

  Future<bool> editCategory(String categoryID,
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    changeLoadingState(isLoading: true);

    bool response = await FirebaseDataSource()
        .editCategory(categoryID, categoriesAndSubCategoryModel);

    changeLoadingState();

    return response;
  }

  Future<bool> addSubCategory(String categoryID,
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    changeLoadingState(isLoading: true);

    bool response = await FirebaseDataSource()
        .addSubCategory(categoryID, categoriesAndSubCategoryModel);

    changeLoadingState();

    return response;
  }

  Future<bool> editSubCategories(String categoryID, String subCategoryID,
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    changeLoadingState(isLoading: true);

    bool response = await FirebaseDataSource().editSubCategories(
        categoryID, subCategoryID, categoriesAndSubCategoryModel);

    changeLoadingState();

    return response;
  }

  Future<bool> deleteCategory(String categoryId) async {
    changeLoadingState(isLoading: true);

    bool response = await FirebaseDataSource().deleteCategory(categoryId);

    changeLoadingState();

    return response;
  }

  Future<bool> deleteSubCategory(
      String categoryId, String subCategoryId) async {
    changeLoadingState(isLoading: true);

    bool response =
        await FirebaseDataSource().deleteSubCategory(categoryId, subCategoryId);

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
