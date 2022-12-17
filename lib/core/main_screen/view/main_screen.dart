import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/core/create_user_account/view/create_user_account_view.dart';
import 'package:techno_store/core/reset_password/view/reset_password.dart';
import 'package:techno_store/core/welcome_page/view/welcome_page.dart';
import 'package:techno_store/data_source/firebase.dart';
import 'package:techno_store/shared/color_utilities.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}



class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {

    return StreamBuilder<User?>(
        stream: FirebaseDataSource()
            .firebaseAuth
            .authStateChanges(),
        builder: ((context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(child: CircularProgressIndicator());
          }
          else if (snapshot.hasData) {
            return WelcomePage();
          } else {
            return SignIn();
          }
        }));
  }
}

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

final login_email = TextEditingController();
final login_password = TextEditingController();

class _SignInState extends State<SignIn> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Container(
            color: ColorUtilities.backgroundContainer,
            child: Container(
                width: width,
                height: height * 0.4,
                decoration: const BoxDecoration(
                  color:ColorUtilities.secondary,
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
                  color: ColorUtilities.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Container(
                  margin: EdgeInsets.only(top: 30, left: 40, right: 40),
                  child: Column(
                    children: [
                      StreamBuilder<User?>(
                          stream: FirebaseDataSource()
                              .firebaseAuth
                              .authStateChanges(),
                          builder: ((context, snapshot) {
                            if (snapshot.hasData) {
                              return Text("signed in");
                            } else {
                              return Text("signed out");
                            }
                          })),
                      Row(
                        children: [
                          ElevatedButton(
                              onPressed: () async {
                                await FirebaseDataSource()
                                    .signIn("mmm@gmail.com", "mmmmmmmm");
                              },
                              child: Text("jhgfjhgfgh")),
                          ElevatedButton(
                              onPressed: () {
                                FirebaseDataSource().signOut();
                                // await FirebaseAuth.instance.signOut();

                                if (FirebaseDataSource()
                                    .firebaseAuth
                                    .currentUser ==
                                    null) {
                                  print("no user founed");
                                } else {
                                  print(FirebaseDataSource()
                                      .firebaseAuth
                                      .currentUser
                                      ?.uid);
                                }
                              },
                              child: Text("out")),
                        ],
                      ),
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
                            hintText: ' Email ',
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
                            hintText: ' password ',
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => WelcomePage()),
                          );
                        },
                        child: Container(
                          width: width * 0.5,
                          height: height * 0.06,
                          child: Center(
                              child: Text(
                                "Login",
                                textAlign: TextAlign.center,
                              )),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: ColorUtilities.secondary,
                          textStyle:
                          TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        "or",
                        style: TextStyle(color: Colors.grey),
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
                              child: Text(
                                "Create new account",
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
                          "Forget password?",
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
                )),
          )
        ],
      ),
    );
  }
}

