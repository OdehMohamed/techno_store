import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/shared/model/category_and_sub_category_model.dart';
import 'package:techno_store/core/shared/view_model/shared_state.dart';
import 'package:techno_store/core/utils/color_utilities.dart';
import 'package:techno_store/core/utils/custom_widgets.dart';
import 'package:techno_store/core/utils/message.dart';
import 'package:techno_store/core/utils/utilities.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/core2/widgets/main_app_bar.dart';
import 'package:techno_store/core2/widgets/main_button.dart';

import '../../utils/string_utilities.dart';
import '../../utils/widget_utilities.dart';
import '../view_model/manage_categories_state.dart';

class manageCategory extends StatefulWidget {
  const manageCategory({Key? key}) : super(key: key);

  @override
  State<manageCategory> createState() => _manageCategoryState();
}

bool enabled_sub_category = false;

class _manageCategoryState extends State<manageCategory> {
  late SharedState sharedState;
  late ManageCategories manageCategoriesState;
  late Future getCategoriesFuture;
  Future? getSubCategoriesFuture;
  CategoriesAndSubCategoryModel? selectedCategory;
  CategoriesAndSubCategoryModel? selectedSubCategory;
  CategoriesAndSubCategoryModel? add_sub_category_selectedCategory;

  TextEditingController edit_name_controller_en = TextEditingController();
  TextEditingController edit_name_controller_ar = TextEditingController();
  TextEditingController new_category_name_controller_en =
      TextEditingController();
  TextEditingController new_category_name_controller_ar =
      TextEditingController();

  TextEditingController new_sub_category_controller_en =
      TextEditingController();
  TextEditingController new_sub_category_controller_ar =
      TextEditingController();
  final _new_category_key = GlobalKey<FormState>();
  final _new_sub_category_key = GlobalKey<FormState>();
  final _drop_down_list_key = GlobalKey<FormState>();
  final _edit_delete_fields_key = GlobalKey<FormState>();

  final _advancedDrawerController = AdvancedDrawerController();

  @override
  void initState() {
    sharedState = context.read<SharedState>();
    manageCategoriesState = context.read<ManageCategories>();
    getCategoriesFuture = sharedState.getCategories();
    super.initState();
  }

  @override
  void dispose() {
    edit_name_controller_en.dispose();
    edit_name_controller_ar.dispose();
    new_category_name_controller_en.dispose();
    new_category_name_controller_ar.dispose();
    new_sub_category_controller_en.dispose();
    new_sub_category_controller_ar.dispose();
    super.dispose();
  }

