import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/core/create_user_account/view/create_user_account_view.dart';
import 'package:techno_store/core/main_screen/view_model/main_screen_state.dart';
import 'package:techno_store/core/reset_password/view/reset_password.dart';
import 'package:techno_store/core/shared/view_model/shared_state.dart';
import 'package:techno_store/data_source/firebase.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:techno_store/shared/message.dart';
import 'package:techno_store/shared/utilities.dart';
import 'package:techno_store/shared/widget_utilities.dart';

class SignInForm extends StatefulWidget {
  final MainScreenState mainScreenState;
  final SharedState sharedState;
  final bool? isTesting;
  const SignInForm({Key? key, required this.mainScreenState, required this.sharedState, this.isTesting}) : super(key: key);

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final login_email = TextEditingController();
  final login_password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Container(
      margin: EdgeInsets.only(
        top: 30,
        left: width < 500
            ? width * 0.1
            : width < 1025
                ? width * 0.2
                : width * 0.3,
        right: width < 500
            ? width * 0.1
            : width < 1025
                ? width * 0.2
                : width * 0.3,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              "Login".tr(),
              style: TextStyle(
                  fontSize: 26,
                  color: ColorUtilities.secondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: Utilities.isEnglish(context) ? 3 : 0),
            ),
            Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: ColorUtilities.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextFormField(
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
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please Enter".tr() + " " + "Email".tr();
                      }
                      if (!RegExp(
                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                          .hasMatch(value)) {
                        return "Please Enter".tr() + " " + "valid Email".tr();
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  height: height * 0.05,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: ColorUtilities.white,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextFormField(
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
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please Enter".tr() + " " + "Password".tr();
                      }
                      if (value.length < 8) {
                        return "Password".tr() + " " + "too short".tr();
                      }
                      if (value.contains(" ")) {
                        return "Password".tr() + " " + "can't have spaces".tr();
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      try {
                        widget.mainScreenState
                            .signIn(
                                login_email.text.trim(), login_password.text)
                            .then((value) {
                          if (FirebaseDataSource().firebaseAuth.currentUser !=
                                  null &&
                              FirebaseDataSource()
                                      .firebaseAuth
                                      .currentUser
                                      ?.uid !=
                                  null) {
                            widget.sharedState.updateUserInfo(FirebaseDataSource()
                                .firebaseAuth
                                .currentUser!
                                .uid);
                          }
                        });
                      } catch (e) {
                        Message.showErrorToastMessage(
                            "Wrong inputs or you are not signed up");
                      }
                    }
                  },
                  child: Container(
                    width: width < 500
                        ? width * 0.5
                        : width < 1025
                            ? width * 0.4
                            : width * 0.3,
                    height: width < 500
                        ? height * 0.06
                        : width < 1025
                            ? height * 0.04
                            : height * 0.06,
                    child: Center(
                        child: WidgetUtilities.autoSizeText(
                      "Login",
                      textAlign: TextAlign.center,
                    )),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorUtilities.secondary,
                    textStyle: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                (widget.isTesting ?? false)
                    ? Column(
                        children: [
                          SizedBox(
                            height: 10,
                          ),
                          InkWell(
                            child: Text(
                              "Login as a Guest".tr() + "?".tr(),
                              style:
                                  TextStyle(color: Colors.blue, fontSize: 12),
                            ),
                            onTap: () {
                              try {
                                widget.mainScreenState
                                    .signIn("guest@gmail.com", "123456789")
                                    .then((value) {
                                  if (FirebaseDataSource()
                                              .firebaseAuth
                                              .currentUser !=
                                          null &&
                                      FirebaseDataSource()
                                              .firebaseAuth
                                              .currentUser
                                              ?.uid !=
                                          null) {
                                    widget.sharedState.updateUserInfo(
                                        FirebaseDataSource()
                                            .firebaseAuth
                                            .currentUser!
                                            .uid);
                                  }
                                });
                              } catch (e) {
                                Message.showErrorToastMessage(
                                    "Wrong inputs or you are not signed up");
                              }
                            },
                          )
                        ],
                      )
                    : SizedBox(),
                SizedBox(
                  height: 15,
                ),
                WidgetUtilities.autoSizeText(
                  "or",
                  textStyle: TextStyle(color: Colors.grey),
                ),
                SizedBox(
                  height: 15,
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreateUserAccount()),
                    );
                  },
                  child: Container(
                    width: width < 500
                        ? width * 0.5
                        : width < 1025
                            ? width * 0.4
                            : width * 0.3,
                    height: width < 500
                        ? height * 0.06
                        : width < 1025
                            ? height * 0.04
                            : height * 0.06,
                    child: Center(
                        child: WidgetUtilities.autoSizeText(
                      "Create new Account",
                      textAlign: TextAlign.center,
                    )),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(128, 128, 128, 1),
                    textStyle: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
            InkWell(
              child: Text(
                "Forget password".tr() + "?".tr(),
                style: TextStyle(color: Colors.blue, fontSize: 12),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ResetPassword()),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
