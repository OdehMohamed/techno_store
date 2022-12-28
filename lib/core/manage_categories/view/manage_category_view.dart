import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/shared/model/category_and_sub_category_model.dart';
import 'package:techno_store/core/shared/view_model/shared_state.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:techno_store/shared/custom_widgets.dart';
import 'package:techno_store/shared/utilities.dart';

import '../../../shared/string_utilities.dart';
import '../../../shared/widget_utilities.dart';

class manageCategory extends StatefulWidget {
  const manageCategory({Key? key}) : super(key: key);

  @override
  State<manageCategory> createState() => _manageCategoryState();
}

bool enabled_sub_category = false;
// var categories = [
//   'Item 1',
//   'Item 2',
//   'Item 3',
//   'Item 4',
//   'Item 5',
// ];
// var sub_categories = [
//   'Item 1',
//   'Item 2',
//   'Item 3',
//   'Item 4',
//   'Item 5',
// ];
// String? sub_category_dropdown_value;
// String? category_dropdown_value;



class _manageCategoryState extends State<manageCategory> {
  late SharedState sharedState;

  late Future getCategoriesFuture;
  Future? getSubCategoriesFuture;
  CategoriesAndSubCategoryModel? selectedCategory;
  CategoriesAndSubCategoryModel? selectedSubCategory;


  TextEditingController edit_name_controller = TextEditingController();
  TextEditingController new_category_name_controller_en = TextEditingController();
  TextEditingController new_category_name_controller_ar = TextEditingController();

  TextEditingController new_sub_category_controller_en = TextEditingController();
  TextEditingController new_sub_category_controller_ar = TextEditingController();


  @override
  void initState() {
    sharedState = context.read<SharedState>();
    getCategoriesFuture = sharedState.getCategories();
    super.initState();
  }

