import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/product_details/view/product_details.dart';
import 'package:techno_store/core/store/view_model/store_state.dart';
import 'package:techno_store/shared/color_utilities.dart';

import '../../../shared/widget_utilities.dart';
import '../../shared/model/productModel.dart';

class Store extends StatefulWidget {
  const Store({Key? key}) : super(key: key);

  @override
  State<Store> createState() => _StoreState();
}

var categories = [
  'Devices',
  'Accessories',
  'Covers',
  'Screen protectors',
];
var sub_categories = [
  'Item 1',
  'Item 2',
  'Item 3',
  'Item 4',
  'Item 5',
];
String category_dropdown_value = 'Devices';
String? sub_category_dropdown_value;
int gridNumber=2;

List<Color> backgroundColor = [
  Colors.white,
  Colors.transparent,
  Colors.transparent
];
List<Color> textColor = [
  ColorUtilities.secondary,
  ColorUtilities.white,
  ColorUtilities.white,
];
List <Color> gridIconColor = [
  Color.fromRGBO(76, 127, 158, 1),
  Colors.black
];

void changeStatus(int status) {
  switch (status) {
    case 0:
      {
        backgroundColor = [
          ColorUtilities.white,
          Colors.transparent,
          Colors.transparent
        ];
        textColor = [
          ColorUtilities.secondary,
          ColorUtilities.white,
          ColorUtilities.white,
        ];
        break;
      }
    case 1:
      {
        backgroundColor = [
          Colors.transparent,
          ColorUtilities.white,
          Colors.transparent
        ];
        textColor = [
          ColorUtilities.white,
          ColorUtilities.secondary,
          ColorUtilities.white,
        ];
        break;
      }
    case 2:
      {
        backgroundColor = [
          Colors.transparent,
          Colors.transparent,
          ColorUtilities.white,
        ];
        textColor = [
          ColorUtilities.white,
          ColorUtilities.white,
          ColorUtilities.secondary
        ];
        break;
      }
    default:
      {
        backgroundColor = [
          Colors.white,
          Colors.transparent,
          Colors.transparent
        ];
        textColor = [
          ColorUtilities.secondary,
          ColorUtilities.white,
          ColorUtilities.white,
        ];
        break;
      }
  }
}

