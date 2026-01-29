import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:techno_store/core/new_product/view/new_product.dart';
import 'package:techno_store/core/product_details/view_model/product_details_state.dart';
import 'package:techno_store/core/shared/model/productModel.dart';
import 'package:techno_store/core/utils/color_utilities.dart';
import 'package:techno_store/core2/widgets/message.dart';
import 'package:techno_store/core/utils/utilities.dart';

import '../../utils/widget_utilities.dart';
import '../../shared/view_model/shared_state.dart';

class ProductDetails extends StatefulWidget {
  final ProductModel product;
  ProductDetails({Key? key, required this.product}) : super(key: key);
  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  @override
  late ProductDetailsState productDetailsState;
  late SharedState sharedState;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final CarouselSliderController _carouselcontroller =
      CarouselSliderController();
  int _current = 0;

  bool favourite = false;
  @override
  void initState() {
    sharedState = context.read<SharedState>();
    productDetailsState = context.read<ProductDetailsState>();
    if (widget.product.favoriteList!.contains(sharedState.userId)) {
      favourite = true;
    }
    super.initState();
  }

  Widget build(BuildContext context) {
    productDetailsState = context.watch<ProductDetailsState>();
    sharedState = context.watch<SharedState>();
    favoriteChangeMessage(bool value, String msg) {
      if (value) {
        Message.showShortToastMessage(msg.tr());
        setState(() {});
      }
    }

    void changeFavourite() {
      String msg = "";
      favourite = !favourite;
      if (widget.product.favoriteList!.contains(sharedState.userId)) {
        widget.product.favoriteList?.remove(sharedState.userId);
        msg = "Removed from favorite";
      } else {
        widget.product.favoriteList?.add(sharedState.userId!);
        msg = "Added to favorite";
      }
      productDetailsState
          .updateFavorites(widget.product.id!, widget.product.favoriteList!)
          .then((value) => favoriteChangeMessage(value, msg));
    }

    deleteMessage(bool value) {
      if (value) {
        Message.showLongToastMessage("Deleted".tr());
        Navigator.pop(context);
        Navigator.pop(context);
      }
    }

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Column(
          children: [
            Container(
              color: ColorUtilities.backgroundContainer,
              child: Container(
                  width: width,
                  height: height * 0.1,
                  padding:
                      EdgeInsets.only(left: 0.12 * width, right: 0.12 * width),
                  decoration: const BoxDecoration(
                    color: ColorUtilities.secondary,
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: height * 0.03,
                        ),
                        WidgetUtilities.autoSizeText(
                          "Product Details",
                          textStyle: TextStyle(
                              color: ColorUtilities.textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ])),
            ),
            Container(
              color: ColorUtilities.secondary,
              child: Container(
                  width: width,
                  height: height * 0.9,
                  decoration: const BoxDecoration(
                    color: ColorUtilities.backgroundContainer,
                  ),
                  child: Container(
                      child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          padding:
                              EdgeInsets.only(top: 30, left: 30, right: 30),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              sharedState.userType == 0
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        InkWell(
                                          child: Icon(Icons.edit,
                                              color: ColorUtilities.secondary,
                                              size: 25),
                                          onTap: () {
                                            Utilities.navigatorWithBack(
                                                context,
                                                NewProduct(
                                                  editable: true,
                                                  edit_product: widget.product,
                                                ));
                                          },
                                        ),
                                        SizedBox(
                                          width: width * 0.05,
                                        ),
                                        InkWell(
                                          child: Icon(CupertinoIcons.delete,
                                              color: Colors.red, size: 25),
                                          onTap: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text(
                                                      "Delete warning".tr()),
                                                  content: Text(
                                                      "Are you sure you want to delete this product?"
                                                          .tr()),
                                                  actions: [
                                                    TextButton(
                                                      child: Text(
                                                        "Delete".tr(),
                                                        style: TextStyle(
                                                            color: Colors.red),
                                                      ),
                                                      onPressed: () {
                                                        productDetailsState
                                                            .deleteProduct(
                                                                widget.product)
                                                            .then((value) =>
                                                                deleteMessage(
                                                                    value));
                                                      },
                                                    ),
                                                    TextButton(
                                                      child:
                                                          Text("Cancel".tr()),
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                    )
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    )
                                  : SizedBox(
                                      width: 20,
                                    ),
                              Container(
                                width: width * 0.5,
                                child: Column(
                                  children: [
                                    WidgetUtilities.autoSizeText(
                                      widget.product.enName! +
                                          "\n" +
                                          widget.product.arName!,
                                      maxLine: 4,
                                      minFontSize: 14,
                                      textAlign: TextAlign.center,
                                      textStyle: TextStyle(
                                        color: Color.fromRGBO(76, 127, 158, 1),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              sharedState.userType != 9
                                  ? InkWell(
                                      child: favourite
                                          ? Icon(
                                              CupertinoIcons.heart_fill,
                                              color: Colors.red,
                                              size: 35,
                                            )
                                          : Icon(CupertinoIcons.heart,
                                              color: Color.fromRGBO(
                                                  76, 127, 158, 1),
                                              size: 35),
                                      onTap: () {
                                        changeFavourite();
                                      },
                                    )
                                  : SizedBox(),
                            ],
                          ),
                        ),
                        widget.product.photo!.isNotEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                      height: height * 0.4,
                                      margin:
                                          EdgeInsets.only(top: 30, bottom: 30),
                                      child: CarouselSlider(
                                        carouselController: _carouselcontroller,
                                        options: CarouselOptions(
                                            enlargeCenterPage: true,
                                            height: 400.0,
                                            enableInfiniteScroll: false,
                                            onPageChanged: (index, reason) {
                                              setState(() {
                                                _current = index;
                                              });
                                            }),
                                        items: widget.product.photo?.map((i) {
                                          return Builder(
                                            builder: (BuildContext context) {
                                              return Container(
                                                  child: Container(
                                                      width: width,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: 2,
                                                            color:
                                                                ColorUtilities
                                                                    .secondary),
                                                      ),
                                                      margin: EdgeInsets.only(
                                                          left: 5, right: 5),
                                                      child: GestureDetector(
                                                          child: InkWell(
                                                        child: i.contains(
                                                                "https://firebasestorage.googleapis.com/v0/b/technostore")
                                                            ? Image.network(
                                                                i,
                                                                fit:
                                                                    BoxFit.fill,
                                                                loadingBuilder: (BuildContext
                                                                        context,
                                                                    Widget
                                                                        child,
                                                                    ImageChunkEvent?
                                                                        loadingProgress) {
                                                                  if (loadingProgress ==
                                                                      null)
                                                                    return child;
                                                                  return Center(
                                                                    child:
                                                                        CircularProgressIndicator(
                                                                      value: loadingProgress.expectedTotalBytes !=
                                                                              null
                                                                          ? loadingProgress.cumulativeBytesLoaded /
                                                                              loadingProgress.expectedTotalBytes!
                                                                          : null,
                                                                    ),
                                                                  );
                                                                },
                                                              )
                                                            : Image.file(
                                                                File(i),
                                                                fit:
                                                                    BoxFit.fill,
                                                              ),
                                                        onTap: () {
                                                          showDialog<Image>(
                                                            context: context,
                                                            builder: (BuildContext
                                                                    context) =>
                                                                AlertDialog(
                                                              content:
                                                                  Container(
                                                                width: width,
                                                                height: width,
                                                                child:
                                                                    PhotoView(
                                                                  backgroundDecoration:
                                                                      BoxDecoration(
                                                                          color:
                                                                              Colors.transparent),
                                                                  imageProvider:
                                                                      NetworkImage(
                                                                          i),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ))));
                                            },
                                          );
                                        }).toList(),
                                      )),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: widget.product.photo!
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      return GestureDetector(
                                        onTap: () => _carouselcontroller
                                            .animateToPage(entry.key),
                                        child: Container(
                                          width: 12.0,
                                          height: 12.0,
                                          margin: EdgeInsets.symmetric(
                                              vertical: 8.0, horizontal: 4.0),
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: (Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.white
                                                      : Colors.black)
                                                  .withOpacity(
                                                      _current == entry.key
                                                          ? 0.9
                                                          : 0.4)),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  SizedBox(
                                    height: height * 0.05,
                                  )
                                ],
                              )
                            : Container(
                                margin: EdgeInsets.all(40),
                                width: width * 0.4,
                                height: height * 0.2,
                                child: Image.asset(
                                    "assets/images/defaultProductImage.png"),
                              ),
                        WidgetUtilities.autoSizeText(
                            widget.product.price.toString() + "ILS".tr(),
                            textStyle: TextStyle(
                                color: ColorUtilities.secondary, fontSize: 20)),
                        SizedBox(
                          height: 10,
                        ),
                        WidgetUtilities.autoSizeText("vat included".tr(),
                            textStyle: TextStyle(fontSize: 14)),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          margin: EdgeInsets.only(right: 30, left: 30, top: 20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.all(10),
                                    child: WidgetUtilities.autoSizeText(
                                      "Description".tr(),
                                      textStyle: TextStyle(
                                          color: Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                ],
                              ),
                              Divider(
                                thickness: 2,
                              ),
                              Container(
                                width: width * 0.8,
                                height: height * 0.3,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: SingleChildScrollView(
                                    child: Container(
                                        margin: EdgeInsets.all(10),
                                        child: Text(widget.product.description!,
                                            style: TextStyle(
                                                color: Colors.black)))),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))),
            )
          ],
        ),
      ),
    );
  }
}
