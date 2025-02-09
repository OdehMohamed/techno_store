import 'package:carousel_slider/carousel_slider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/product_details/view/product_details.dart';
import 'package:techno_store/core/store/view_model/store_state.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:techno_store/shared/utilities.dart';

import '../../../shared/custom_widgets.dart';
import '../../../shared/string_utilities.dart';
import '../../../shared/widget_utilities.dart';
import '../../shared/model/category_and_sub_category_model.dart';
import '../../shared/model/productModel.dart';
import '../../shared/view_model/shared_state.dart';

class Store extends StatefulWidget {
  final CategoriesAndSubCategoryModel category;
  final String categoryId;
  const Store({Key? key, required this.category, required this.categoryId}) : super(key: key);

  @override
  State<Store> createState() => _StoreState();
}

class _StoreState extends State<Store> {
  int gridNumber = 2;

  List<Color> backgroundColor = [];
  List<Color> textColor = [];
  List<Color> gridIconColor = [Color.fromRGBO(76, 127, 158, 1), Colors.black];
  late SharedState sharedState;
  Future? getSubCategoriesFuture;
  CategoriesAndSubCategoryModel? selectedSubCategory;
  List<CategoriesAndSubCategoryModel> futureSubCategories=[];
  late StoreState storeState;
  Future<List<ProductModel>>? productList;
  final CarouselSliderController _carouselcontroller = CarouselSliderController();
  int _current = 0;
  void changeSubCategory(int index, String subCategoryID) {
    productList = storeState.getProducts(subCategoryID);
    for (int i = 0; i < backgroundColor.length; i++) {
      backgroundColor[i] = Colors.transparent;
      textColor[i] = Colors.black;
    }
    backgroundColor[index] = ColorUtilities.secondary;
    textColor[index] = ColorUtilities.white;
  }

  @override
  void initState() {
    selectedSubCategory = null;
    storeState = context.read<StoreState>();
    sharedState = context.read<SharedState>();
    getSubCategoriesFuture=sharedState.getSubCategories(widget.categoryId);
    super.initState();
  }

