import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/create_user_account/view/create_user_account_view.dart';
import 'package:techno_store/core/main_screen/view_model/main_screen_state.dart';
import 'package:techno_store/core/reset_password/view/reset_password.dart';
import 'package:techno_store/core/welcome_page/view/welcome_page.dart';
import 'package:techno_store/data_source/firebase.dart';
import 'package:techno_store/shared/color_utilities.dart';

import '../../../shared/widget_utilities.dart';
import 'package:techno_store/shared/message.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseDataSource().firebaseAuth.authStateChanges(),
        builder: ((context, snapshot) {
          // if(snapshot.connectionState == ConnectionState.waiting){
          //   return Center(child: CircularProgressIndicator());
          // }
          // else
          if (snapshot.hasData) {
            return WelcomePage();
          } else if (!snapshot.hasData) {
            return SignIn();
          } else {
            return Center(child: CircularProgressIndicator());
          }
        }));
  }
}

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final login_email = TextEditingController();
  final login_password = TextEditingController();
  late MainScreenState mainScreenState;

  @override
  void initState() {
    mainScreenState = context.read<MainScreenState>();
    super.initState();
  }

  @override
  void dispose() {
    login_email.dispose();
    login_password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    mainScreenState = context.watch<MainScreenState>();
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ModalProgressHUD(
        inAsyncCall: mainScreenState.loading,
        child: Column(
          children: [
            Container(
              color: ColorUtilities.backgroundContainer,
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
                          color: ColorUtilities.white,
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
                      Container(
                        decoration: BoxDecoration(
                          color: ColorUtilities.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: TextField(
                          controller: login_email,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.perm_identity_outlined,
                              color: ColorUtilities.secondary,
                              size: 28,
                            ),
                            hintText: 'Email'.tr(),
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      Container(
                        decoration: BoxDecoration(
                          color: ColorUtilities.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: TextField(
                          controller: login_password,
                          obscureText: true,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              color: ColorUtilities.secondary,
                              size: 28,
                            ),
                            hintText: 'Password'.tr(),
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          try {
                            mainScreenState.signIn(
                                "obeidmaen@gmail.com", "mmmmmmmm");
                          } catch (e) {
                            Message.showErrorToastMessage(
                                "Wrong inputs or you are not signed up");
                          }
                        },
                        child: Container(
                          width: width * 0.5,
                          height: height * 0.06,
                          child: Center(
                              child: WidgetUtilities.autoSizeText(
                            "Login",
                            textAlign: TextAlign.center,
                          )),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorUtilities.secondary,
                          textStyle:
                              TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 15),
                      WidgetUtilities.autoSizeText(
                        "or",
                        textStyle: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CreateUserAccount()),
                          );
                        },
                        child: Container(
                          width: width * 0.5,
                          height: height * 0.06,
                          child: Center(
                              child: WidgetUtilities.autoSizeText(
                            "Create new Account",
                            textAlign: TextAlign.center,
                          )),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: Color.fromRGBO(128, 128, 128, 1),
                          textStyle:
                              TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 35),
                      InkWell(
                        child: Text(
                          "Forget password".tr() + "?".tr(),
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ResetPassword()),
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
