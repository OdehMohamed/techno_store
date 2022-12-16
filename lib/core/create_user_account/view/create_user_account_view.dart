// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/data_source/firebase.dart';
import 'package:techno_store/shared/color_utilities.dart';

class CreateUserAccount extends StatefulWidget {
  const CreateUserAccount({Key? key}) : super(key: key);

  @override
  State<CreateUserAccount> createState() => _CreateUserAccountState();
}

final fullname_controller = TextEditingController();
final email_controller = TextEditingController();
final password_controller = TextEditingController();
final re_password_controller = TextEditingController();

class _CreateUserAccountState extends State<CreateUserAccount> {
  String photoPath = "";

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
      extendBodyBehindAppBar: true,
      body: Column(
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
                  child: Text(
                    "New Account",
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
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
                  child: Column(
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
                                      // final ImagePicker _picker = ImagePicker();
                                      // // Pick an image
                                      // var image = await _picker.pickImage(
                                      //     source: ImageSource.gallery);
                                      // print(image?.path ?? "ss");
                                      // if (image?.path != null) {
                                      //   setState(() {
                                      //     photoPath = image!.path;
                                      //   });
                                      // }
                                      //
                                      //
                                      //
                                      //Use image picker here
                                      //
                                      //
                                      //

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
                        child: TextField(
                          controller: fullname_controller,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.perm_identity_outlined,
                              color: ColorUtilities.secondary,
                              size: 28,
                            ),
                            hintText: ' Full name ',
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: TextField(
                          controller: email_controller,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.email,
                              color: ColorUtilities.secondary,
                              size: 28,
                            ),
                            hintText: ' Email ',
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: TextField(
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
                            hintText: ' Password ',
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: TextField(
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
                            hintText: ' re-password ',
                            hintStyle:
                                TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseDataSource()
                              .signUp("maenobaid123@gmail.com", "mmmmmmmm");
                        },
                        child: Container(
                          width: 200,
                          child: Text(
                            "Create Account",
                            textAlign: TextAlign.center,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorUtilities.primary,
                          textStyle:
                              TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )),
          )
        ],
      ),
    );
  }
}