  bool sub_category_flag = false;
  @override
  Widget build(BuildContext context) {
    feedbackMessage(bool value, String msg) {
      if (value) {
        Navigator.pop(context);
        Message.showLongToastMessage(msg.tr());
      }
    }

    sharedState = context.watch<SharedState>();
    manageCategoriesState = context.watch<ManageCategories>();

    change_sub_category_flag() {
      sub_category_flag = !sub_category_flag;
      if (sub_category_flag) {
        edit_name_controller_en.text = selectedSubCategory!.enName!;
        edit_name_controller_ar.text = selectedSubCategory!.arName!;
      } else {
        edit_name_controller_en.text = selectedCategory!.enName!;
        edit_name_controller_ar.text = selectedCategory!.arName!;
      }
    }

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(width <= 500 ? height * 0.05 : height * 0.08),
        child: MainAppBar(
          haveLeading: false,
          advancedDrawerController: _advancedDrawerController,
          title: 'Manage Categories'.tr(),
          onLanguageChanged: () => setState(() {}),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: sharedState.loading,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Form(
                    key: _drop_down_list_key,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 32,
                        ),
                        WidgetUtilities.autoSizeText("Categories",
                            textStyle:
                                const TextStyle(color: AppColors.primary)),
                        FutureBuilder(
                            future: getCategoriesFuture,
                            builder: (context, AsyncSnapshot snapshot) {
                              if (snapshot.hasData) {
                                List<CategoriesAndSubCategoryModel>
                                    futureCategories = snapshot.data;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: FormValidatorDropdown<
                                          CategoriesAndSubCategoryModel>(
                                        name: "CategoryName",
                                        dropDownValue: selectedCategory,
                                        onChanged: (newValue) {
                                          selectedCategory = newValue;
                                          getSubCategoriesFuture = sharedState
                                              .getSubCategories(newValue.id!);
                                          selectedSubCategory = null;
                                          edit_name_controller_en.text =
                                              selectedCategory!.enName!;
                                          edit_name_controller_ar.text =
                                              selectedCategory!.arName!;
                                          setState(() {});
                                        },
                                        items: List.generate(
                                            futureCategories.length,
                                            (index) => DropdownMenuItem<
                                                    CategoriesAndSubCategoryModel>(
                                                  value:
                                                      futureCategories[index],
                                                  child: Text(
                                                    StringUtilities
                                                        .getStringByLanguage(
                                                            context,
                                                            futureCategories[
                                                                    index]
                                                                .arName,
                                                            futureCategories[
                                                                    index]
                                                                .enName),
                                                    style: const TextStyle(
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                )),
                                        label: "Categories".tr(),
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox();
                            }),
                        const Divider(
                          thickness: 1,
                        ),
                        WidgetUtilities.autoSizeText(
                          "Sub-Categories",
                          textStyle: const TextStyle(color: Colors.black),
                        ),
                        getSubCategoriesFuture != null
                            ? FutureBuilder(
                                future: getSubCategoriesFuture,
                                builder: (context, AsyncSnapshot snapshot) {
                                  if (snapshot.hasData) {
                                    List<CategoriesAndSubCategoryModel>
                                        futureSubCategories = snapshot.data;
                                    if (futureSubCategories.isEmpty) {
                                      return SizedBox(
                                        width:
                                            Utilities.getDeviceWidth(context),
                                        height:
                                            Utilities.getDeviceHeight(context) *
                                                0.15,
                                        child: (Center(
                                            child: WidgetUtilities.autoSizeText(
                                                "there is no sub-categories at this category",
                                                textStyle: const TextStyle(
                                                    color: Colors.black)))),
                                      );
                                    } else {
                                      return Row(
                                        children: [
                                          Expanded(
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  if (selectedSubCategory ==
                                                      null) {
                                                    edit_name_controller_en
                                                        .text = "";
                                                    edit_name_controller_ar
                                                        .text = "";
                                                  } else {
                                                    edit_name_controller_en
                                                            .text =
                                                        selectedSubCategory!
                                                            .enName!;
                                                    edit_name_controller_ar
                                                            .text =
                                                        selectedSubCategory!
                                                            .arName!;
                                                  }
                                                  sub_category_flag = true;
                                                });
                                              },
                                              child: FormValidatorDropdown<
                                                  CategoriesAndSubCategoryModel>(
                                                name: "SubCategoryName",
                                                dropDownValue:
                                                    selectedSubCategory,
                                                optional: !sub_category_flag,
                                                onChanged: sub_category_flag
                                                    ? (newValue) {
                                                        selectedSubCategory =
                                                            newValue;
                                                        edit_name_controller_en
                                                                .text =
                                                            selectedSubCategory!
                                                                .enName!;
                                                        edit_name_controller_ar
                                                                .text =
                                                            selectedSubCategory!
                                                                .arName!;
                                                        setState(() {});
                                                      }
                                                    : null,
                                                items: List.generate(
                                                  futureSubCategories.length,
                                                  (index) => DropdownMenuItem<
                                                      CategoriesAndSubCategoryModel>(
                                                    value: futureSubCategories[
                                                        index],
                                                    child: Text(
                                                      StringUtilities
                                                          .getStringByLanguage(
                                                              context,
                                                              futureSubCategories[
                                                                      index]
                                                                  .arName,
                                                              futureSubCategories[
                                                                      index]
                                                                  .enName),
                                                    ),
                                                  ),
                                                ),
                                                label: "Sub-Categories".tr(),
                                              ),
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              InkWell(
                                                child: const Icon(
                                                  Icons.add_circle_outlined,
                                                  color: Colors.green,
                                                  size: 30,
                                                ),
                                                onTap: () async {
                                                  await showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        new_sub_category_controller_en
                                                                .text =
                                                            new_sub_category_controller_ar
                                                                .text = "";
                                                        return StatefulBuilder(
                                                            builder: (context,
                                                                StateSetter
                                                                    setState) {
                                                          return AlertDialog(
                                                            title: SizedBox(
                                                              width: Utilities
                                                                  .getDeviceWidth(
                                                                      context),
                                                              height: Utilities
                                                                      .getDeviceHeight(
                                                                          context) *
                                                                  0.05,
                                                              child: WidgetUtilities.autoSizeText(
                                                                  "Add sub-category",
                                                                  textStyle: const TextStyle(
                                                                      color: Colors
                                                                          .black),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center),
                                                            ),
                                                            content: SizedBox(
                                                                width: Utilities
                                                                    .getDeviceWidth(
                                                                        context),
                                                                height: Utilities
                                                                        .getDeviceHeight(
                                                                            context) *
                                                                    0.4,
                                                                child: Form(
                                                                  key:
                                                                      _new_sub_category_key,
                                                                  child: Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceEvenly,
                                                                    children: [
                                                                      FutureBuilder(
                                                                          future:
                                                                              getCategoriesFuture,
                                                                          builder:
                                                                              (context, AsyncSnapshot snapshot) {
                                                                            if (snapshot.hasData) {
                                                                              List<CategoriesAndSubCategoryModel> futureCategories = snapshot.data;
                                                                              return FormValidatorDropdown<CategoriesAndSubCategoryModel>(
                                                                                name: "CategoryName",
                                                                                dropDownValue: add_sub_category_selectedCategory,
                                                                                onChanged: (newValue) {
                                                                                  add_sub_category_selectedCategory = newValue;
                                                                                  setState(() {});
                                                                                },
                                                                                items: List.generate(
                                                                                    futureCategories.length,
                                                                                    (index) => DropdownMenuItem<CategoriesAndSubCategoryModel>(
                                                                                          value: futureCategories[index],
                                                                                          child: Text(StringUtilities.getStringByLanguage(context, futureCategories[index].arName, futureCategories[index].enName)),
                                                                                        )),
                                                                                label: "Categories".tr(),
                                                                              );
                                                                            }
                                                                            return const SizedBox();
                                                                          }),
                                                                      Container(
                                                                        width: Utilities.getDeviceWidth(context) *
                                                                            0.5,
                                                                        margin: const EdgeInsets
                                                                            .only(
                                                                            top:
                                                                                20),
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                20,
                                                                            right:
                                                                                20),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              ColorUtilities.white,
                                                                          border:
                                                                              Border.all(color: Colors.grey),
                                                                          borderRadius:
                                                                              BorderRadius.circular(5),
                                                                        ),
                                                                        child:
                                                                            TextFormField(
                                                                          validator:
                                                                              (value) {
                                                                            if (value == null ||
                                                                                value.trim().isEmpty) {
                                                                              return "Please Enter".tr() + " " + "New Sub-Category".tr() + "enLang".tr();
                                                                            }
                                                                            return null;
                                                                          },
                                                                          controller:
                                                                              new_sub_category_controller_en,
                                                                          style:
                                                                              const TextStyle(color: Colors.black),
                                                                          decoration:
                                                                              InputDecoration(
                                                                            border:
                                                                                InputBorder.none,
                                                                            hintText:
                                                                                'New Sub-Category'.tr() + "enLang".tr(),
                                                                            hintStyle:
                                                                                const TextStyle(color: Colors.grey, fontSize: 10),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        width: Utilities.getDeviceWidth(context) *
                                                                            0.5,
                                                                        margin: const EdgeInsets
                                                                            .only(
                                                                            top:
                                                                                20),
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            left:
                                                                                20,
                                                                            right:
                                                                                20),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          color:
                                                                              ColorUtilities.white,
                                                                          border:
                                                                              Border.all(color: Colors.grey),
                                                                          borderRadius:
                                                                              BorderRadius.circular(5),
                                                                        ),
                                                                        child:
                                                                            TextFormField(
                                                                          validator:
                                                                              (value) {
                                                                            if (value == null ||
                                                                                value.trim().isEmpty) {
                                                                              return "Please Enter".tr() + " " + "New Sub-Category".tr() + "arLang".tr();
                                                                            }
                                                                            return null;
                                                                          },
                                                                          controller:
                                                                              new_sub_category_controller_ar,
                                                                          style:
                                                                              const TextStyle(color: Colors.black),
                                                                          decoration:
                                                                              InputDecoration(
                                                                            border:
                                                                                InputBorder.none,
                                                                            hintText:
                                                                                'New Sub-Category'.tr() + "arLang".tr(),
                                                                            hintStyle:
                                                                                const TextStyle(color: Colors.grey, fontSize: 10),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                )),
                                                            actions: [
                                                              Center(
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    ElevatedButton(
                                                                      onPressed:
                                                                          () {
                                                                        if (_new_sub_category_key
                                                                            .currentState!
                                                                            .validate()) {
                                                                          manageCategoriesState
                                                                              .addSubCategory(
                                                                                  add_sub_category_selectedCategory!.id!,
                                                                                  CategoriesAndSubCategoryModel(
                                                                                    enName: new_sub_category_controller_en.text.trim(),
                                                                                    arName: new_sub_category_controller_ar.text.trim(),
                                                                                  ))
                                                                              .then((value) => feedbackMessage(value, "Added successfully"));
                                                                        }
                                                                      },
                                                                      child: Text(
                                                                          "Add"
                                                                              .tr()),
                                                                      style: ElevatedButton.styleFrom(
                                                                          backgroundColor:
                                                                              Colors.green),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 30,
                                                                    ),
                                                                    ElevatedButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child: const Text(
                                                                              "Cancel")
                                                                          .tr(),
                                                                      style: ElevatedButton.styleFrom(
                                                                          backgroundColor:
                                                                              Colors.grey),
                                                                    ),
                                                                  ],
                                                                ),
                                                              )
                                                            ],
                                                          );
                                                        });
                                                      });
                                                },
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              sub_category_flag
                                                  ? InkWell(
                                                      child: const Icon(
                                                        Icons.near_me_disabled,
                                                        color: Colors.grey,
                                                        size: 30,
                                                      ),
                                                      onTap: () {
                                                        setState(() {
                                                          change_sub_category_flag();
                                                        });
                                                      })
                                                  : const SizedBox(),
                                            ],
                                          )
                                        ],
                                      );
                                    }
                                  }
                                  return const SizedBox();
                                })
                            : const SizedBox(),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Form(
                    key: _edit_delete_fields_key,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: edit_name_controller_en,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'New Name'.tr() + "enLang".tr(),
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please Enter".tr() +
                                  " " +
                                  "New Name".tr() +
                                  "enLang".tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        TextFormField(
                          controller: edit_name_controller_ar,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'New Name'.tr() + "arLang".tr(),
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Please Enter".tr() +
                                  " " +
                                  "New Name".tr() +
                                  "arLang".tr();
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  MainButton(
                    onPressed: () {
                      if (_edit_delete_fields_key.currentState!.validate() &&
                          _drop_down_list_key.currentState!.validate()) {
                        if (sub_category_flag) {
                          selectedSubCategory!.arName =
                              edit_name_controller_ar.text.trim();
                          selectedSubCategory!.enName =
                              edit_name_controller_en.text.trim();
                          manageCategoriesState
                              .editSubCategories(
                                  selectedCategory!.id!,
                                  selectedSubCategory!.id!,
                                  selectedSubCategory!)
                              .then((value) => feedbackMessage(
                                  value, "Edited successfully"));
                        } else {
                          selectedCategory!.arName =
                              edit_name_controller_ar.text.trim();
                          selectedCategory!.enName =
                              edit_name_controller_en.text.trim();
                          manageCategoriesState
                              .editCategory(
                                  selectedCategory!.id!, selectedCategory!)
                              .then((value) => feedbackMessage(
                                  value, "Edited successfully"));
                        }
                      }
                    },
                    label: "Change",
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  MainButton(
                    onPressed: () {
                      if (sub_category_flag) {
                        if (_drop_down_list_key.currentState!.validate()) {
                          manageCategoriesState
                              .deleteSubCategory(selectedCategory!.id!,
                                  selectedSubCategory!.id!)
                              .then(
                                  (value) => feedbackMessage(value, "Deleted"));
                        }
                      } else {
                        if (_drop_down_list_key.currentState!.validate()) {
                          manageCategoriesState
                              .deleteCategory(selectedCategory!.id!)
                              .then(
                                  (value) => feedbackMessage(value, "Deleted"));
                        }
                      }
                    },
                    label: "Delete",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
