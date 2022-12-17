import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/maintenance_list/view/maintenance_list.dart';
import 'package:techno_store/core/store/view/store.dart';
import 'package:techno_store/core/welcome_page/view_model/welcome_page_state.dart';
import 'package:techno_store/data_source/firebase.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late WelcomePageState welcomePageState;

  @override
  void initState() {
    welcomePageState = context.read<WelcomePageState>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    welcomePageState = context.watch<WelcomePageState>();
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Widget card(
      String title,
      Icon icon,
    ) {
      return Column(
        children: [
          InkWell(
            onTap: () {},
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
                      Text(
                        title,
                        style: TextStyle(color: Colors.white),
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
      appBar: AppBar(
        elevation: 0,
        title: Text("Welcome"),
        backgroundColor: Colors.transparent,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10, left: 10),
            child: Center(
              child: InkWell(
                onTap: () {
                  FirebaseDataSource().sendEmailVerification();
                },
                child: Text(
                  "AR",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        ],
      ),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      drawer: ModalProgressHUD(
        inAsyncCall: welcomePageState.loading,
        child: Container(
          width: 0.8 * width,
          height: height,
          color: Color.fromRGBO(24, 114, 151, 1),
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
              Text(
                "My name ",
                style: TextStyle(color: Colors.white),
              ),
              Flexible(
                  child: ListView(
                children: [
                  card("Favorite", Icon(Icons.star, color: Colors.yellow)),
                  card(
                    "Store",
                    Icon(
                      Icons.shopping_cart,
                      color: Colors.white60,
                    ),
                  ),
                  card(
                    "Check My Device",
                    Icon(
                      Icons.phone_android,
                      color: Colors.white60,
                    ),
                  ),
                  card(
                    "Maintinance",
                    Icon(Icons.add_to_home_screen, color: Colors.white60),
                  ),
                  card(
                    "Add new Emoloyee",
                    Icon(
                      Icons.person_add,
                      color: Colors.white60,
                    ),
                  ),
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
                          Text(
                            "Logout",
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ))),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Color.fromRGBO(239, 239, 239, 1),
            child: Container(
                width: width,
                height: height * 0.4,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(76, 127, 158, 1),
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
            color: Color.fromRGBO(76, 127, 158, 1),
            child: Container(
                width: width,
                height: height * 0.6,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(239, 239, 239, 1),
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
                              color: Color.fromRGBO(76, 127, 158, 1),
                            ),
                            width: 200,
                            height: 90,
                            child: Center(
                              child: Text(
                                "Store",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 22),
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
                              color: Color.fromRGBO(76, 127, 158, 1),
                            ),
                            width: 200,
                            height: 90,
                            child: Center(
                              child: Text(
                                "Maintinance",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 22),
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
