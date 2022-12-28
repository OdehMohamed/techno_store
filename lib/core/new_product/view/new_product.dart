import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/new_product/view_model/new_product_state.dart';
import 'package:techno_store/core/product_details/view/product_details.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:file_picker/file_picker.dart';

import '../../../shared/custom_widgets.dart';
import '../../../shared/string_utilities.dart';
import '../../../shared/widget_utilities.dart';
import '../../shared/model/brand_model.dart';
import '../../shared/model/category_and_sub_category_model.dart';
import '../../shared/view_model/shared_state.dart';

class NewProduct extends StatefulWidget {
  const NewProduct({Key? key}) : super(key: key);

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

  final _formKey = GlobalKey<FormState>();
  List<String> photoPaths=[];
  final en_title_controller = TextEditingController();
  final ar_title_controller = TextEditingController();
  final description_controller = TextEditingController();
  final price_controller = TextEditingController();

  var categories = [
    'Item 1',
    'Item 2',
    'Item 3',
    'Item 4',
    'Item 5',
  ];
  var brands = [
    "brand1",
    "brand2"
  ];
  var sub_categories = [
    'Item 1',
    'Item 2',
    'Item 3',
    'Item 4',
    'Item 5',
  ];
  String? category_dropdown_value;
  String? sub_category_dropdown_value;
  String? brand_dropdown_value;
  @override
  void initState() {
    newProductState= context.read<NewProductState>();
    sharedState = context.read<SharedState>();
    getCategoriesFuture = sharedState.getCategories();
    getBrandsFuture = sharedState.getBrands();


    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    newProductState= context.watch<NewProductState>();
    sharedState= context.watch<SharedState>();

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body:SingleChildScrollView(
        child:  Column(
          children: [
            Container(
              color: ColorUtilities.backgroundContainer,
              child: Container(
                  width: width,
                  height: height * 0.25,
                  decoration: const BoxDecoration(
                    color: ColorUtilities.secondary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                    ),
                  ),
                  child: Center(
                    child: WidgetUtilities.autoSizeText(
                        "New Product".tr(),
                        textStyle: TextStyle(color: ColorUtilities.textColor,fontSize: 20)
                    ),
                  )),
            ),
            Container(
              color: ColorUtilities.secondary,
              child: Container(
                  width: width,
                  height: height * 0.75,
                  decoration: const BoxDecoration(
                    color: ColorUtilities.backgroundContainer,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: Container(
                      margin: EdgeInsets.only(right: 40, left: 40,bottom: 15,top: 15),
                      child: SingleChildScrollView(
                          child:Form(
                            key: _formKey,
                            child:  Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(
                                    decoration: BoxDecoration(
                                      color:ColorUtilities.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color:Color.fromRGBO(0, 0, 0, 0.4),
                                          blurRadius: 20,
                                          offset: Offset(0, 15),
                                        ),
                                      ],
                                    ),
                                    height: height*0.4,
                                    child:photoPaths.isNotEmpty? ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: List.generate(
                                        photoPaths.length,
                                            (i) => Container(
                                            width: width*0.4,
                                            alignment: Alignment.center,
                                            child:Container(margin: EdgeInsets.all(10),
                                                child:Stack(
                                                  children: [
                                                    Image.file(
                                                      File(photoPaths[i]),
                                                      fit: BoxFit.fill,
                                                    ),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        InkWell(
                                                          child: Icon(Icons.cancel,color: Colors.red,size: 30,),
                                                          onTap: (){
                                                            photoPaths.remove(photoPaths[i]);
                                                            setState(() {});
                                                          },
                                                        )
                                                      ],
                                                    ),
                                                  ],
                                                )
                                            )
                                        ),
                                      ),
                                    )
                                        :Image.asset("assets/images/defaultProductImage.png")
                                ),
                                SizedBox(height: 15,),
                                Container(
                                  width: width*0.4,
                                  child:
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      InkWell(
                                        child:
                                        Container(
                                          padding: EdgeInsets.all(15),
                                          decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(50)
                                          ),
                                          child:  Center(child:Icon(Icons.add,size: 20,),),
                                        ),
                                        onTap: () async {
                                          final result = await FilePicker
                                              .platform
                                              .pickFiles(
                                              allowMultiple: true,
                                              type: FileType.image
                                          );
                                          if (result != null) {
                                            result.files.forEach((file) {
                                              photoPaths.add(file.path!);
                                            });
                                            setState(() {});
                                          }
                                        },
                                      ),
                                      SizedBox(width: 10,),
                                      InkWell(
                                        child:
                                        Container(
                                          padding: EdgeInsets.all(15),
                                          decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(50)
                                          ),
                                          child:  Center(child:Icon(Icons.delete,size: 20,),),
                                        ),
                                        onTap: ()  {
                                          setState(() {
                                            photoPaths=[];
                                          });
                                        },
                                      ),
                                    ],),
                                ),
                                SizedBox(height: 15,),
                                Container(
                                  padding: EdgeInsets.only(left: 20,right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child : TextFormField(
                                    controller: en_title_controller,
                                    style: TextStyle(color: Colors.black),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'English Title'.tr(),
                                      hintStyle:
                                      TextStyle(color:Colors.grey, fontSize: 16),),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please Enter".tr()+" "+"English Title".tr();
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(height: 15,),
                                Container(
                                  padding: EdgeInsets.only(left: 20,right: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child :TextFormField(
                                    controller: ar_title_controller,
                                    style: TextStyle(color: Colors.black),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Arabic Title'.tr(),
                                      hintStyle:
                                      TextStyle(color:Colors.grey, fontSize: 16),),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please Enter".tr()+" "+"Arabic Title".tr();
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(height: 15,),
                                Container(
                                  height: 100,
                                  padding: EdgeInsets.only(left: 10,right: 10),
                                  decoration: BoxDecoration(
                                    color: ColorUtilities.white,
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: TextFormField(
                                    controller: description_controller,
                                    style: TextStyle(color: Colors.black),
                                    keyboardType: TextInputType.multiline,
                                    maxLines: null,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Description'.tr(),
                                      hintStyle:
                                      TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please Enter".tr()+" "+"Description".tr();
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(height: 15,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: width*0.35,
                                      height: height*0.1,
                                      padding: EdgeInsets.only(left: 10,right: 10),
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
                                             return SizedBox();
                                           }),
                                      // DropdownButtonFormField(
                                      //   isExpanded: true,
                                      //   hint: WidgetUtilities.autoSizeText("Category",textStyle: TextStyle(color: Colors.black)),
                                      //   value: category_dropdown_value,
                                      //   icon: const Icon(Icons.keyboard_arrow_down),
                                      //   items: categories.map((String items) {
                                      //     return DropdownMenuItem(
                                      //       value: items,
                                      //       child: WidgetUtilities.autoSizeText(items ,textStyle: TextStyle(color: Colors.black)),
                                      //     );
                                      //   }).toList(),
                                      //   onChanged: (String? newValue) {
                                      //     setState(() {
                                      //       category_dropdown_value = newValue!;
                                      //     });
                                      //   },
                                      //   validator: (value) {
                                      //     if (value == null ) {
                                      //       return "Please Enter".tr()+" "+"Category".tr();
                                      //     }
                                      //     return null;
                                      //   },
                                      // ),
                                    ),
                                    Container(
                                      width: width*0.35,
                                      height: height*0.1,
                                      padding: EdgeInsets.only(left: 10,right: 10),
                                      decoration: BoxDecoration(
                                        color: ColorUtilities.white,
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child:
                                      getSubCategoriesFuture != null
                                          ? FutureBuilder(
                                          future: getSubCategoriesFuture,
                                          builder: (context, AsyncSnapshot snapshot) {
                                            if (snapshot.hasData) {
                                              List<CategoriesAndSubCategoryModel>
                                              futureSubCategories = snapshot.data;
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
                                            return SizedBox();
                                          })
                                          : Center (child :Text("Select category first".tr(),style: TextStyle(color: Colors.grey),textAlign: TextAlign.center,)),
                                      // DropdownButtonFormField(
                                      //   isExpanded: true,
                                      //   hint: WidgetUtilities.autoSizeText("Sub-Categories",textStyle: TextStyle(color: Colors.black)),
                                      //   value: sub_category_dropdown_value,
                                      //   icon: const Icon(Icons.keyboard_arrow_down),
                                      //   items: sub_categories.map((String items) {
                                      //     return DropdownMenuItem(
                                      //       value: items,
                                      //       child: WidgetUtilities.autoSizeText(items,textStyle: TextStyle(color: Colors.black)),
                                      //     );
                                      //   }).toList(),
                                      //   onChanged: (String? newValue) {
                                      //     setState(() {
                                      //       sub_category_dropdown_value = newValue!;
                                      //     });
                                      //   },
                                      //   validator: (value) {
                                      //     if (value == null ) {
                                      //       return "Please Enter".tr()+" "+"Sub-Categories".tr();
                                      //     }
                                      //     return null;
                                      //   },
                                      // ),
                                    ),
                                  ],),
                                SizedBox(height: 15,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: width*0.35,
                                      height: height*0.1,

                                      padding: EdgeInsets.only(left: 20,right: 20),
                                      decoration: BoxDecoration(
                                        color: ColorUtilities.white,
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child :TextFormField(
                                        keyboardType: TextInputType.number,
                                        controller: price_controller,
                                        style: TextStyle(color: Colors.black),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'Price'.tr(),
                                          hintStyle:
                                          TextStyle(color:Colors.grey, fontSize: 16),),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return "Please Enter".tr()+" "+"Price".tr();
                                          }
                                          if (num.tryParse(value) == null) {
                                            return "Not Valid Price".tr();
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    Container(
                                      width: width*0.35,
                                      height: height*0.1,

                                      padding: EdgeInsets.only(left: 10,right: 10),
                                      decoration: BoxDecoration(
                                        color: ColorUtilities.white,
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child:
                                      FutureBuilder(
                                          future: getBrandsFuture,
                                          builder: (context, AsyncSnapshot snapshot) {
                                            if (snapshot.hasData) {
                                              List<BrandModel>
                                              futureBrands = snapshot.data;
                                              return FormValidatorDropdown<
                                                  BrandModel>(
                                                name: "BrandName",
                                                dropDownValue: selectedBrand,
                                                onChanged: (newValue) {
                                                  selectedBrand = newValue;
                                                  setState(() {});
                                                },
                                                items: List.generate(
                                                    futureBrands.length,
                                                        (index) => DropdownMenuItem<
                                                        BrandModel>(
                                                      value:
                                                      futureBrands[index],
                                                      child: Text(futureBrands[index].name!),
                                                    )),
                                                label: "Device Brand".tr(),
                                              );
                                            }
                                            return SizedBox();
                                          }),
                                      // DropdownButtonFormField(
                                      //   isExpanded: true,
                                      //   hint: WidgetUtilities.autoSizeText("Device Brand",textStyle: TextStyle(color: Colors.black)),
                                      //   value: brand_dropdown_value,
                                      //   icon: const Icon(Icons.keyboard_arrow_down),
                                      //   items: brands.map((String items) {
                                      //     return DropdownMenuItem(
                                      //       value: items,
                                      //       child: WidgetUtilities.autoSizeText(items,textStyle: TextStyle(color: Colors.black)),
                                      //     );
                                      //   }).toList(),
                                      //   onChanged: (String? newValue) {
                                      //     setState(() {
                                      //       brand_dropdown_value = newValue!;
                                      //     });
                                      //   },
                                      //   validator: (value) {
                                      //     if (value == null ) {
                                      //       return "Please Enter".tr()+" "+"Price".tr();
                                      //     }
                                      //     return null;
                                      //   },
                                      // ),
                                    ),

                                  ],
                                ),
                                SizedBox(height: 15,),
                                SizedBox(height: 15,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: (){
                                        if (_formKey.currentState!.validate()) {
                                          // call function
                                        }
                                      },
                                      child: Container(
                                        width: width*0.2,
                                        child: WidgetUtilities.autoSizeText("Create",textAlign: TextAlign.center,),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        primary: ColorUtilities.secondary,
                                        textStyle:
                                        TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: (){
                                        Navigator.pop(context);
                                      },
                                      child: Container(
                                        width: width*0.2,
                                        child: WidgetUtilities.autoSizeText("Cancel",textAlign: TextAlign.center,),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        primary: Color.fromRGBO(128, 128, 128, 1),
                                        textStyle:
                                        TextStyle(fontSize: 16, color: Colors.white),
                                      ),
                                    ),

                                  ],
                                ),
                                SizedBox(height: 10,),
                              ],
                            ),
                          )
                      )
                  )
              ),
            )
          ],
        ),
      ),
    );
  }
}
