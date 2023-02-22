import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/favorite_items/view_model/favorite_items_state.dart';
import 'package:techno_store/shared/color_utilities.dart';

import '../../../shared/widget_utilities.dart';
import '../../product_details/view/product_details.dart';
import '../../shared/model/productModel.dart';

class favoraitItems extends StatefulWidget {
  const favoraitItems({Key? key}) : super(key: key);

  @override
  State<favoraitItems> createState() => _favoraitItemsState();
}

int gridNumber = 2;
List<Color> gridIconColor = [Color.fromRGBO(76, 127, 158, 1), Colors.black];

class _favoraitItemsState extends State<favoraitItems> {
  late FavoriteItemsState favoriteItemsState;
  int gridNumber = 2;
  List<Color> gridIconColor = [Color.fromRGBO(76, 127, 158, 1), Colors.black];
  Future<List<ProductModel>>? favoriteDevices;
  @override
  void initState() {
    favoriteItemsState = context.read<FavoriteItemsState>();
    favoriteDevices = favoriteItemsState.getProducts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    favoriteItemsState = context.watch<FavoriteItemsState>();
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    Widget listCard(ProductModel device) {
      String? name = device.enName;
      context.locale == Locale("en")
          ? name = device.enName
          : name = device.arName;
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      WidgetUtilities.autoSizeText(name!,
                          textStyle: TextStyle(color: Colors.black)),
                      SizedBox(
                        width: 30,
                      ),
                      WidgetUtilities.autoSizeText(
                          device.price.toString() + "ILS".tr(),
                          textStyle: TextStyle(color: Colors.black54)),
                    ],
                  ),
                  Container(
                    width: width * 0.5,
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
      String? name = device.enName;
      context.locale == Locale("en")
          ? name = device.enName
          : name = device.arName;
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
              WidgetUtilities.autoSizeText(name!,
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

    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              favoriteItemsState = context.read<FavoriteItemsState>();
              favoriteDevices = favoriteItemsState.getProducts();
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: height * 0.05),
                          child: WidgetUtilities.autoSizeText("Favorite",
                              textStyle: TextStyle(
                                  fontSize: 22,
                                  color: ColorUtilities.textColor)),
                        ),
                      ],
                    ))),
              ),
              Container(
                color: ColorUtilities.secondary,
                child: Container(
                    width: width,
                    height: height * 0.9,
                    decoration: const BoxDecoration(
                      color: ColorUtilities.backgroundContainer,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 30),
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
                          future: favoriteDevices,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                  child: Container(
                                width: 50,
                                height: 50,
                                child: CircularProgressIndicator(),
                              ));
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
                                itemBuilder: (BuildContext context, int index) {
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
        ));
  }
}
