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
      rethrow;
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
        data["photo"] = await uploadPhoto(data["photo"] ?? "");
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

  void getCategories() async {
    await firebaseFirestore.collection("categories").get().then((value) {
      value.docs.forEach((element) {
        print(element.data().toString());
      });
    });
  }

  void addCategory(Map<String, dynamic> data) async {
    await firebaseFirestore
        .collection("categories")
        .add(data)
        .then((value) => print(value.id));
  }

  Future<void> editCategory(
      String categoryID, Map<String, dynamic> data) async {
    await firebaseFirestore
        .collection("categories")
        .doc(categoryID)
        .update(data)
        .then((value) => print("Updated"));
  }

  void getSubCategories(String categoryID) async {
    await firebaseFirestore
        .collection("categories")
        .doc(categoryID)
        .collection("sub-categories")
        .get()
        .then((value) {
      for (var element in value.docs) {
        print(element.data().toString());
      }
    });
  }

  void addSubCategories(String categoryID, Map<String, dynamic> data) async {
    await firebaseFirestore
        .collection("categories")
        .doc(categoryID)
        .collection("sub-categories")
        .add(data)
        .then((value) {
      print(value.id);
    });
  }

  void editSubCategories(String categoryID, String subCategoryID,
      Map<String, dynamic> data) async {
    await firebaseFirestore
        .collection("categories")
        .doc(categoryID)
        .collection("sub-categories")
        .doc(subCategoryID)
        .update(data)
        .then((value) {
      print("Updated");
    });
  }

////
////
////
//////////////////////   <<<<<<<---------   Categories ans Sub-Categories  /////////////////
////
////
////

  ////
//////////////////////   Products   ------->>>>>>> /////////////////
////
////
////
  void getAllProducts (String category,String sub_category) async {
    await firebaseFirestore
        .collection("products")
        .where("category",isEqualTo: category)
        .where("sub_category",isEqualTo:sub_category)
        .get()
        .then((value) {
      value.docs.forEach((element) {
        print(element.data().toString());
      });
    });
  }
  void addProduct(Map<String, dynamic> data) async {
    await firebaseFirestore
        .collection("products")
        .add(data)
        .then((value) => print(value.id));
  }
  void editProduct(product_id,Map<String, dynamic> data) async {
    await firebaseFirestore
        .collection("products")
        .doc(product_id)
        .update(data)
        .then((value) {
      print("Updated");
    });
  }
  void deleteProduct(String product_id) async {
    await firebaseFirestore
        .collection('products')
        .doc(product_id)
        .delete()
    .then((value) => print(product_id+" -->deleted"));
  }

  ////
////
////
////
//////////////////////   <<<<<<<---------   Products  /////////////////
////
////
////
////
//////////////////////   Maintenance   ------->>>>>>> /////////////////
////
////
////
  void getDevicesInMaintenance (String status) async {
    await firebaseFirestore
        .collection("MaintenanceDevices")
        .where("status",isEqualTo:status)
        .get()
        .then((value) {
      value.docs.forEach((element) {
        print(element.data().toString());
      });
    });
  }
  void addDeviceToMaintenance(Map<String, dynamic> data) async {
    await firebaseFirestore
        .collection("MaintenanceDevices")
        .add(data)
        .then((value) => print(value.id));
  }
  void editDeviceInMaintenance (device_id,Map<String, dynamic> data) async {
    await firebaseFirestore
        .collection("MaintenanceDevices")
        .doc(device_id)
        .update(data)
        .then((value) {
      print("Updated");
    });
  }
  void checkDeviceStatus(String phone_number) async{
    await firebaseFirestore
        .collection("MaintenanceDevices")
        .where("phoneNumber",isEqualTo:phone_number)
        .get()
        .then((value) {
      value.docs.forEach((element) {
        print(element.data().toString());
      });
    });
  }

////
////
////
//////////////////////   <<<<<<<---------   Maintenance  /////////////////

}
