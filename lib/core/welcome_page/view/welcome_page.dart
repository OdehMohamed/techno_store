import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:techno_store/core/favorite_items/view/favoriteItems.dart';
import 'package:techno_store/core/maintenance_list/view/maintenance_list.dart';
import 'package:techno_store/core/manage_categories/view/manageCategory.dart';
import 'package:techno_store/core/new_device_maintenance/view/new_device_maintenance.dart';
import 'package:techno_store/core/new_product/view/new_product.dart';
import 'package:techno_store/core/new_user_admin_side/view/new_user_admin_side.dart';
import 'package:techno_store/core/store/view/store.dart';
import 'package:techno_store/core/track_phone_page/view/track_phone_page.dart';
import 'package:techno_store/data_source/firebase.dart';
import 'package:techno_store/shared/color_utilities.dart';

import '../../../shared/utilities.dart';
import '../../../shared/widget_utilities.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Widget card(
      String title,
      Icon icon,
        tap()
    ) {
      return Column(
        children: [
          InkWell(
            onTap: tap,
            child: Container(
              padding: EdgeInsets.only(left: 20),
              height: height * 0.1,
              width: width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      icon,
                      WidgetUtilities.autoSizeText(
                        title,
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
    String lang = context.locale == Locale("en") ? "ar" : "en";
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title:  WidgetUtilities.autoSizeText("Welcome"),
        backgroundColor: Colors.transparent,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10, left: 10),
            child: Center(
              child: InkWell(
                onTap: () {
                  context.locale = context.locale == Locale("en") ? Locale("ar") : Locale("en");
                },
                child: WidgetUtilities.autoSizeText(
                  lang.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      drawer: Container(
        width: 0.8 * width,
        height: height,
        color: ColorUtilities.secondary,
        child: Column(
          children: [
            Container(
                margin: EdgeInsets.only(top: height * 0.07),
                width: 100,
                height: 100,
                child: CircleAvatar(
                  backgroundImage: AssetImage("assets/images/defaultImg.png"),
                  backgroundColor: Colors.white,
                )),
            SizedBox(
              height: 10,
            ),
            WidgetUtilities.autoSizeText(
              "My name ",
            ),
            Flexible(
                child: ListView(
              children: [
                card("Favorite", Icon(Icons.star, color: Colors.yellow),(){Utilities.navigatorWithBack(context, favoraitItems());}),
                card(
                  "Store",
                  Icon(
                    Icons.shopping_cart,
                    color: Colors.white60,
                  ),
                    (){Utilities.navigatorWithBack(context, Store());}
                ),
                card(
                  "Check My Device",
                  Icon(
                    Icons.phone_android,
                    color: Colors.white60,
                  ),
                    (){Utilities.navigatorWithBack(context, TrackPhonePage());}
                ),
                card(
                  "Maintenance",
                  Icon(Icons.add_to_home_screen, color: Colors.white60),
                    (){Utilities.navigatorWithBack(context, MaintinanceList());}
                ),
                card(
                  "Add new Employee",
                  Icon(
                    Icons.person_add,
                    color: Colors.white60,
                  ),
                    (){Utilities.navigatorWithBack(context, NewUserAdminSide());}
                ),
                card("Add new Product", Icon(Icons.note_add,color: Colors.white60,),
                        (){Navigator.push(context, MaterialPageRoute(builder: (context) => NewProduct()),);}
                ),
                card("Manage Categories", Icon(Icons.category,color: Colors.white60,),
                        (){Navigator.push(context, MaterialPageRoute(builder: (context) =>manageCategory()),);}
                ),
              ],
            )),
            InkWell(
                onTap: () {
                  FirebaseDataSource().signOut();
                },
                child: Container(
                    padding: EdgeInsets.all(10),
                    color: Colors.red,
                    width: width,
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.logout,
                          color: Colors.white60,
                        ),
                        WidgetUtilities.autoSizeText(
                          "Logout",
                        ),
                      ],
                    ))),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color:ColorUtilities.backgroundContainer,
            child: Container(
                width: width,
                height: height * 0.4,
                decoration: const BoxDecoration(
                  color: ColorUtilities.secondary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                      width: 150,
                      height: 150,
                      child: Image.asset(
                        "assets/images/logo.png",
                        fit: BoxFit.fill,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )),
          ),
          Container(
            color: ColorUtilities.secondary,
            child: Container(
                width: width,
                height: height * 0.6,
                decoration: const BoxDecoration(
                  color: ColorUtilities.backgroundContainer,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Container(
                  margin: EdgeInsets.only(top: 30, left: 40, right: 40),
                  child: Column(
                    children: [
                      SizedBox(
                        height: height * 0.05,
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Store()),
                          );
                        },
                        child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: ColorUtilities.secondary,
                            ),
                            width: 200,
                            height: 90,
                            child: Center(
                              child: WidgetUtilities.autoSizeText(
                                "Store",
                                textStyle: TextStyle(fontSize: 22,color: ColorUtilities.textColor),
                              ),
                            )),
                      ),
                      SizedBox(
                        height: height * 0.05,
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MaintinanceList()),
                          );
                        },
                        child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: ColorUtilities.secondary,
                            ),
                            width: 200,
                            height: 90,
                            child: Center(
                              child: WidgetUtilities.autoSizeText(
                                "Maintenance",
                                textStyle: TextStyle(
                                    color: ColorUtilities.textColor, fontSize: 22),
                              ),
                            )),
                      ),
                      Flexible(child: Container()),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            child: Icon(
                              FontAwesome5.whatsapp,
                              color: Colors.green,
                              size: 30,
                            ),
                          ),
                          SizedBox(width: 15),
                          InkWell(
                            child: Icon(
                              FontAwesome5.facebook,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                          SizedBox(width: 15),
                          InkWell(
                            child: Icon(
                              FontAwesome5.instagram,
                              color: Colors.pink,
                              size: 30,
                            ),
                          ),
                          SizedBox(width: 15),
                          InkWell(
                            child: Icon(
                              FontAwesome5.snapchat,
                              color: Colors.yellowAccent,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                      ),
                    ],
                  ),
                )),
          ),
        ],
      ),
    );
  }
}
