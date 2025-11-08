// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:techno_store/core2/widgets/main_app_bar.dart';
import 'package:techno_store/features/create_user_account/widgets/sign_up_form.dart';

class CreateUserAccount extends StatefulWidget {
  const CreateUserAccount({Key? key}) : super(key: key);

  @override
  State<CreateUserAccount> createState() => _CreateUserAccountState();
}

class _CreateUserAccountState extends State<CreateUserAccount> {
  final _advancedDrawerController = AdvancedDrawerController();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(height * 0.08),
          child: MainAppBar(
            haveLeading: false,
            advancedDrawerController: _advancedDrawerController,
            title: "New Account",
            onLanguageChanged: () {
              setState(() {});
            },
          )),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: height * 0.8,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                  child: SignUpForm(),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