  void changeGridLength(int length) {
    gridNumber = length;
    switch (length) {
      case 1:
        {
          gridIconColor = [Colors.black, Color.fromRGBO(76, 127, 158, 1)];
          break;
        }
      case 2:
        {
          gridIconColor = [Color.fromRGBO(76, 127, 158, 1), Colors.black];
          break;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    storeState = context.watch<StoreState>();
    sharedState = context.watch<SharedState>();

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    Widget listCard(ProductModel device) {
      return InkWell(
        child: Container(
          margin: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.all(width * 0.01),
                width: width * 0.3,
                height: height * 0.4,
                child: device.photo!.isNotEmpty
                    ? Image.network(
                        device.photo!.first,
                        fit: BoxFit.fill,
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                      )
                    : Image.asset(
                        "assets/images/defaultProductImage.png",
                      ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: width*0.55,
                    child:
                    WidgetUtilities.autoSizeText(device.enName!,
                        textStyle: TextStyle(color: Colors.black)),
                  ),
                  Container(
                    width: width*0.55,
                    child:
                    WidgetUtilities.autoSizeText(device.arName!,
                        textStyle: TextStyle(color: Colors.black)),
                  ),
                  Container(
                    width: width*0.5,
                    child:
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        WidgetUtilities.autoSizeText(
                            device.price.toString() + "ILS".tr(),
                            textStyle: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                  Container(
                    width: width * 0.55,
                    child: WidgetUtilities.autoSizeText(device.description!,
                        textStyle: TextStyle(color: Colors.black54)),
                  ),
                  Container(
                    width: width*0.3,
                    decoration: BoxDecoration(
                        color: ColorUtilities.secondary,
                        borderRadius: BorderRadius.circular(15)
                    ),
                    padding: EdgeInsets.all(5),
                    child: Center(
                      child: Text("Show".tr(),style: TextStyle(color: Colors.white),),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ProductDetails(
                      product: device,
                    )),
          );
        },
      );
    }

    Widget gridCard(ProductModel device) {
      return InkWell(
        child: Container(
          height: height * 0.3,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: width * 0.25,
                height: height * 0.1,
                child: device.photo!.isNotEmpty
                    ? Image.network(
                        device.photo!.first,
                        fit: BoxFit.fill,
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                      )
                    : Image.asset(
                        "assets/images/defaultProductImage.png",
                      ),
              ),
              WidgetUtilities.autoSizeText(device.enName!,
                  textStyle: TextStyle(color: Colors.black)),
              WidgetUtilities.autoSizeText(device.arName!,
                  textStyle: TextStyle(color: Colors.black)),

              SizedBox(
                height: 5,
              ),
              WidgetUtilities.autoSizeText(device.price.toString() + "ILS".tr(),
                  textStyle: TextStyle(color: Colors.black54)),
              SizedBox(
                height: 5,
              ),
              Container(
                width: width*0.3,
                decoration: BoxDecoration(
                  color: ColorUtilities.secondary,
                  borderRadius: BorderRadius.circular(15)
                ),
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(5),
                child: Center(
                  child: Text("Show".tr(),style: TextStyle(color: Colors.white),),
                ),
              )
            ],
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ProductDetails(
                      product: device,
                    )),
          ).then((value) => () {
                setState(() {});
              });
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: ModalProgressHUD(
          inAsyncCall: sharedState.loading || storeState.loading,
          child: RefreshIndicator(
            onRefresh: () async {
             setState(() {
               getSubCategoriesFuture = sharedState.getSubCategories(widget.categoryId);
             });
            },
            child: Column(
              children: [

                Container(
                  color: ColorUtilities.backgroundContainer,
                  child: Container(
                      width: width,
                      height: height * 0.1,
                      decoration: const BoxDecoration(
                        color: ColorUtilities.secondary,
                      ),
                      child: Center(
                          child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.only(top: height*0.03),
                                child: Utilities.isEnglish(context)?
                                Text(widget.category.enName!,style: TextStyle(color: Colors.white,fontSize: 22),):
                                Text(widget.category.arName!,style: TextStyle(color: Colors.white,fontSize: 22)),
                              ),
                            ],
                          ),
                        ],
                      ))),
                ),
                Container(
                  color: Color.fromRGBO(76, 127, 158, 1),
                  child: Container(
                      width: width,
                      height: height * 0.9,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(239, 239, 239, 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            height: height*0.1,
                            width: width,
                            margin: EdgeInsets.only(top: 30),
                            child:  getSubCategoriesFuture != null
                                ? FutureBuilder(
                                future: getSubCategoriesFuture,
                                builder:
                                    (context, AsyncSnapshot snapshot) {
                                  if (snapshot.hasData) {
                                    futureSubCategories =
                                        snapshot.data;
                                    if (futureSubCategories.isEmpty){
                                      productList = storeState
                                          .getProducts("hi");
                                      getSubCategoriesFuture=null;
                                      return SizedBox();
                                    }
                                    else if (selectedSubCategory == null) {
                                      productList = storeState
                                          .getProducts(futureSubCategories
                                          .first.id!);
                                      selectedSubCategory =
                                          futureSubCategories.first;
                                      backgroundColor = [];
                                      textColor = [];
                                      for (int i = 0;
                                      i < futureSubCategories.length;
                                      i++) {
                                        backgroundColor.add(
                                          Colors.transparent,
                                        );
                                        textColor.add(Colors.black);
                                      }
                                      backgroundColor[0] = ColorUtilities
                                          .secondary;
                                      textColor[0] =
                                          ColorUtilities.white;
                                    }
                                    if (backgroundColor.length !=
                                        futureSubCategories.length ||
                                        textColor.length !=
                                            futureSubCategories.length) {
                                      backgroundColor = [];
                                      textColor = [];
                                      for (int i = 0;
                                      i < futureSubCategories.length;
                                      i++) {
                                        backgroundColor.add(
                                          Colors.transparent,
                                        );
                                        textColor.add(Colors.black);
                                      }
                                      backgroundColor[0] = ColorUtilities
                                          .secondary;
                                      textColor[0] =
                                          ColorUtilities.white;
                                    }
                                    return
                                      CarouselSlider(
                                          carouselController: _carouselcontroller,
                                          options: CarouselOptions(
                                            initialPage: _current,
                                            padEnds: false,
                                            viewportFraction: 0.3,
                                              enableInfiniteScroll: false,
                                              disableCenter: true,
                                              onPageChanged: (index, reason) {
                                                setState(() {
                                                  _current = index;
                                                });}
                                          ),
                                        items: futureSubCategories.map((subCat){
                                          int i=futureSubCategories.indexOf(subCat);
                                          return Builder(
                                            builder: (BuildContext context) {
                                              return Column(
                                                children: [
                                                  InkWell(
                                                    child: Container(
                                                      width: width*0.8,
                                                      height: height*0.07,
                                                      margin: EdgeInsets.only(right: 5,left: 5),
                                                      padding: EdgeInsets.only(
                                                          top: 10, bottom: 10, left: width*0.04, right: width*0.04),
                                                      decoration: BoxDecoration(
                                                          border: Border.all(width: 1,color: ColorUtilities.secondary),
                                                          color: backgroundColor[
                                                          i],
                                                          borderRadius:
                                                          BorderRadius
                                                              .circular(5)),
                                                      child: Center(child: WidgetUtilities.autoSizeText(
                                                        StringUtilities
                                                            .getStringByLanguage(
                                                            context,
                                                            futureSubCategories[
                                                            i]
                                                                .arName,
                                                            futureSubCategories[
                                                            i]
                                                                .enName),
                                                        textAlign: TextAlign.center,
                                                        textStyle: TextStyle(
                                                            color:
                                                            textColor[i]),
                                                      minFontSize: 8, maxLine: 2
                                                      ),)
                                                    ),
                                                    onTap: () {
                                                      _current=i;
                                                      changeSubCategory(
                                                          i,
                                                          futureSubCategories[
                                                          i]
                                                              .id!);
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }).toList(),
                                      );
                                  }
                                  return SizedBox();
                                })
                                : SizedBox(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: futureSubCategories.asMap().entries.map((entry) {
                              return GestureDetector(
                                onTap: () => _carouselcontroller.animateToPage(entry.key),
                                child: Container(
                                  width: 14.0,
                                  height: 7.0,
                                  margin: EdgeInsets.symmetric(vertical: 0, horizontal: 4.0),
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: (Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : Colors.black)
                                          .withOpacity(_current == entry.key ? 0.9 : 0.4)),
                                ),
                              );
                            }).toList(),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 10),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                    child: Container(
                                      margin: EdgeInsets.all(15),
                                      child: Center(
                                        child: Icon(
                                          Icons.grid_view_rounded,
                                          color: gridIconColor[0],
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      changeGridLength(2);
                                      setState(() {});
                                    },
                                  ),
                                  InkWell(
                                    child: Container(
                                      margin: EdgeInsets.all(15),
                                      child: Center(
                                        child: Icon(
                                          Icons.format_list_bulleted,
                                          color: gridIconColor[1],
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      changeGridLength(1);
                                      setState(() {});
                                    },
                                  )
                                ]),
                          ),
                          Expanded(
                              child: FutureBuilder<List<ProductModel>>(
                            future: productList,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.waiting ||
                                  snapshot.data == null) {
                                return SizedBox();
                              } else if (snapshot.hasData) {
                                List<ProductModel> devices =
                                    snapshot.data as List<ProductModel>;
                                if (devices.isEmpty) {
                                  return Center(
                                    child: Text("No Data".tr()),
                                  );
                                }
                                return GridView.builder(
                                  padding: EdgeInsets.all(10),
                                  itemCount: devices.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                          childAspectRatio: gridNumber == 2
                                              ? (1 / 1.2)
                                              : (1 / 0.5),
                                          crossAxisCount: gridNumber,
                                          crossAxisSpacing: 1.0,
                                          mainAxisSpacing: 5),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    if (gridNumber == 1) {
                                      return listCard(devices[index]);
                                    }
                                    return gridCard(devices[index]);
                                  },
                                );
                              } else if (snapshot.data!.isEmpty) {
                                return Center(
                                  child: Text("No Data".tr()),
                                );
                              } else {
                                return Center(
                                  child: Text("Error".tr()),
                                );
                              }
                            },
                          ))
                        ],
                      )),
                )
              ],
            ),
          )),
    );
  }
}
