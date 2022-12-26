import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/data_source/firebase.dart';
import 'package:techno_store/shared/color_utilities.dart';

import '../../../shared/message.dart';
import '../../../shared/widget_utilities.dart';
import '../view_model/reset_password_state.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

final email_controller = TextEditingController();
final _formKey = GlobalKey<FormState>();

class _ResetPasswordState extends State<ResetPassword> {
  late ResetPasswordState resetPasswordState;
  @override
  void initState() {
    resetPasswordState = context.read<ResetPasswordState>();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    resetPasswordState=context.watch<ResetPasswordState>();
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
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
                  child: WidgetUtilities.autoSizeText(
                    "Reset Password".tr(),
                    textStyle: TextStyle(fontSize: 22,color: ColorUtilities.textColor)
                  ),
                )),
          ),
          Container(
            color: ColorUtilities.secondary,
            child: Container(
                width: width,
                height: height * 0.75,
                decoration: const BoxDecoration(
                  color: ColorUtilities.backgroundContainer,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Container(
                    margin: EdgeInsets.only(right: 40, left: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        WidgetUtilities.autoSizeText(
                          "We will send an Email to reset your password",
                          textAlign: TextAlign.center,
                          textStyle: TextStyle(color: Colors.black)
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
                                hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please Enter".tr()+" "+"Email".tr();
                                }
                                if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                    .hasMatch(value)) {
                                  return "Please Enter".tr()+" "+"valid Email".tr();
                                }
                                return null;
                              },
                            ),
                          )
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                            resetPasswordState.resetPassword(email_controller.text).then((value) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content:  Text('Please check your email or spam'.tr()),
                              )
                              );
                            });
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
    );
  }
}
