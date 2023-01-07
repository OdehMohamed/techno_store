// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/new_device_maintenance/view/new_device_maintenance.dart';
import 'package:techno_store/core/shared/model/create_user_account_model.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../../../shared/widget_utilities.dart';
import '../../shared/view_model/shared_state.dart';

class CreateUserAccount extends StatefulWidget {
  const CreateUserAccount({Key? key}) : super(key: key);

  @override
  State<CreateUserAccount> createState() => _CreateUserAccountState();
}

class _CreateUserAccountState extends State<CreateUserAccount> {

  String photoPath = "";
  final _formKey = GlobalKey<FormState>();

  final fullname_controller = TextEditingController();
  final email_controller = TextEditingController();
  final password_controller = TextEditingController();
  final re_password_controller = TextEditingController();

  late SharedState createUserAccountState;

  @override
  void initState() {
    createUserAccountState = context.read<SharedState>();
    super.initState();
  }

  @override
  void dispose() {
    fullname_controller.dispose();
    email_controller.dispose();
    password_controller.dispose();
    re_password_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    createUserAccountState = context.watch<SharedState>();
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
      extendBodyBehindAppBar: true,
      body: ModalProgressHUD(
        inAsyncCall: createUserAccountState.loading,
        child:SingleChildScrollView(child:  GestureDetector(
          onTap: (){
            FocusScope.of(context).requestFocus(FocusNode());
            },
          child: Column(
            children: [
              Container(
                color: Color.fromRGBO(239, 239, 239, 1),
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
                            "New Account",
                            textStyle: TextStyle(fontSize: 20,color: ColorUtilities.textColor
                            ))
                    )),
              ),
              Container(
                color: ColorUtilities.secondary,
                child: Container(
                    width: width,
                    height: height * 0.75,
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(239, 239, 239, 1),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: Container(
                        margin: EdgeInsets.only(right: 40, left: 40),
                        child:Form(
                          key: _formKey,
                          child:  Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                      decoration: BoxDecoration(
                                        color: ColorUtilities.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                            ColorUtilities.black.withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: Offset(0, 15),
                                          ),
                                        ],
                                      ),
                                      width: 100,
                                      height: 100,
                                      child: photoPath.isNotEmpty
                                          ? Image.file(
                                        File(photoPath),
                                        fit: BoxFit.fill,
                                      )
                                          : Image.asset(
                                          "assets/images/defaultImg.png")),
                                  Container(
                                      height: 110,
                                      width: 100,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          InkWell(
                                            child: Container(
                                                width: 25,
                                                height: 25,
                                                decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    borderRadius:
                                                    BorderRadius.circular(50)),
                                                child: Center(
                                                  child: Text("+"),
                                                )),
                                            onTap: () async {


                                              final result =
                                              await FilePicker.platform.pickFiles(
                                                type: FileType.image,
                                              );
                                              if (result != null) {
                                                final file = result.files.first;

                                                setState(() {
                                                  photoPath = file.path!;
                                                });
                                              }
                                            },
                                          )
                                        ],
                                      )),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                  controller: fullname_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    prefixIcon: Icon(
                                      Icons.perm_identity_outlined,
                                      color: ColorUtilities.secondary,
                                      size: 28,
                                    ),
                                    hintText: 'Full name'.tr(),
                                    hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter".tr()+" "+"Full name".tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                  controller: email_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    prefixIcon: Icon(
                                      Icons.email,
                                      color: ColorUtilities.secondary,
                                      size: 28,
                                    ),
                                    hintText: 'Email'.tr(),
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
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                  obscureText: true,
                                  controller: password_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: ColorUtilities.secondary,
                                      size: 28,
                                    ),
                                    hintText: 'Password'.tr(),
                                    hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter".tr()+" "+"Password".tr();
                                    }
                                    if (value.length<8){
                                      return "Password".tr()+" " +"too short".tr();
                                    }
                                    if (value.contains(" ")){
                                      return "Password".tr()+" " +"can't have spaces".tr();
                                    }
                                    if (value!=re_password_controller.value.text){
                                      return "Passwords does not match".tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                    obscureText: true,
                                    controller: re_password_controller,
                                    style: TextStyle(color: Colors.black),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      prefixIcon: Icon(
                                        Icons.lock,
                                        color: ColorUtilities.secondary,
                                        size: 28,
                                      ),
                                      hintText: 're-password'.tr(),
                                      hintStyle:
                                      TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please Enter".tr()+" "+"re-password".tr();
                                      }
                                      if (value!=password_controller.value.text){
                                        return "Passwords does not match".tr();
                                      }
                                      return null;
                                    }
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    await createUserAccountState
                                        .signUp(
                                        email_controller.text,
                                        password_controller.text,
                                        CreateUserAccountModel(
                                            name: fullname_controller.text, photo: photoPath))
                                        .then((value) => Navigator.pop(context));
                                      String s = createUserAccountState.userName ?? "";
                                      print("pleassse : " + s);
                                  }
                                },
                                child: Container(
                                    width: 200,
                                    child: WidgetUtilities.autoSizeText(
                                        "Create Account",
                                        textAlign: TextAlign.center
                                    )
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ColorUtilities.primary,
                                  textStyle:
                                  TextStyle(fontSize: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        )
                    )),
              )
            ],
          ),
        ),)
      ),
    );
  }
}
