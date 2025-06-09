import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/core/main_screen/view/widgets/sign_in.dart';
import 'package:techno_store/core/welcome_page/view/welcome_page.dart';
import 'package:techno_store/data_source/firebase.dart';

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
