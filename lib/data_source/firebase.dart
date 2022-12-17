import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:techno_store/core/create_user_account/model/create_user_account_model.dart';
import 'package:techno_store/shared/message.dart';
import 'package:uuid/uuid.dart';

class FirebaseDataSource {
  static final FirebaseDataSource instance = FirebaseDataSource._internal();
  late final FirebaseAuth firebaseAuth;
  late final FirebaseFirestore firebaseFirestore;
  late final FirebaseStorage firebaseStorage;

  factory FirebaseDataSource() {
    return instance;
  }

  FirebaseDataSource._internal() {
    firebaseAuth = FirebaseAuth.instance;
    firebaseFirestore = FirebaseFirestore.instance;
    firebaseStorage = FirebaseStorage.instance;
  }

  ////
  ////
  ////
  //////////////////////   User Authentication  ------->>>>>>> /////////////////
  ////
  /////
  /////

  Future<void> signIn(String email, String password) async {
    try {
      await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password)
          .then((value) => print(value.user?.email));
    } catch (e, v) {
      print(e.toString() + "----->" + v.toString());
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password)
          .then((value) => print(value.user?.email));
    } catch (e, v) {
      Message.showErrorToastMessage(e.toString());
      print(e.toString() + "----->" + v.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } catch (e, v) {
      print(e.toString() + "----->" + v.toString());
    }
  }

  Future<void> resetPassword(String email) async {
    print("rrrrrrrrrrrrrrrrrrr");
    try {
      await firebaseAuth
          .sendPasswordResetEmail(email: email)
          .onError((error, stackTrace) => print(error));
    } catch (e, v) {
      print(e.toString() + " -----> " + v.toString());
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await firebaseAuth.currentUser?.sendEmailVerification();
    } catch (e, v) {
      print(e.toString() + " -----> " + v.toString());
    }
  }

  ////
  ////
  ////
  //////////////////////   <<<<<<<---------   User Authentication  /////////////////
  ////
  ////
  ////

  ////
  ////
  ////
  //////////////////////   User Information  ------->>>>>>> /////////////////
  ////
  ////
  ////

  Future<void> saveUserInfo(
      CreateUserAccountModel createUserAccountModel) async {
    Map<String, dynamic> data = createUserAccountModel.toJson();

    try {
      if (data["photo"] != "") {
        data["photo"] = uploadPhoto(data["photo"] ?? "");
      }

      await firebaseFirestore
          .collection("users")
          .doc(firebaseAuth.currentUser?.uid)
          .set(data);
    } catch (e, v) {
      print(e.toString() + " -----> " + v.toString());
    }
  }

////
////
////
//////////////////////   <<<<<<<---------   User Information  /////////////////
////
////
////

////
////
////
//////////////////////   Photos  ------->>>>>>> /////////////////
////
////
////

  Future<String> uploadPhoto(String photo) async {
    try {
      if (photo != "") {
        final snapshot = await firebaseStorage
            .ref()
            .child('Images/' + const Uuid().v4())
            .putFile(File(photo))
            .whenComplete(() => null);
        //to save the link of the photo
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e, v) {
      print(e.toString() + " -----> " + v.toString());
    }

    return "";
  }

////
////
////
//////////////////////   <<<<<<<---------   Photos  /////////////////
////
////
////

////
////
////
//////////////////////   Categories ans Sub-Categories  ------->>>>>>> /////////////////
////
////
////

////
////
////
//////////////////////   <<<<<<<---------   Categories ans Sub-Categories  /////////////////
////
////
////
}
