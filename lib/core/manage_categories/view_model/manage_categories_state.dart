import 'package:flutter/cupertino.dart';
import 'package:techno_store/data_source/firebase.dart';

import '../../shared/model/category_and_sub_category_model.dart';

class ManageCategories extends ChangeNotifier {
  bool loading = false;

  Future<void> addCategory(
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    loading = true;

    await FirebaseDataSource().addCategory(categoriesAndSubCategoryModel);

    changeLoadingState();
  }

  Future<void> editCategory(String categoryID,
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    loading = true;

    await FirebaseDataSource()
        .editCategory(categoryID, categoriesAndSubCategoryModel);

    changeLoadingState();
  }

  Future<void> addSubCategory(String categoryID,
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    loading = true;

    await FirebaseDataSource()
        .addSubCategory(categoryID, categoriesAndSubCategoryModel);

    changeLoadingState();
  }

  Future<void> editSubCategories(String categoryID, String subCategoryID,
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    loading = true;

    await FirebaseDataSource().editSubCategories(
        categoryID, subCategoryID, categoriesAndSubCategoryModel);

    changeLoadingState();
  }

  Future<void> deleteCategory(String categoryId) async {
    loading = true;

    await FirebaseDataSource().deleteCategory(categoryId);

    changeLoadingState();
  }

  Future<void> deleteSubCategory(
      String categoryId, String subCategoryId) async {
    loading = true;

    await FirebaseDataSource().deleteSubCategory(categoryId, subCategoryId);

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
