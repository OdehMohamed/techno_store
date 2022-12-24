import 'package:flutter/material.dart';
import 'package:techno_store/core/shared/model/category_and_sub_category_model.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:techno_store/shared/string_utilities.dart';
import 'package:techno_store/shared/utilities.dart';
import 'package:techno_store/shared/widget_utilities.dart';

class CustomWidgets {
  static InputDecorator categoriesDropdownMenu(
      BuildContext context,
      List<CategoriesAndSubCategoryModel>? categoriesList,
      CategoriesAndSubCategoryModel? value,
      Function notify) {
    return InputDecorator(
        decoration: InputDecoration(),
        child: Opacity(
          opacity: 1,
          child: DropdownButton<CategoriesAndSubCategoryModel>(
            isExpanded: true,
            underline: const SizedBox.shrink(),
            value: value,
            //Value
            onChanged: (CategoriesAndSubCategoryModel? newValue)  {
              value = newValue!;
              notify(newValue);
            },
            items: List.generate(
                categoriesList?.length ?? 0,
                (index) => DropdownMenuItem<CategoriesAndSubCategoryModel>(
                      value: categoriesList![index],
                      child: Text(StringUtilities.getStringByLanguage(
                          context,
                          categoriesList[index].arName,
                          categoriesList[index].enName)),
                    )),
          ),
        ));
  }
}
