import 'package:flutter/cupertino.dart';
import 'package:techno_store/core/shared/model/category_and_sub_category_model.dart';
import 'package:techno_store/data_source/firebase.dart';

class SharedState extends ChangeNotifier{
  bool loading = false;

  Future<List<CategoriesAndSubCategoryModel>> getCategories() async {
    return await FirebaseDataSource().getCategories();
  }
  void refresh() {
    notifyListeners();
  }
}