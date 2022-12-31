import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/shared/model/category_and_sub_category_model.dart';
import 'package:techno_store/core/shared/view_model/shared_state.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:techno_store/shared/custom_widgets.dart';
import 'package:techno_store/shared/message.dart';
import 'package:techno_store/shared/utilities.dart';

import '../../../shared/string_utilities.dart';
import '../../../shared/widget_utilities.dart';
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
  TextEditingController new_category_name_controller_en = TextEditingController();
  TextEditingController new_category_name_controller_ar = TextEditingController();

  TextEditingController new_sub_category_controller_en = TextEditingController();
  TextEditingController new_sub_category_controller_ar = TextEditingController();
  final _new_category_key =GlobalKey<FormState>();
  final _new_sub_category_key =GlobalKey<FormState>();
  final _drop_down_list_key =GlobalKey<FormState>();
  final _edit_delete_fields_key =GlobalKey<FormState>();

  @override
  void initState() {
    sharedState = context.read<SharedState>();
    manageCategoriesState=context.read<ManageCategories>();
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
  bool sub_category_flag=false;
  @override
  Widget build(BuildContext context) {
    sharedState = context.watch<SharedState>();
    manageCategoriesState=context.watch<ManageCategories>();

    change_sub_category_flag(){
      sub_category_flag=!sub_category_flag;
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: ModalProgressHUD(
        inAsyncCall: sharedState.loading,
        child: Column(
          children: [
            Container(
              color: ColorUtilities.backgroundContainer,
              child: Container(
                  padding: EdgeInsets.only(
                      top: Utilities.getDeviceHeight(context) * 0.1),
                  width: Utilities.getDeviceWidth(context),
                  height: Utilities.getDeviceHeight(context) * 0.2,
                  decoration: const BoxDecoration(
                    color: ColorUtilities.secondary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                    ),
                  ),
                  child: Container(
                    child: WidgetUtilities.autoSizeText("Manage Categories",
                        textAlign: TextAlign.center,
                        textStyle: TextStyle(
                            fontSize: 22, color: ColorUtilities.textColor)),
                  )),
            ),
            Container(
              color: ColorUtilities.secondary,
              child: Container(
                  width: Utilities.getDeviceWidth(context),
                  height: Utilities.getDeviceHeight(context) * 0.8,
                  decoration: const BoxDecoration(
                    color: ColorUtilities.backgroundContainer,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.only(
                        left: 20, right: 20, top: 20, bottom: 40),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Form(
                            key: _drop_down_list_key,
                            child: Column(
                            children: [
                              WidgetUtilities.autoSizeText("Categories", textStyle: TextStyle(color: Colors.black)),
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
                                                setState(() {});
                                              },
                                              items: List.generate(
                                                  futureCategories.length,
                                                      (index) => DropdownMenuItem<
                                                      CategoriesAndSubCategoryModel>(
                                                    value:
                                                    futureCategories[index],
                                                    child: Text(StringUtilities
                                                        .getStringByLanguage(
                                                        context,
                                                        futureCategories[
                                                        index]
                                                            .arName,
                                                        futureCategories[
                                                        index]
                                                            .enName)),
                                                  )),
                                              label: "Categories".tr(),
                                            ),
                                          ),
                                          InkWell(
                                            child: Icon(
                                              Icons.add_circle_outlined,
                                              color: Colors.green,
                                              size: 30,
                                            ),
                                            onTap: () async {
                                              await showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    new_category_name_controller_en.text=new_category_name_controller_ar.text="";
                                                    return AlertDialog(
                                                      title: Container(
                                                        width:
                                                        Utilities.getDeviceWidth(
                                                            context),
                                                        height:
                                                        Utilities.getDeviceHeight(
                                                            context) *
                                                            0.05,
                                                        child: WidgetUtilities
                                                            .autoSizeText(
                                                            "Add Category",
                                                            textStyle: TextStyle(
                                                                color:
                                                                Colors.black),
                                                            textAlign:
                                                            TextAlign.center),
                                                      ),
                                                      content: Container(
                                                          width: Utilities
                                                              .getDeviceWidth(
                                                              context),
                                                          height: Utilities
                                                              .getDeviceHeight(
                                                              context) *
                                                              0.3,
                                                          child:Form(
                                                            key: _new_category_key,
                                                            child:  Column(
                                                              mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceEvenly,
                                                              children: [
                                                                Container(
                                                                  width: Utilities
                                                                      .getDeviceWidth(
                                                                      context) *
                                                                      0.5,
                                                                  margin:
                                                                  EdgeInsets.only(
                                                                      top: 20),
                                                                  padding:
                                                                  EdgeInsets.only(
                                                                      left: 20,
                                                                      right: 20),
                                                                  decoration:
                                                                  BoxDecoration(
                                                                    color:
                                                                    ColorUtilities
                                                                        .white,
                                                                    border: Border.all(
                                                                        color: Colors
                                                                            .grey),
                                                                    borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                        5),
                                                                  ),
                                                                  child: TextFormField(
                                                                    controller:
                                                                    new_category_name_controller_en,
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black),
                                                                    decoration:
                                                                    InputDecoration(
                                                                      border:
                                                                      InputBorder
                                                                          .none,
                                                                      hintText:
                                                                      'New Category'
                                                                          .tr() +
                                                                          "enLang"
                                                                              .tr(),
                                                                      hintStyle: TextStyle(
                                                                          color: Colors
                                                                              .grey,
                                                                          fontSize: 14),
                                                                    ),
                                                                    validator: (value) {
                                                                      if (value == null || value.isEmpty) {
                                                                        return "Please Enter".tr()+" "+"New Category".tr()+"enLang";
                                                                      }
                                                                      return null;
                                                                    },
                                                                  ),
                                                                ),
                                                                Container(
                                                                  width: Utilities
                                                                      .getDeviceWidth(
                                                                      context) *
                                                                      0.5,
                                                                  margin:
                                                                  EdgeInsets.only(
                                                                      top: 20),
                                                                  padding:
                                                                  EdgeInsets.only(
                                                                      left: 20,
                                                                      right: 20),
                                                                  decoration:
                                                                  BoxDecoration(
                                                                    color:
                                                                    ColorUtilities
                                                                        .white,
                                                                    border: Border.all(
                                                                        color: Colors
                                                                            .grey),
                                                                    borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                        5),
                                                                  ),
                                                                  child: TextFormField(
                                                                    controller:
                                                                    new_category_name_controller_ar,
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black),
                                                                    decoration:
                                                                    InputDecoration(
                                                                      border:
                                                                      InputBorder
                                                                          .none,
                                                                      hintText:
                                                                      'New Category'
                                                                          .tr() +
                                                                          "arLang"
                                                                              .tr(),
                                                                      hintStyle: TextStyle(
                                                                          color: Colors
                                                                              .grey,
                                                                          fontSize: 14),
                                                                    ),
                                                                    validator: (value) {
                                                                      if (value == null || value.isEmpty) {
                                                                        return "Please Enter".tr()+" "+"New Category".tr()+"arLang";
                                                                      }
                                                                      return null;
                                                                    },
                                                                  ),
                                                                ),
                                                              ],
                                                            ),)
                                                      ),
                                                      actions: [
                                                        Center(
                                                          child: Row(
                                                            mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                            children: [
                                                              ElevatedButton(
                                                                onPressed: () {
                                                                  if (_new_category_key.currentState!.validate()){
                                                                    manageCategoriesState.addCategory(CategoriesAndSubCategoryModel(
                                                                      enName: new_category_name_controller_en.text,
                                                                      arName: new_category_name_controller_ar.text,
                                                                    )).then((value) => (){
                                                                      Navigator.pop(context);
                                                                      Message.showLongToastMessage("Added successfully");
                                                                    });
                                                                  }
                                                                },
                                                                child:
                                                                Text("Add".tr()),
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                    backgroundColor:
                                                                    Colors
                                                                        .green),
                                                              ),
                                                              SizedBox(
                                                                width: 30,
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child: Text("Cancel")
                                                                    .tr(),
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                    backgroundColor:
                                                                    Colors
                                                                        .grey),
                                                              ),
                                                            ],
                                                          ),
                                                        )
                                                      ],
                                                    );
                                                  });
                                            },
                                          ),
                                        ],
                                      );
                                    }
                                    return SizedBox();
                                  }),
                              Divider(thickness: 1,),
                              WidgetUtilities.autoSizeText("Sub-Categories",
                                  textStyle: TextStyle(color: Colors.black)),
                              getSubCategoriesFuture != null
                                  ? FutureBuilder(
                                  future: getSubCategoriesFuture,
                                  builder: (context, AsyncSnapshot snapshot) {
                                    if (snapshot.hasData) {
                                      List<CategoriesAndSubCategoryModel>
                                      futureSubCategories = snapshot.data;
                                      return Row(
                                        children: [
                                          Expanded(
                                            child:
                                            InkWell(
                                              onTap: (){
                                                setState(() {
                                                  sub_category_flag=true;
                                                });
                                              },
                                              child: FormValidatorDropdown<
                                                  CategoriesAndSubCategoryModel>(
                                                name: "SubCategoryName",
                                                dropDownValue: selectedSubCategory,
                                                optional: !sub_category_flag,
                                                onChanged:sub_category_flag? (newValue) {
                                                  selectedSubCategory = newValue;
                                                  setState(() {});
                                                }:null,
                                                items: List.generate(
                                                    futureSubCategories.length,
                                                        (index) => DropdownMenuItem<
                                                        CategoriesAndSubCategoryModel>(
                                                      value:
                                                      futureSubCategories[
                                                      index],
                                                      child: Text(StringUtilities
                                                          .getStringByLanguage(
                                                          context,
                                                          futureSubCategories[
                                                          index]
                                                              .arName,
                                                          futureSubCategories[
                                                          index]
                                                              .enName)),
                                                    )),
                                                label: "Sub-Categories".tr(),
                                              )
                                              ,),
                                          ),
                                          Column(
                                            children: [
                                              InkWell(
                                                child: Icon(
                                                  Icons.add_circle_outlined,
                                                  color: Colors.green,
                                                  size: 30,
                                                ),
                                                onTap: () async {
                                                  await showDialog(
                                                      context: context,
                                                      builder:
                                                          (BuildContext context) {
                                                        new_sub_category_controller_en.text=new_sub_category_controller_ar.text="";
                                                        return StatefulBuilder(builder: (context,StateSetter setState){
                                                          return AlertDialog(
                                                            title: Container(
                                                              width: Utilities
                                                                  .getDeviceWidth(
                                                                  context),
                                                              height: Utilities
                                                                  .getDeviceHeight(
                                                                  context) *
                                                                  0.05,
                                                              child: WidgetUtilities
                                                                  .autoSizeText(
                                                                  "Add sub-category",
                                                                  textStyle: TextStyle(
                                                                      color: Colors
                                                                          .black),
                                                                  textAlign:
                                                                  TextAlign
                                                                      .center),
                                                            ),
                                                            content: Container(
                                                                width: Utilities
                                                                    .getDeviceWidth(
                                                                    context),
                                                                height: Utilities
                                                                    .getDeviceHeight(
                                                                    context) *
                                                                    0.4,
                                                                child: Form(
                                                                  key: _new_sub_category_key,
                                                                  child: Column(
                                                                    mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceEvenly,
                                                                    children: [
                                                                      FutureBuilder(
                                                                          future: getCategoriesFuture,
                                                                          builder: (context, AsyncSnapshot snapshot) {
                                                                            if (snapshot.hasData) {
                                                                              List<CategoriesAndSubCategoryModel>
                                                                              futureCategories = snapshot.data;
                                                                              return FormValidatorDropdown<
                                                                                  CategoriesAndSubCategoryModel>(
                                                                                name: "CategoryName",
                                                                                dropDownValue: add_sub_category_selectedCategory,
                                                                                onChanged: (newValue) {
                                                                                  add_sub_category_selectedCategory = newValue;
                                                                                  setState(() {});
                                                                                },
                                                                                items: List.generate(
                                                                                    futureCategories.length,
                                                                                        (index) => DropdownMenuItem<
                                                                                        CategoriesAndSubCategoryModel>(
                                                                                      value:
                                                                                      futureCategories[index],
                                                                                      child: Text(StringUtilities
                                                                                          .getStringByLanguage(
                                                                                          context,
                                                                                          futureCategories[
                                                                                          index]
                                                                                              .arName,
                                                                                          futureCategories[
                                                                                          index]
                                                                                              .enName)),
                                                                                    )),
                                                                                label: "Categories".tr(),
                                                                              );
                                                                            }
                                                                            return SizedBox();
                                                                          }),
                                                                      Container(
                                                                        width: Utilities
                                                                            .getDeviceWidth(
                                                                            context) *
                                                                            0.5,
                                                                        margin: EdgeInsets
                                                                            .only(
                                                                            top: 20),
                                                                        padding: EdgeInsets
                                                                            .only(
                                                                            left: 20,
                                                                            right:
                                                                            20),
                                                                        decoration:
                                                                        BoxDecoration(
                                                                          color:
                                                                          ColorUtilities
                                                                              .white,
                                                                          border: Border.all(
                                                                              color: Colors
                                                                                  .grey),
                                                                          borderRadius:
                                                                          BorderRadius
                                                                              .circular(
                                                                              5),
                                                                        ),
                                                                        child: TextField(
                                                                          controller:
                                                                          new_sub_category_controller_en,
                                                                          style: TextStyle(
                                                                              color: Colors
                                                                                  .black),
                                                                          decoration:
                                                                          InputDecoration(
                                                                            border:
                                                                            InputBorder
                                                                                .none,
                                                                            hintText: 'New Sub-Category'
                                                                                .tr() +
                                                                                "enLang"
                                                                                    .tr(),
                                                                            hintStyle: TextStyle(
                                                                                color: Colors
                                                                                    .grey,
                                                                                fontSize:
                                                                                14),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      Container(
                                                                        width: Utilities
                                                                            .getDeviceWidth(
                                                                            context) *
                                                                            0.5,
                                                                        margin: EdgeInsets
                                                                            .only(
                                                                            top: 20),
                                                                        padding: EdgeInsets
                                                                            .only(
                                                                            left: 20,
                                                                            right:
                                                                            20),
                                                                        decoration:
                                                                        BoxDecoration(
                                                                          color:
                                                                          ColorUtilities
                                                                              .white,
                                                                          border: Border.all(
                                                                              color: Colors
                                                                                  .grey),
                                                                          borderRadius:
                                                                          BorderRadius
                                                                              .circular(
                                                                              5),
                                                                        ),
                                                                        child: TextField(
                                                                          controller:
                                                                          new_sub_category_controller_ar,
                                                                          style: TextStyle(
                                                                              color: Colors
                                                                                  .black),
                                                                          decoration:
                                                                          InputDecoration(
                                                                            border:
                                                                            InputBorder
                                                                                .none,
                                                                            hintText: 'New Sub-Category'
                                                                                .tr() +
                                                                                "arLang"
                                                                                    .tr(),
                                                                            hintStyle: TextStyle(
                                                                                color: Colors
                                                                                    .grey,
                                                                                fontSize:
                                                                                14),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                )
                                                            ),
                                                            actions: [
                                                              Center(
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                                  children: [
                                                                    ElevatedButton(
                                                                      onPressed: () {
                                                                        if (_new_sub_category_key.currentState!.validate()) {
                                                                          manageCategoriesState.addSubCategory(add_sub_category_selectedCategory!.id!,CategoriesAndSubCategoryModel(
                                                                            enName: new_sub_category_controller_en.text,
                                                                            arName: new_sub_category_controller_ar.text,
                                                                          )).then((value) => (){
                                                                            Navigator.pop(context);
                                                                            Message.showLongToastMessage("Added successfully");
                                                                          });
                                                                        }
                                                                      },
                                                                      child: Text(
                                                                          "Add".tr()),
                                                                      style: ElevatedButton
                                                                          .styleFrom(
                                                                          backgroundColor:
                                                                          Colors
                                                                              .green),
                                                                    ),
                                                                    SizedBox(
                                                                      width: 30,
                                                                    ),
                                                                    ElevatedButton(
                                                                      onPressed: () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                      Text("Cancel")
                                                                          .tr(),
                                                                      style: ElevatedButton
                                                                          .styleFrom(
                                                                          backgroundColor:
                                                                          Colors
                                                                              .grey),
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
                                              SizedBox(height: 10,),
                                              sub_category_flag?
                                              InkWell(
                                                  child: Icon(
                                                    Icons.near_me_disabled,
                                                    color: Colors.grey,
                                                    size: 30,
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      change_sub_category_flag();
                                                    });
                                                  }
                                              )
                                                  :SizedBox(),
                                            ],
                                          )
                                        ],
                                      );
                                    }
                                    return SizedBox();
                                  })
                                  : SizedBox(),
                            ],
                          ),
                          ),
                          Form(
                            key: _edit_delete_fields_key,
                            child:  Column(
                            children: [
                              Container(
                                width: Utilities.getDeviceWidth(context) * 0.5,
                                margin: EdgeInsets.only(top: 20),
                                padding: EdgeInsets.only(left: 20, right: 20),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                  controller: edit_name_controller_en,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'New Name'.tr()+"enLang".tr(),
                                    hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter".tr()+" "+"New Name".tr()+"enLang".tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              Container(
                                width: Utilities.getDeviceWidth(context) * 0.5,
                                margin: EdgeInsets.only(top: 20),
                                padding: EdgeInsets.only(left: 20, right: 20),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                  controller: edit_name_controller_ar,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'New Name'.tr()+"arLang".tr(),
                                    hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter".tr()+" "+"New Name".tr()+"arLang".tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),),
                          SizedBox(
                            height: 20,
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 10,bottom: 10),
                            width: Utilities.getDeviceWidth(context) * 0.5,
                            height: Utilities.getDeviceHeight(context) * 0.05,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_edit_delete_fields_key.currentState!.validate()&&_drop_down_list_key.currentState!.validate()){
                                  if (sub_category_flag){
                                    manageCategoriesState.editSubCategories(selectedCategory!.id!,selectedSubCategory!.id!, selectedCategory!).then((value) => (){
                                      Navigator.pop(context);
                                      Message.showLongToastMessage("Edited successfully".tr());
                                    });
                                  }
                                  else {
                                    selectedCategory!.arName=edit_name_controller_ar.text;
                                    selectedCategory!.enName=edit_name_controller_en.text;
                                    manageCategoriesState.editCategory(selectedCategory!.id!, selectedCategory!).then((value) => (){
                                      Navigator.pop(context);
                                      Message.showLongToastMessage("Edited successfully".tr());
                                    });
                                  }
                                }
                              },
                              child: WidgetUtilities.autoSizeText("Change"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                textStyle: TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          Container(
                              margin: EdgeInsets.only(top: 10,bottom: 10),
                              width: Utilities.getDeviceWidth(context) * 0.5,
                              height: Utilities.getDeviceHeight(context) * 0.05,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (sub_category_flag){
                                    if (_drop_down_list_key.currentState!.validate()){
                                      manageCategoriesState.deleteSubCategory(selectedCategory!.id!,selectedSubCategory!.id!).then((value) => (){
                                        Navigator.pop(context);
                                        Message.showLongToastMessage("Deleted".tr());
                                      });
                                    }
                                  }
                                  else {
                                    if (_drop_down_list_key.currentState!.validate()){
                                      manageCategoriesState.deleteCategory(selectedCategory!.id!).then((value) => (){
                                        Navigator.pop(context);
                                        Message.showLongToastMessage("Deleted".tr());
                                      });
                                    }
                                  }
                                },
                                child: WidgetUtilities.autoSizeText("Delete"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  textStyle: TextStyle(
                                    fontSize: 20,
                                  ),
                                ),
                              )),
                        ],
                      ),
                    )
                  )),
            )
          ],
        ),
      ),
    );
  }
}
