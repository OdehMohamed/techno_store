import 'package:flutter/material.dart';
import 'package:techno_store/core/shared/model/category_and_sub_category_model.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:techno_store/shared/string_utilities.dart';
import 'package:techno_store/shared/utilities.dart';
import 'package:techno_store/shared/widget_utilities.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

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
//
// class FormValidatorDropdown<T> extends StatelessWidget {
//   const FormValidatorDropdown(
//       {required this.label,
//         this.onChanged,
//         required this.items,
//         required this.dropDownValue,
//         this.showErrorText = true,
//         this.optional = false,
//         Key? key})
//       : super(key: key);
//
//   final String label;
//   final bool showErrorText;
//   final bool optional;
//   final ValueChanged<T>? onChanged;
//   final T? dropDownValue;
//   final List<DropdownMenuItem<T>> items;
//
//   @override
//   Widget build(BuildContext context) {
//     return InputDecorator(
//       decoration: InputDecoration(
//         label: Text(label),
//       ),
//       //SSCUI.getDefaultInputDecoration(context, label, errorText: state.errorText),
//       child: Opacity(
//         opacity: 1,
//         child: DropdownButton<T>(
//           isExpanded: true,
//           underline: const SizedBox.shrink(),
//           //iconSize: SSCUI.SMALL_ICON_SIZE,
//           value: dropDownValue,
//           onChanged: (T? newValue) async {
//             onChanged!(newValue as T);
//             //state.didChange(newValue);
//           },
//           items: items,
//         ),
//       ),
//     );
//   }
// }

class FormValidatorDropdown<T> extends StatelessWidget {
  const FormValidatorDropdown(
      {required this.label,
        required this.name,
        this.onChanged,
        required this.items,
        required this.dropDownValue,
        this.showErrorText = true,
        this.optional = false,
        Key? key})
      : super(key: key);

  final String label;
  final String name;
  final bool showErrorText;
  final bool optional;
  final ValueChanged<T>? onChanged;
  final T? dropDownValue;
  final List<DropdownMenuItem<T>> items;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField(
      autovalidateMode: AutovalidateMode.always,
      name: name,
      builder: (FormFieldState<T> state) {
        return InputDecorator(
          decoration: InputDecoration(
            label: Text(label),
            errorText: state.errorText
          ),
          //SSCUI.getDefaultInputDecoration(context, label, errorText: state.errorText),
          child: Opacity(
            opacity: 1,
            child: DropdownButton<T>(
              isExpanded: true,
              underline: const SizedBox.shrink(),
              //iconSize: SSCUI.SMALL_ICON_SIZE,
              value: dropDownValue,
              onChanged: (T? newValue) async {
                onChanged!(newValue as T);
                state.didChange(newValue);
              },
              items: items,
            ),
          ),
        );

      },
      validator: FormBuilderValidators.compose([
        if (!optional)
          FormBuilderValidators.required(
              errorText: showErrorText
                  ? "this_field_is_required"
                  : ' '),
      ]),
    );
  }
}



//
// class FormValidatorDropdown<T> extends StatelessWidget {
//   const FormValidatorDropdown(
//       {required this.label,
//         required this.name,
//         this.onChanged,
//         required this.items,
//         required this.dropDownValue,
//         this.showErrorText = true,
//         this.optional = false,
//         Key? key})
//       : super(key: key);
//
//   final String label;
//   final String name;
//   final bool showErrorText;
//   final bool optional;
//   final ValueChanged<T>? onChanged;
//   final T? dropDownValue;
//   final List<DropdownMenuItem<T>> items;
//
//   @override
//   Widget build(BuildContext context) {
//     return FormBuilderField(
//       autovalidateMode: AutovalidateMode.always,
//       name: name,
//       builder: (FormFieldState<T> state) {
//         return InputDecorator(
//           decoration: SSCUI.getDefaultInputDecoration(context, label, errorText: state.errorText),
//           child: DropdownButton<T>(
//             isExpanded: true,
//             underline: const SizedBox.shrink(),
//             iconSize: SSCUI.SMALL_ICON_SIZE,
//             value: dropDownValue,
//             onChanged: (T? newValue) async {
//               onChanged!(newValue as T);
//               state.didChange(newValue);
//             },
//             items: items,
//           ),
//         );
//       },
//       validator: FormBuilderValidators.compose([
//         if (!optional)
//           FormBuilderValidators.required(
//               errorText: showErrorText
//                   ? AppLocalization.of(context).getTranslatedValues("this_field_is_required")
//                   : ' '),
//       ]),
//     );
//   }
// }