  @override
  void dispose() {
    edit_name_controller.dispose();
    new_category_name_controller_en.dispose();
    new_category_name_controller_ar.dispose();
    new_sub_category_controller_en.dispose();
    new_sub_category_controller_ar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    sharedState = context.watch<SharedState>();
    Widget card(
      String title,
      Icon icon,
    ) {
      return Column(
        children: [
          InkWell(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.all(20),
              height: Utilities.getDeviceHeight(context) * 0.1,
              width: Utilities.getDeviceWidth(context),
              child: Column(
                children: [
                  Row(
                    children: [
                      icon,
                      Text(
                        title,
                        style: TextStyle(color: ColorUtilities.white),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          Divider(
            color: Colors.grey,
            thickness: 1,
          ),
        ],
      );
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        WidgetUtilities.autoSizeText("Categories",
                            textStyle: TextStyle(color: Colors.black)),
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
                                        label: "Categories",
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
                                                    child: Column(
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
                                                          child: TextField(
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
                                                          child: TextField(
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
                                                          ),
                                                        ),
                                                      ],
                                                    )),
                                                actions: [
                                                  Center(
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        ElevatedButton(
                                                          onPressed: () {},
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
                        // Row(
                        //   children: [
                        //     Container(
                        //       width: Utilities.getDeviceWidth(context) * 0.7,
                        //       margin: EdgeInsets.all(15),
                        //       child: DropdownButton(
                        //         isExpanded: true,
                        //         underline: SizedBox(),
                        //         hint: WidgetUtilities.autoSizeText("Category",
                        //             textStyle: TextStyle(color: Colors.black)),
                        //         value: category_dropdown_value,
                        //         icon: const Icon(Icons.keyboard_arrow_down),
                        //         items: categories.map((String items) {
                        //           return DropdownMenuItem(
                        //             value: items,
                        //             child: WidgetUtilities.autoSizeText(items,
                        //                 textStyle:
                        //                     TextStyle(color: Colors.black)),
                        //           );
                        //         }).toList(),
                        //         onChanged: (String? newValue) {
                        //           setState(() {
                        //             category_dropdown_value = newValue!;
                        //           });
                        //         },
                        //       ),
                        //     ),
                        //     InkWell(
                        //       child: Icon(
                        //         Icons.add_circle_outlined,
                        //         color: Colors.green,
                        //         size: 30,
                        //       ),
                        //       onTap: () async {
                        //         await showDialog(
                        //             context: context,
                        //             builder: (BuildContext context) {
                        //               return AlertDialog(
                        //                 title: Container(
                        //                   width:
                        //                       Utilities.getDeviceWidth(context),
                        //                   height:
                        //                       Utilities.getDeviceHeight(context) *
                        //                           0.05,
                        //                   child: WidgetUtilities.autoSizeText(
                        //                       "Add Category",
                        //                       textStyle:
                        //                           TextStyle(color: Colors.black),
                        //                       textAlign: TextAlign.center),
                        //                 ),
                        //                 content: Container(
                        //                     width:
                        //                         Utilities.getDeviceWidth(context),
                        //                     height: Utilities.getDeviceHeight(
                        //                             context) *
                        //                         0.3,
                        //                     child: Column(
                        //                       mainAxisAlignment:
                        //                           MainAxisAlignment.spaceEvenly,
                        //                       children: [
                        //                         Container(
                        //                           width: Utilities.getDeviceWidth(
                        //                                   context) *
                        //                               0.5,
                        //                           margin:
                        //                               EdgeInsets.only(top: 20),
                        //                           padding: EdgeInsets.only(
                        //                               left: 20, right: 20),
                        //                           decoration: BoxDecoration(
                        //                             color: ColorUtilities.white,
                        //                             border: Border.all(
                        //                                 color: Colors.grey),
                        //                             borderRadius:
                        //                                 BorderRadius.circular(5),
                        //                           ),
                        //                           child: TextField(
                        //                             controller:
                        //                                 new_category_name_controller_en,
                        //                             style: TextStyle(
                        //                                 color: Colors.black),
                        //                             decoration: InputDecoration(
                        //                               border: InputBorder.none,
                        //                               hintText:
                        //                                   'New Category'.tr() +
                        //                                       "enLang".tr(),
                        //                               hintStyle: TextStyle(
                        //                                   color: Colors.grey,
                        //                                   fontSize: 14),
                        //                             ),
                        //                           ),
                        //                         ),
                        //                         Container(
                        //                           width: Utilities.getDeviceWidth(
                        //                                   context) *
                        //                               0.5,
                        //                           margin:
                        //                               EdgeInsets.only(top: 20),
                        //                           padding: EdgeInsets.only(
                        //                               left: 20, right: 20),
                        //                           decoration: BoxDecoration(
                        //                             color: ColorUtilities.white,
                        //                             border: Border.all(
                        //                                 color: Colors.grey),
                        //                             borderRadius:
                        //                                 BorderRadius.circular(5),
                        //                           ),
                        //                           child: TextField(
                        //                             controller:
                        //                                 new_category_name_controller_ar,
                        //                             style: TextStyle(
                        //                                 color: Colors.black),
                        //                             decoration: InputDecoration(
                        //                               border: InputBorder.none,
                        //                               hintText:
                        //                                   'New Category'.tr() +
                        //                                       "arLang".tr(),
                        //                               hintStyle: TextStyle(
                        //                                   color: Colors.grey,
                        //                                   fontSize: 14),
                        //                             ),
                        //                           ),
                        //                         ),
                        //                       ],
                        //                     )),
                        //                 actions: [
                        //                   Center(
                        //                     child: Row(
                        //                       mainAxisAlignment:
                        //                           MainAxisAlignment.center,
                        //                       children: [
                        //                         ElevatedButton(
                        //                           onPressed: () {},
                        //                           child: Text("Add".tr()),
                        //                           style: ElevatedButton.styleFrom(
                        //                               backgroundColor:
                        //                                   Colors.green),
                        //                         ),
                        //                         SizedBox(
                        //                           width: 30,
                        //                         ),
                        //                         ElevatedButton(
                        //                           onPressed: () {
                        //                             Navigator.pop(context);
                        //                           },
                        //                           child: Text("Cancel").tr(),
                        //                           style: ElevatedButton.styleFrom(
                        //                               backgroundColor:
                        //                                   Colors.grey),
                        //                         ),
                        //                       ],
                        //                     ),
                        //                   )
                        //                 ],
                        //               );
                        //             });
                        //       },
                        //     )
                        //   ],
                        // ),
                        // Divider(
                        //   thickness: 1,
                        //   color: Colors.grey,
                        // ),
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
                                          child: FormValidatorDropdown<
                                              CategoriesAndSubCategoryModel>(
                                            name: "SubCategoryName",
                                            dropDownValue: selectedSubCategory,
                                            onChanged: (newValue) {
                                              selectedSubCategory = newValue;
                                              setState(() {});
                                            },
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
                                            label: "Sub Categories",
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
                                                builder:
                                                    (BuildContext context) {
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
                                                              "Add Category",
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
                                                            0.3,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceEvenly,
                                                          children: [
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
                                                                    new_category_name_controller_en,
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black),
                                                                decoration:
                                                                    InputDecoration(
                                                                  border:
                                                                      InputBorder
                                                                          .none,
                                                                  hintText: 'New Category'
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
                                                                    new_category_name_controller_ar,
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black),
                                                                decoration:
                                                                    InputDecoration(
                                                                  border:
                                                                      InputBorder
                                                                          .none,
                                                                  hintText: 'New Category'
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
                                                        )),
                                                    actions: [
                                                      Center(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            ElevatedButton(
                                                              onPressed: () {},
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
                                          },
                                        ),
                                      ],
                                    );
                                  }
                                  return SizedBox();
                                })
                            : SizedBox(),
                        // Row(children: [
                        //   Container(
                        //       width: Utilities.getDeviceWidth(context) * 0.7,
                        //       margin: EdgeInsets.all(15),
                        //       child: InkWell(
                        //         child: DropdownButton(
                        //             isExpanded: true,
                        //             underline: SizedBox(),
                        //             hint: WidgetUtilities.autoSizeText(
                        //               "Sub-Categories",
                        //               textStyle: TextStyle(
                        //                   color: enabled_sub_category
                        //                       ? Colors.black
                        //                       : Colors.black12),
                        //             ),
                        //             value: sub_category_dropdown_value,
                        //             icon: Icon(
                        //               Icons.keyboard_arrow_down,
                        //               color: enabled_sub_category
                        //                   ? Colors.black
                        //                   : Colors.black12,
                        //             ),
                        //             items: sub_categories.map((String items) {
                        //               return DropdownMenuItem(
                        //                 value: items,
                        //                 child: WidgetUtilities.autoSizeText(
                        //                     items,
                        //                     textStyle:
                        //                         TextStyle(color: Colors.black)),
                        //               );
                        //             }).toList(),
                        //             onChanged: enabled_sub_category
                        //                 ? (String? newValue) {
                        //                     setState(() {
                        //                       category_dropdown_value =
                        //                           newValue!;
                        //                     });
                        //                   }
                        //                 : null),
                        //         onTap: () {
                        //           enabled_sub_category = true;
                        //           setState(() {});
                        //         },
                        //       )),
                        //   Column(
                        //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        //     children: [
                        //       enabled_sub_category
                        //           ? InkWell(
                        //               child: Icon(
                        //                 Icons.near_me_disabled,
                        //                 color: Colors.grey,
                        //                 size: 30,
                        //               ),
                        //               onTap: () {
                        //                 enabled_sub_category = false;
                        //                 setState(() {});
                        //               },
                        //             )
                        //           : Container(),
                        //       InkWell(
                        //         child: Icon(
                        //           Icons.add_circle_outlined,
                        //           color: Colors.green,
                        //           size: 30,
                        //         ),
                        //         onTap: () {
                        //           showDialog<Image>(
                        //             context: context,
                        //             builder: (BuildContext context) =>
                        //                 AlertDialog(
                        //               title: Container(
                        //                 child: WidgetUtilities.autoSizeText(
                        //                     "Add sub-category",
                        //                     textStyle:
                        //                         TextStyle(color: Colors.black),
                        //                     textAlign: TextAlign.center),
                        //                 width:
                        //                     Utilities.getDeviceWidth(context),
                        //                 height:
                        //                     Utilities.getDeviceHeight(context) *
                        //                         0.05,
                        //               ),
                        //               content: Container(
                        //                   width:
                        //                       Utilities.getDeviceWidth(context),
                        //                   height: Utilities.getDeviceHeight(
                        //                           context) *
                        //                       0.3,
                        //                   child: Column(
                        //                     children: [
                        //                       Container(
                        //                         width: Utilities.getDeviceWidth(
                        //                                 context) *
                        //                             0.7,
                        //                         margin: EdgeInsets.all(15),
                        //                         child: DropdownButton(
                        //                           isExpanded: true,
                        //                           underline: SizedBox(),
                        //                           hint: WidgetUtilities
                        //                               .autoSizeText("Category",
                        //                                   textStyle: TextStyle(
                        //                                       color: Colors
                        //                                           .black)),
                        //                           value:
                        //                               category_dropdown_value,
                        //                           icon: const Icon(Icons
                        //                               .keyboard_arrow_down),
                        //                           items: categories
                        //                               .map((String items) {
                        //                             return DropdownMenuItem(
                        //                               value: items,
                        //                               child: WidgetUtilities
                        //                                   .autoSizeText(items,
                        //                                       textStyle: TextStyle(
                        //                                           color: Colors
                        //                                               .black)),
                        //                             );
                        //                           }).toList(),
                        //                           onChanged:
                        //                               (String? newValue) {
                        //                             setState(() {
                        //                               category_dropdown_value =
                        //                                   newValue!;
                        //                             });
                        //                           },
                        //                         ),
                        //                       ),
                        //                       Container(
                        //                         width: Utilities.getDeviceWidth(
                        //                                 context) *
                        //                             0.5,
                        //                         margin:
                        //                             EdgeInsets.only(top: 20),
                        //                         padding: EdgeInsets.only(
                        //                             left: 20, right: 20),
                        //                         decoration: BoxDecoration(
                        //                           color: ColorUtilities.white,
                        //                           border: Border.all(
                        //                               color: Colors.grey),
                        //                           borderRadius:
                        //                               BorderRadius.circular(5),
                        //                         ),
                        //                         child: TextField(
                        //                           controller:
                        //                               new_sub_category_controller_en,
                        //                           style: TextStyle(
                        //                               color: Colors.black),
                        //                           decoration: InputDecoration(
                        //                             border: InputBorder.none,
                        //                             hintText: 'New Sub-Category'
                        //                                     .tr() +
                        //                                 "enLang".tr(),
                        //                             hintStyle: TextStyle(
                        //                                 color: Colors.grey,
                        //                                 fontSize: 12),
                        //                           ),
                        //                         ),
                        //                       ),
                        //                       Container(
                        //                         width: Utilities.getDeviceWidth(
                        //                                 context) *
                        //                             0.5,
                        //                         margin:
                        //                             EdgeInsets.only(top: 20),
                        //                         padding: EdgeInsets.only(
                        //                             left: 20, right: 20),
                        //                         decoration: BoxDecoration(
                        //                           color: ColorUtilities.white,
                        //                           border: Border.all(
                        //                               color: Colors.grey),
                        //                           borderRadius:
                        //                               BorderRadius.circular(5),
                        //                         ),
                        //                         child: TextField(
                        //                           controller:
                        //                               new_sub_category_controller_ar,
                        //                           style: TextStyle(
                        //                               color: Colors.black),
                        //                           decoration: InputDecoration(
                        //                             border: InputBorder.none,
                        //                             hintText: 'New Sub-Category'
                        //                                     .tr() +
                        //                                 "arLang".tr(),
                        //                             hintStyle: TextStyle(
                        //                                 color: Colors.grey,
                        //                                 fontSize: 12),
                        //                           ),
                        //                         ),
                        //                       ),
                        //                     ],
                        //                   )),
                        //               actions: [
                        //                 Center(
                        //                   child: Row(
                        //                     mainAxisAlignment:
                        //                         MainAxisAlignment.center,
                        //                     children: [
                        //                       ElevatedButton(
                        //                         onPressed: () {},
                        //                         child: Text("Add".tr()),
                        //                         style: ElevatedButton.styleFrom(
                        //                             backgroundColor:
                        //                                 Colors.green),
                        //                       ),
                        //                       SizedBox(
                        //                         width: 30,
                        //                       ),
                        //                       ElevatedButton(
                        //                         onPressed: () {
                        //                           Navigator.pop(context);
                        //                         },
                        //                         child: Text("Cancel".tr()),
                        //                         style: ElevatedButton.styleFrom(
                        //                             backgroundColor:
                        //                                 Colors.grey),
                        //                       ),
                        //                     ],
                        //                   ),
                        //                 )
                        //               ],
                        //             ),
                        //           );
                        //         },
                        //       ),
                        //     ],
                        //   )
                        // ]),
                        // Divider(
                        //   thickness: 1,
                        //   color: Colors.grey,
                        // ),
                        Container(
                          width: Utilities.getDeviceWidth(context) * 0.5,
                          margin: EdgeInsets.only(top: 20),
                          padding: EdgeInsets.only(left: 20, right: 20),
                          decoration: BoxDecoration(
                            color: ColorUtilities.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: TextField(
                            controller: edit_name_controller,
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'New Name'.tr(),
                              hintStyle:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Container(
                          width: Utilities.getDeviceWidth(context) * 0.5,
                          height: Utilities.getDeviceHeight(context) * 0.05,
                          child: ElevatedButton(
                            onPressed: () {},
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
                            width: Utilities.getDeviceWidth(context) * 0.5,
                            height: Utilities.getDeviceHeight(context) * 0.05,
                            child: ElevatedButton(
                              onPressed: () {},
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
                  )),
            )
          ],
        ),
      ),
    );
  }
}
