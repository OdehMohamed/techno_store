import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/favorite_items/view/favoriteItems.dart';
import 'package:techno_store/core/maintenance_list/view/maintenance_list.dart';
import 'package:techno_store/core/manage_categories/view/manage_category_view.dart';
import 'package:techno_store/core/new_device_maintenance/view/new_device_maintenance.dart';
import 'package:techno_store/core/new_product/view/new_product.dart';
import 'package:techno_store/core/new_user_admin_side/view/new_user_admin_side.dart';
import 'package:techno_store/core/store/view/store.dart';
import 'package:techno_store/core/welcome_page/view_model/welcome_page_state.dart';
import 'package:techno_store/core/track_phone_page/view/track_phone_page.dart';
import 'package:techno_store/data_source/firebase.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/utilities.dart';
import '../../../shared/widget_utilities.dart';
import '../../selectCategory/view/selectCategory.dart';
import '../../shared/view_model/shared_state.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late WelcomePageState welcomePageState;
  late SharedState sharedState;

  @override
  void initState() {
    welcomePageState = context.read<WelcomePageState>();
    sharedState = context.read<SharedState>();
    super.initState();
  }

  void _launchSocial(String url, String fallbackUrl) async {
    try {
      bool launched =
          await launch(url, forceSafariVC: false, forceWebView: false);
      if (!launched) {
        await launch(fallbackUrl, forceSafariVC: false, forceWebView: false);
      }
    } catch (e) {
      await launch(fallbackUrl, forceSafariVC: false, forceWebView: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    welcomePageState = context.watch<WelcomePageState>();
    sharedState = context.watch<SharedState>();
    if (FirebaseDataSource().firebaseAuth.currentUser != null &&
        FirebaseDataSource().firebaseAuth.currentUser?.uid != null &&
        sharedState.userId == null) {
      sharedState
          .updateUserInfo(FirebaseDataSource().firebaseAuth.currentUser!.uid);
    }
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Widget card(String title, Icon icon, tap()) {
      return Column(
        children: [
          // Consumer<SharedState>(
          //     builder: (context, profile, child) {
          //       if (FirebaseDataSource().firebaseAuth.currentUser != null &&
          //           FirebaseDataSource().firebaseAuth.currentUser?.uid != null &&
          //           sharedState.userId == null) {
          //         sharedState
          //             .updateUserInfo(FirebaseDataSource().firebaseAuth.currentUser!.uid);
          //       }
          //       return SizedBox();}),
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
    CircleAvatar profile_image = CircleAvatar(
      backgroundImage: AssetImage("assets/images/defaultImg.png"),
      backgroundColor: Colors.white,
    );
    if (sharedState.userPhoto != null) {
      if (sharedState.userPhoto!.isNotEmpty) {
        profile_image = CircleAvatar(
          backgroundImage: NetworkImage(sharedState.userPhoto!),
          backgroundColor: Colors.white,
        );
      }
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10, left: 10),
            child: Center(
              child: InkWell(
                onTap: () {
                  context.locale = context.locale == Locale("en")
                      ? Locale("ar")
                      : Locale("en");
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
                child: profile_image),
            SizedBox(
              height: 10,
            ),
            WidgetUtilities.autoSizeText(
              sharedState.userName ?? "loading",
            ),
            Flexible(
                child: ListView(
              children: [
                sharedState.userType!=3?
                card("Favorite", Icon(Icons.star, color: Colors.yellow), () {
                  Utilities.navigatorWithBack(context, favoraitItems());
                }):SizedBox(),
                sharedState.userType!=3?
                card(
                    "Store",
                    Icon(
                      Icons.shopping_cart,
                      color: Colors.white60,
                    ), () {
                  Utilities.navigatorWithBack(context, SelectCategory());
                }):SizedBox(),
                card(
                    "Check My Device",
                    Icon(
                      Icons.phone_android,
                      color: Colors.white60,
                    ), () {
                  Utilities.navigatorWithBack(context, TrackPhonePage());
                }),
                sharedState.userType == 0 ||
                        sharedState.userType == 2 ||
                        sharedState.userType == 3
                    ? card("Maintenance",
                        Icon(Icons.add_to_home_screen, color: Colors.white60),
                        () {
                        Utilities.navigatorWithBack(context, MaintinanceList());
                      })
                    : SizedBox(),
                sharedState.userType == 0
                    ? card(
                        "Add new Employee",
                        Icon(
                          Icons.person_add,
                          color: Colors.white60,
                        ), () {
                        Utilities.navigatorWithBack(
                            context, NewUserAdminSide());
                      })
                    : SizedBox(),
                sharedState.userType == 0
                    ? card(
                        "Add new Product",
                        Icon(
                          Icons.note_add,
                          color: Colors.white60,
                        ), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NewProduct(
                                    editable: false,
                                  )),
                        );
                      })
                    : SizedBox(),
                sharedState.userType == 0
                    ? card(
                        "Manage Categories",
                        Icon(
                          Icons.category,
                          color: Colors.white60,
                        ), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => manageCategory()),
                        );
                      })
                    : SizedBox(),
              ],
            )),
            InkWell(
                onTap: () async {
                  try {
                    await welcomePageState.signOut();
                  } catch (e) {
                    print(e.toString());
                  }
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
      body: ModalProgressHUD(
        opacity: 0.3,
        inAsyncCall: welcomePageState.loading||sharedState.userType==null,
        child: Column(
          children: [
            Container(
              color: ColorUtilities.backgroundContainer,
              child: Container(
                  width: width,
                  height: height * 0.2,
                  decoration: const BoxDecoration(
                    color: ColorUtilities.secondary,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.only(top: height*0.05),
                          child:Center(
                              child:
                             Column(
                               children: [
                                 Text("T.E.C.H.N.O",
                                   style: TextStyle(
                                     fontSize: width*0.075,
                                     color: ColorUtilities.backgroundContainer,
                                     letterSpacing: 3,

                                   ),
                                 ),
                                 Container(
                                   padding: EdgeInsets.only(left: width*0.05),
                                   child: Text("Store",
                                     textAlign: TextAlign.center,
                                     style: TextStyle(
                                       fontSize: width*0.075,
                                       color: ColorUtilities.backgroundContainer,
                                       letterSpacing: 20,
                                     ),
                                   ),
                                 ),
                               ],
                             )
                          )
                      ),
                    ],
                  )
              ),
            ),
            Container(
              color: ColorUtilities.secondary,
              child: Container(
                  width: width,
                  height: height * 0.68,
                  decoration: const BoxDecoration(
                    color: ColorUtilities.backgroundContainer,
                  ),
                  child: Container(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          sharedState.userType!=3&&sharedState.userType!=null?
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => SelectCategory()),
                              );
                            },
                            child: Container(
                              padding: Utilities.isEnglish(context)?EdgeInsets.only(right: 10):
                              EdgeInsets.only(left: 10)
                                ,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: ColorUtilities.secondary,
                                ),
                                width: width*0.5,
                                height: height*0.12,
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_cart,color: ColorUtilities.white,size: 30,),
                                      WidgetUtilities.autoSizeText(
                                        "Store",
                                        textStyle: TextStyle(
                                            fontSize: 26,
                                            color: ColorUtilities.textColor),
                                      )
                                    ],
                                  ),
                                )),
                          ):
                              sharedState.userType!=null?
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => TrackPhonePage()),
                              );
                            },
                            child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: ColorUtilities.secondary,
                                ),
                                width: width*0.5,
                                height: height*0.12,
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                    Icon(Icons.phone_android,color: ColorUtilities.white,size: 30,),
                                    WidgetUtilities.autoSizeText(
                                      "Check Status",
                                      textStyle: TextStyle(
                                          fontSize: 22,
                                          color: ColorUtilities.textColor),
                                    )
                                  ],),
                                )),
                          ):
                                  SizedBox(),
                          SizedBox(
                            height: height * 0.05,
                          ),
                          InkWell(
                            onTap: () {
                              sharedState.userType != 1
                                  ? Utilities.navigatorWithBack(
                                  context, MaintinanceList())
                                  : Utilities.navigatorWithBack(
                                  context, TrackPhonePage());
                            },
                            child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: ColorUtilities.secondary,
                                ),
                                width: width*0.5,
                                height: height*0.12,
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_to_home_screen,color: Colors.white,size: 30,),
                                      WidgetUtilities.autoSizeText(
                                        "Maintenance",
                                        textStyle: TextStyle(
                                            color: ColorUtilities.textColor,
                                            fontSize: 22),
                                      )
                                    ],
                                  ),
                                )),
                          ),
                        ],
                      ),
                    ),
                  )),
            ),
            Container(
              color: ColorUtilities.secondary,
              height: height*0.12,
              child:Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                Text("Contact us:".tr(),style: TextStyle(color: Colors.white,fontSize: 18,fontWeight: FontWeight.bold),),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(5),
                      child: InkWell(
                        child: Icon(
                          FontAwesome5.whatsapp,
                          color: ColorUtilities.secondary,
                          size: 30,
                        ),
                        onTap: () {
                          _launchSocial(
                              'https://wa.me/message/WGQOCNRN47W7M1?src=qr',
                              'https://wa.me/message/WGQOCNRN47W7M1?src=qr');
                        },
                      ),
                      decoration: BoxDecoration(
                        color: ColorUtilities.backgroundContainer,
                        borderRadius: BorderRadius.circular(50)
                      ),
                    ),
                    SizedBox(width: 15),
                    Container(
                      padding: EdgeInsets.all(5),
                      child: InkWell(
                        child: Icon(
                          FontAwesome5.facebook,
                          color: ColorUtilities.secondary,
                          size: 30,
                        ),
                        onTap: () {
                          _launchSocial('fb://profile/100088001516569',
                              'facebook.com/people/Techno-Store-تكنو-ستور/100088001516569/');
                        },
                      ),
                      decoration: BoxDecoration(
                          color: ColorUtilities.backgroundContainer,
                          borderRadius: BorderRadius.circular(50)
                      ),
                    ),
                    SizedBox(width: 15),
                    Container(
                      padding: EdgeInsets.all(5),
                      child: InkWell(
                        child: Icon(
                          FontAwesome5.instagram,
                          color: ColorUtilities.secondary,
                          size: 30,
                        ),
                        onTap: () {
                          _launchSocial(
                              'instagram://user?username=techno__store00',
                              'https://www.instagram.com/techno__store00/?igshid=YmMyMTA2M2Y%3D');
                        },
                      ),
                      decoration: BoxDecoration(
                          color: ColorUtilities.backgroundContainer,
                          borderRadius: BorderRadius.circular(50)
                      ),
                    ),
                    SizedBox(width: 15),
                    Container(
                      padding: EdgeInsets.all(5),
                      child: InkWell(
                        child: Icon(
                          FontAwesome5.snapchat,
                          color:ColorUtilities.secondary,
                          size: 30,
                        ),
                        onTap: () {
                          _launchSocial(
                              'https://www.snapchat.com/add/technostore0',
                              'https://www.snapchat.com/add/technostore0');
                        },
                      ),
                      decoration: BoxDecoration(
                          color: ColorUtilities.backgroundContainer,
                          borderRadius: BorderRadius.circular(50)
                      ),
                    ),
                    SizedBox(width: 15),
                    Container(
                      padding: EdgeInsets.all(5),
                      child:
                      InkWell(
                        child: Icon(
                          Icons.tiktok,
                          color: ColorUtilities.secondary,
                          size: 30,
                        ),
                        onTap: () {
                          _launchSocial(
                              'https://www.tiktok.com/@technostore11?_t=8YtE7LC84os&_r=1',
                              'https://www.tiktok.com/@technostore11?_t=8YtE7LC84os&_r=1');
                        },
                      ),
                      decoration: BoxDecoration(
                          color: ColorUtilities.backgroundContainer,
                          borderRadius: BorderRadius.circular(50)
                      ),
                    ),
                  ],
                ),
              ],)
            ),
          ],
        ),
      ),
    );
  }
}