class _StoreState extends State<Store> {
  late StoreState storeState;
  late Future<List<ProductModel>> productList ;
  @override
  void initState() {
    storeState=context.read<StoreState>();
    productList= storeState.getProducts('3N7ICfyqonoRodcOAEEk');
    super.initState();
  }
  void changeGridLength(int length){
    gridNumber =length;
    switch(length){

      case 1: {
        gridIconColor = [Colors.black,Color.fromRGBO(76, 127, 158, 1)];
        break;
      }
      case 2:{
        gridIconColor = [Color.fromRGBO(76, 127, 158, 1),Colors.black];
        break;
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    storeState=context.watch<StoreState>();
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Widget listCard(ProductModel device){
      String? name=device.enName;
      context.locale == Locale("en")?name=device.enName:name=device.arName;
      return InkWell(
        child:  Container(
          margin: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.all(width*0.01),
                width: width*0.3,
                height: height*0.4,
                child: device.photo!.isNotEmpty ?Image.network(device.photo!.first,fit: BoxFit.fill,):
                Image.asset("assets/images/defaultProductImage.png",),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      WidgetUtilities.autoSizeText(name!,textStyle: TextStyle(color: Colors.black)),
                      SizedBox(width: 30,),
                      WidgetUtilities.autoSizeText(device.price.toString()+"JD".tr(),textStyle: TextStyle(color: Colors.black54)),
                    ],
                  ),
                  Container(
                    width: width*0.5,
                    child: WidgetUtilities.autoSizeText(device.description!,textStyle: TextStyle(color: Colors.black54)),
                  )
                ],
              )
            ],
          ),
        ),
        onTap: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetails(product: device,)),);
        },
      );
    }
    Widget gridCard(ProductModel device){
      String? name=device.enName;
      context.locale == Locale("en")?name=device.enName:name=device.arName;
      return InkWell(
        child:  Container(
          height: height*0.25,
          decoration: BoxDecoration(
              color:Colors.white,
              borderRadius: BorderRadius.circular(10)
          ),
          margin: EdgeInsets.all(5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: width*0.25,
                height: height*0.12,
                child: device.photo!.isNotEmpty?Image.network(device.photo!.first,fit: BoxFit.fill,):
                Image.asset("assets/images/defaultProductImage.png",),
              ),
              WidgetUtilities.autoSizeText(name!,textStyle: TextStyle(color: Colors.black)),
              SizedBox(height: 5,),
              WidgetUtilities.autoSizeText(device.price.toString()+"JD".tr(),textStyle: TextStyle(color: Colors.black54)),
              SizedBox(height: 5,),
            ],
          ),
        ),
        onTap: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetails(product: device,)),);
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
      body: Column(
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
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: height * 0.1),
                      child: WidgetUtilities.autoSizeText(
                        "Store",
                        textStyle: TextStyle(fontSize: 22,color: ColorUtilities.textColor)
                      ),
                    ),
                    Flexible(child: Container()),
                    Row(children: [
                      Container(
                        width: width*0.35,
                        padding: EdgeInsets.only(right: 30,left: 30),
                        child:DropdownButton(
                          dropdownColor: Color.fromRGBO(76, 127, 158, 0.9),
                          isExpanded: true,
                          underline: SizedBox(),
                          value: category_dropdown_value,
                          icon: const Icon(Icons.keyboard_arrow_down,color: Colors.white,),
                          items: categories.map((String items) {
                            return DropdownMenuItem(
                              value: items,
                              child: WidgetUtilities.autoSizeText(items,textStyle: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 18),),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              category_dropdown_value = newValue!;
                            });
                          },
                        ),
                      ),
                      Container(
                        width: width * 0.65,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              InkWell(
                                child: Container(
                                  padding: EdgeInsets.only(
                                      top: 5, bottom: 5, left: 10, right: 10),
                                  decoration: BoxDecoration(
                                      color: backgroundColor[0],
                                      borderRadius: BorderRadius.circular(15)),
                                  child: Text(
                                    "Phones",
                                    style: TextStyle(
                                        color: textColor[0], fontSize: 14),
                                  ),
                                ),
                                onTap: () {
                                  changeStatus(0);
                                  setState(() {});
                                },
                              ),
                              InkWell(
                                child: Container(
                                  padding: EdgeInsets.only(
                                      top: 5, bottom: 5, left: 10, right: 10),
                                  decoration: BoxDecoration(
                                      color: backgroundColor[1],
                                      borderRadius: BorderRadius.circular(25)),
                                  child: Text(
                                    "Laptops",
                                    style: TextStyle(
                                        color: textColor[1], fontSize: 14),
                                  ),
                                ),
                                onTap: () {
                                  changeStatus(1);
                                  setState(() {});
                                },
                              ),
                              InkWell(
                                child: Container(
                                  padding: EdgeInsets.only(
                                      top: 5, bottom: 5, left: 10, right: 10),
                                  decoration: BoxDecoration(
                                      color: backgroundColor[2],
                                      borderRadius: BorderRadius.circular(25)),
                                  child: Text(
                                    "Tablets",
                                    style: TextStyle(
                                        color: textColor[2], fontSize: 14),
                                  ),
                                ),
                                onTap: () {
                                  changeStatus(2);
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    ])
                  ],
                ))),
          ),
          Container(
            color:Color.fromRGBO(76, 127, 158, 1),
            child: Container (
                width: width,
                height: height*0.75,
                decoration: const BoxDecoration(
                  color:   Color.fromRGBO(239, 239, 239, 1),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                  ),
                ),
                child:Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 30),
                      child:    Row(mainAxisAlignment: MainAxisAlignment.center,children: [
                        InkWell(
                          child: Container(
                            margin: EdgeInsets.all(15),
                            child: Center(child:
                            Icon(Icons.grid_view_rounded,color: gridIconColor[0],size: 30,),),
                          ),
                          onTap: (){
                            changeGridLength(2);
                            setState(() {});
                          },
                        ),
                        InkWell(
                          child: Container(
                            margin: EdgeInsets.all(15),
                            child: Center(child:
                            Icon(Icons.format_list_bulleted,color: gridIconColor[1],size: 30,),),
                          ),
                          onTap: (){
                            changeGridLength(1);
                            setState(() {});
                          },
                        )
                      ]
                      ),
                    ),
                    Expanded(
                      child:
                      FutureBuilder<List<ProductModel>>(
                        future: productList,
                        builder: (context,snapshot){
                          if (snapshot.connectionState==ConnectionState.waiting){
                            return Center (child :Container(width: 50,height: 50,child: CircularProgressIndicator(),));
                          }
                          else if(snapshot.hasData){
                            List<ProductModel> devices= snapshot.data as List<ProductModel>;
                            return 
                              GridView.builder(
                              padding: EdgeInsets.all(10),
                              itemCount: devices.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  childAspectRatio: gridNumber==2?(1 / 1):(1/0.5),
                                  crossAxisCount: gridNumber,
                                  crossAxisSpacing: 1.0,
                                  mainAxisSpacing: 5
                              ), itemBuilder: (BuildContext context, int index) {
                              if (gridNumber==1){
                                return listCard(devices[index]);
                              }
                              return gridCard(devices[index]);
                            },
                            );
                          }
                          else  if (snapshot.data!.isEmpty){
                            return Center(child: Text("No Data".tr()),);
                          }
                          else {
                            return Center(child: Text("Error".tr()),);
                          }
                        },
                      )
                    )
                  ],
                )
            ),
          )
        ],
      ),
    );
  }
}
