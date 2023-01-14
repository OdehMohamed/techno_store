import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/data_source/firebase.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:techno_store/shared/utilities.dart';

import '../../../shared/message.dart';
import '../../../shared/widget_utilities.dart';
import '../view_model/reset_password_state.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final email_controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late ResetPasswordState resetPasswordState;
  @override
  void initState() {
    resetPasswordState = context.read<ResetPasswordState>();
    super.initState();
  }

  @override
  void dispose() {
    email_controller.dispose();
    super.dispose();
  }

  resetMessage(value) {
    if (value) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please check your email or spam'.tr()),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    resetPasswordState = context.watch<ResetPasswordState>();
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Column(
          children: [
            Container(
              color: ColorUtilities.backgroundContainer,
              child: Container(
                padding: EdgeInsets.all(height*0.02),
                  width: width,
                  height: height * 0.1,
                  decoration: const BoxDecoration(
                    color: ColorUtilities.secondary,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children:[ WidgetUtilities.autoSizeText("Reset Password".tr(),
                        textStyle: TextStyle(
                            fontSize: 22, color: ColorUtilities.textColor))],
                  )),
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
                      margin: EdgeInsets.only(right: 40, left: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              WidgetUtilities.autoSizeText(
                                  "We will send an Email to reset your password",
                                  textAlign: TextAlign.center,
                                  textStyle: TextStyle(color: Colors.black)),
                              Padding(
                                  padding: Utilities.getDefaultTBPadding() * 5),
                              WidgetUtilities.autoSizeText("check spam",
                                  textAlign: TextAlign.center,
                                  textStyle:
                                      TextStyle(color: Colors.redAccent)),
                              SizedBox(height: height*0.05,),
                            ],
                          ),
                          Container(
                              padding: EdgeInsets.only(left: 20, right: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Form(
                                key: _formKey,
                                child: TextFormField(
                                  controller: email_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Please Enter your Email'.tr(),
                                    hintStyle: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter".tr() +
                                          " " +
                                          "Email".tr();
                                    }
                                    if (!RegExp(
                                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                        .hasMatch(value)) {
                                      return "Please Enter".tr() +
                                          " " +
                                          "valid Email".tr();
                                    }
                                    return null;
                                  },
                                ),
                              )),
                          SizedBox(height: height*0.1,),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                resetPasswordState
                                    .resetPassword(email_controller.text)
                                    .then((value) => resetMessage(value));
                              }
                            },
                            child: Container(
                              width: width * 0.6,
                              height: height * 0.06,
                              child: Center(
                                  child: WidgetUtilities.autoSizeText(
                                "Send Email",
                                textAlign: TextAlign.center,
                              )),
                            ),
                            style: ElevatedButton.styleFrom(
                              primary: ColorUtilities.secondary,
                              textStyle:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ))),
            )
          ],
        ),
      ),
    );
  }
}
