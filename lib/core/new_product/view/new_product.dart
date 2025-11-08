import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/new_product/view_model/new_product_state.dart';
import 'package:techno_store/core/shared/model/productModel.dart';
import 'package:techno_store/core/utils/color_utilities.dart';
import 'package:file_picker/file_picker.dart';
import 'package:techno_store/core/utils/message.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/core2/widgets/main_app_bar.dart';

import '../../utils/custom_widgets.dart';
import '../../utils/string_utilities.dart';
import '../../utils/widget_utilities.dart';
import '../../shared/model/brand_model.dart';
import '../../shared/model/category_and_sub_category_model.dart';
import '../../shared/view_model/shared_state.dart';

class NewProduct extends StatefulWidget {
  final ProductModel? edit_product;
  final bool editable;

  const NewProduct({Key? key, this.edit_product, required this.editable})
      : super(key: key);

  @override
  State<NewProduct> createState() => _NewProductState();
}

class _NewProductState extends State<NewProduct> {
  late NewProductState newProductState;
  late SharedState sharedState;

  late Future getCategoriesFuture;
  Future? getSubCategoriesFuture;
  late Future getBrandsFuture;
  BrandModel? selectedBrand;
  CategoriesAndSubCategoryModel? selectedCategory;
  CategoriesAndSubCategoryModel? selectedSubCategory;
  List<String> deletedList = [];
  final _formKey = GlobalKey<FormState>();
  List<String> photoPaths = [];
  final en_title_controller = TextEditingController();
  final ar_title_controller = TextEditingController();
  final description_controller = TextEditingController();
  final price_controller = TextEditingController();
  String? category_dropdown_value;
  String? sub_category_dropdown_value;
  String? brand_dropdown_value;
  final _advancedDrawerController = AdvancedDrawerController();

  @override
  void initState() {
    newProductState = context.read<NewProductState>();
    sharedState = context.read<SharedState>();
    getCategoriesFuture = sharedState.getCategories();
    getBrandsFuture = sharedState.getBrands();
    if (widget.editable) {
      en_title_controller.text = widget.edit_product!.enName!;
      ar_title_controller.text = widget.edit_product!.arName!;
      description_controller.text = widget.edit_product!.description!;
      price_controller.text = widget.edit_product!.price!.toString();
      photoPaths = widget.edit_product!.photo!;
    }
    super.initState();
  }

  @override
  void dispose() {
    en_title_controller.dispose();
    ar_title_controller.dispose();
    description_controller.dispose();
    price_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    feedbackMessage(bool value, String msg) {
      if (value) {
        Message.showLongToastMessage(msg.tr());
        Navigator.pop(context);
      }
    }

    newProductState = context.watch<NewProductState>();
    sharedState = context.watch<SharedState>();
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(width <= 500 ? height * 0.05 : height * 0.08),
        child: MainAppBar(
          haveLeading: false,
          advancedDrawerController: _advancedDrawerController,
          title: 'New Product'.tr(),
          onLanguageChanged: () => setState(() {}),
        ),
      ),
      extendBodyBehindAppBar: false,
      body: ModalProgressHUD(
        inAsyncCall: newProductState.loading || sharedState.loading,
        child: SingleChildScrollView(
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  SingleChildScrollView(
                      child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            // color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: photoPaths.isNotEmpty
                              ? SizedBox(
                                  height: height * 0.5,
                                  width: width * 0.8,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: List.generate(
                                      photoPaths.length,
                                      (i) => Container(
                                          child: Container(
                                              margin: const EdgeInsets.all(10),
                                              child: Stack(
                                                children: [
                                                  photoPaths[i].contains(
                                                          "https://firebasestorage.googleapis.com/v0/b/technostore")
                                                      ? Image.network(
                                                          photoPaths[i],
                                                          fit: BoxFit.fill,
                                                        )
                                                      : Image.file(
                                                          File(photoPaths[i]),
                                                          fit: BoxFit.fill,
                                                        ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      InkWell(
                                                        child: const Icon(
                                                          Icons.cancel,
                                                          color: Colors.red,
                                                          size: 30,
                                                        ),
                                                        onTap: () {
                                                          if (photoPaths[i]
                                                              .contains(
                                                                  "https://firebasestorage.googleapis.com/v0/b/technostore")) {
                                                            deletedList.add(
                                                                photoPaths[i]);
                                                          }
                                                          photoPaths.remove(
                                                              photoPaths[i]);
                                                          setState(() {});
                                                        },
                                                      )
                                                    ],
                                                  ),
                                                ],
                                              ))),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: Image.asset(
                                      "assets/images/defaultProductImage.png"),
                                ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        SizedBox(
                          width: width * 0.4,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(50)),
                                  child: const Center(
                                    child: Icon(
                                      Icons.add,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                onTap: () async {
                                  final result = await FilePicker.platform
                                      .pickFiles(
                                          allowMultiple: true,
                                          type: FileType.image);
                                  if (result != null) {
                                    for (var file in result.files) {
                                      photoPaths.add(file.path!);
                                    }
                                    setState(() {});
                                  }
                                },
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              InkWell(
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(50)),
                                  child: const Center(
                                    child: Icon(
                                      Icons.delete,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  setState(() {
                                    photoPaths = [];
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        TextFormField(
                          controller: en_title_controller,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'English Title'.tr(),
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 16),
                          ),
                          validator: (value) {
                            if ((value == null || value.isEmpty) &&
                                ar_title_controller.text.isEmpty) {
                              return "Please Enter".tr() +
                                  " " +
                                  "English Title".tr() +
                                  " " +
                                  "or".tr() +
                                  " " +
                                  "Arabic Title".tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        TextFormField(
                          controller: ar_title_controller,
                          style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Arabic Title'.tr(),
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 16),
                          ),
                          validator: (value) {
                            if ((value == null || value.isEmpty) &&
                                en_title_controller.text.isEmpty) {
                              return "Please Enter".tr() +
                                  " " +
                                  "English Title".tr() +
                                  " " +
                                  "or".tr() +
                                  " " +
                                  "Arabic Title".tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        TextFormField(
                          controller: description_controller,
                          style: const TextStyle(color: Colors.black),
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Description'.tr(),
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontSize: 16),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please Enter".tr() +
                                  " " +
                                  "Description".tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              width: width * 0.35,
                              height: height * 0.15,
                              padding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              decoration: BoxDecoration(
                                color: ColorUtilities.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: FutureBuilder(
                                  future: getCategoriesFuture,
                                  builder: (context, AsyncSnapshot snapshot) {
                                    if (snapshot.hasData) {
                                      List<CategoriesAndSubCategoryModel>
                                          futureCategories = snapshot.data;
                                      if (widget.editable &&
                                          selectedCategory == null) {
                                        for (int i = 0;
                                            i < futureCategories.length;
                                            i++) {
                                          if (futureCategories[i].id ==
                                              widget
                                                  .edit_product!.CategoryID!) {
                                            selectedCategory =
                                                futureCategories[i];
                                            getSubCategoriesFuture =
                                                sharedState.getSubCategories(
                                                    selectedCategory!.id!);
                                          }
                                        }
                                      }
                                      return FormValidatorDropdown<
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
                                      );
                                    }
                                    return const SizedBox();
                                  }),
                            ),
                            Container(
                              width: width * 0.35,
                              height: height * 0.15,
                              padding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              decoration: BoxDecoration(
                                color: ColorUtilities.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: getSubCategoriesFuture != null
                                  ? FutureBuilder(
                                      future: getSubCategoriesFuture,
                                      builder:
                                          (context, AsyncSnapshot snapshot) {
                                        if (snapshot.hasData) {
                                          List<CategoriesAndSubCategoryModel>
                                              futureSubCategories =
                                              snapshot.data;
                                          if (widget.editable &&
                                              selectedSubCategory == null) {
                                            for (int i = 0;
                                                i < futureSubCategories.length;
                                                i++) {
                                              if (futureSubCategories[i].id ==
                                                  widget.edit_product!
                                                      .subCategoryID) {
                                                selectedSubCategory =
                                                    futureSubCategories[i];
                                              }
                                            }
                                          }
                                          return FormValidatorDropdown<
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
                                            label: "Sub-Categories".tr(),
                                          );
                                        }
                                        return const SizedBox();
                                      })
                                  : Center(
                                      child: Text(
                                      "Select category first".tr(),
                                      style:
                                          const TextStyle(color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    )),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              width: width * 0.35,
                              height: height * 0.15,
                              padding:
                                  const EdgeInsets.only(left: 20, right: 20),
                              decoration: BoxDecoration(
                                color: ColorUtilities.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: TextFormField(
                                keyboardType: TextInputType.number,
                                controller: price_controller,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Price'.tr(),
                                  hintStyle: const TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please Enter".tr() +
                                        " " +
                                        "Price".tr();
                                  }
                                  if (num.tryParse(value) == null) {
                                    return "Not Valid Price".tr();
                                  }
                                  return null;
                                },
                              ),
                            ),
                            Container(
                              width: width * 0.35,
                              height: height * 0.15,
                              padding:
                                  const EdgeInsets.only(left: 20, right: 20),
                              decoration: BoxDecoration(
                                color: ColorUtilities.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: FutureBuilder(
                                  future: getBrandsFuture,
                                  builder: (context, AsyncSnapshot snapshot) {
                                    if (snapshot.hasData) {
                                      List<BrandModel> futureBrands =
                                          snapshot.data;
                                      if (widget.editable &&
                                          selectedBrand == null) {
                                        for (int i = 0;
                                            i < futureBrands.length;
                                            i++) {
                                          if (futureBrands[i].name ==
                                              widget.edit_product!.brandID) {
                                            selectedBrand = futureBrands[i];
                                          }
                                        }
                                      }
                                      return FormValidatorDropdown<BrandModel>(
                                        name: "BrandName",
                                        dropDownValue: selectedBrand,
                                        onChanged: (newValue) {
                                          setState(() {
                                            selectedBrand = newValue;
                                          });
                                        },
                                        items: List.generate(
                                            futureBrands.length,
                                            (index) =>
                                                DropdownMenuItem<BrandModel>(
                                                  value: futureBrands[index],
                                                  child: Text(
                                                      futureBrands[index]
                                                          .name!),
                                                )),
                                        label: "Device Brand".tr(),
                                      );
                                    }
                                    return const SizedBox();
                                  }),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  if (widget.editable) {
                                    widget.edit_product!.enName =
                                        en_title_controller.text;
                                    widget.edit_product!.arName =
                                        ar_title_controller.text;
                                    widget.edit_product!.price =
                                        double.parse(price_controller.text);
                                    widget.edit_product!.description =
                                        description_controller.text;
                                    widget.edit_product!.brandID =
                                        selectedBrand!.name;
                                    widget.edit_product!.subCategoryID =
                                        selectedSubCategory!.id;
                                    newProductState
                                        .editProduct(
                                            widget.edit_product!, deletedList)
                                        .then((value) => feedbackMessage(
                                            value, "Edited successfully"));
                                  } else {
                                    ProductModel product = ProductModel(
                                        enName: en_title_controller.text,
                                        arName: ar_title_controller.text,
                                        description:
                                            description_controller.text,
                                        CategoryID: selectedCategory?.id,
                                        subCategoryID: selectedSubCategory?.id,
                                        price:
                                            double.parse(price_controller.text),
                                        brandID: selectedBrand?.name,
                                        photo: photoPaths,
                                        favoriteList: []);
                                    newProductState.addProduct(product).then(
                                        (value) => feedbackMessage(
                                            value, "Added successfully"));
                                  }
                                }
                              },
                              child: SizedBox(
                                width: width * 0.2,
                                child: widget.editable
                                    ? WidgetUtilities.autoSizeText(
                                        "Save",
                                        textAlign: TextAlign.center,
                                      )
                                    : WidgetUtilities.autoSizeText(
                                        "Create",
                                        textAlign: TextAlign.center,
                                      ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorUtilities.secondary,
                                textStyle: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: SizedBox(
                                width: width * 0.2,
                                child: WidgetUtilities.autoSizeText(
                                  "Cancel",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(128, 128, 128, 1),
                                textStyle: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
