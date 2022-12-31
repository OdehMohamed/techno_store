import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:techno_store/core/shared/model/create_user_account_model.dart';
import 'package:techno_store/core/shared/model/brand_model.dart';
import 'package:techno_store/core/shared/model/category_and_sub_category_model.dart';
import 'package:techno_store/core/shared/model/maintenance_device_model.dart';
import 'package:techno_store/core/shared/model/productModel.dart';
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

  Future<void> signUp(String email, String password,
      CreateUserAccountModel createUserAccountModel) async {
    try {
      await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password)
          .then((value) => saveUserInfo(createUserAccountModel));
    } catch (e, v) {
      Message.showErrorToastMessage(e.toString());
      print(e.toString() + "----->" + v.toString());
    }
  }

  Future<void> sinUpByAdmin(String email, String password,
      CreateUserAccountModel createUserAccountModel) async {
    FirebaseApp app = await Firebase.initializeApp(
        name: 'Secondary', options: Firebase.app().options);
    try {
      await FirebaseAuth.instanceFor(app: app)
          .createUserWithEmailAndPassword(email: email, password: password)
          .then((value) =>
              saveUserInfo(createUserAccountModel, uid: value.user?.uid));
    } on FirebaseAuthException catch (e) {
      // Do something with exception. This try/catch is here to make sure
      // that even if the user creation fails, app.delete() runs, if is not,
      // next time Firebase.initializeApp() will fail as the previous one was
      // not deleted.
    }

    await app.delete();
  }

  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } catch (e, v) {
      print(e.toString() + "----->" + v.toString());
    }
  }

  Future<void> resetPassword(String email) async {
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

  Future<void> saveUserInfo(CreateUserAccountModel createUserAccountModel,
      {String? uid}) async {
    Map<String, dynamic> data = createUserAccountModel.toJson();

    try {
      if (data["photo"] != "") {
        data["photo"] = await uploadPhoto(data["photo"] ?? "");
      }

      await firebaseFirestore
          .collection("users")
          .doc(uid ?? firebaseAuth.currentUser?.uid)
          .set(data);
    } catch (e, v) {
      print(e.toString() + " -----> " + v.toString());
    }
  }

  Future<CreateUserAccountModel?> getUserInfo(String uid) async {
    CreateUserAccountModel? createUserAccountModel;
    try {
      await firebaseFirestore.collection("users").doc(uid).get().then((value) {
        createUserAccountModel = CreateUserAccountModel.fromJson(value.data()!);
      });
    } catch (e) {}

    return createUserAccountModel;
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
//////////////////////   Categories and Sub-Categories  ------->>>>>>> /////////////////
////
////
////

  Future<List<CategoriesAndSubCategoryModel>> getCategories() async {
    List<CategoriesAndSubCategoryModel> categories = [];
    try {
      await firebaseFirestore.collection("categories").get().then((value) {
        for (var element in value.docs) {
          CategoriesAndSubCategoryModel category =
              CategoriesAndSubCategoryModel.fromJson(element.data());
          category.id = element.id;
          categories.add(category);
        }
      });
    } catch (e) {}

    return categories;
  }

  Future<void> addCategory(
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    await firebaseFirestore
        .collection("categories")
        .add(categoriesAndSubCategoryModel.toJson())
        .then((value) => print(value.id));
  }

  Future<void> editCategory(String categoryID,
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    await firebaseFirestore
        .collection("categories")
        .doc(categoryID)
        .update(categoriesAndSubCategoryModel.toJson())
        .then((value) => print("Updated"));
  }

  Future<List<CategoriesAndSubCategoryModel>> getSubCategories(
      String categoryID) async {
    List<CategoriesAndSubCategoryModel> subCategories = [];
    try {
      await firebaseFirestore
          .collection("categories")
          .doc(categoryID)
          .collection("sub-categories")
          .get()
          .then((value) {
        for (var element in value.docs) {
          CategoriesAndSubCategoryModel subCategory =
              CategoriesAndSubCategoryModel.fromJson(element.data());
          subCategory.id = element.id;
          subCategory.parentId = categoryID;
          subCategories.add(subCategory);
        }
      });
    } catch (e) {}

    return subCategories;
  }

  Future<void> addSubCategory(String categoryID,
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    await firebaseFirestore
        .collection("categories")
        .doc(categoryID)
        .collection("sub-categories")
        .add(categoriesAndSubCategoryModel.toJson())
        .then((value) {
      print(value.id);
    });
  }

  Future<void> editSubCategories(String categoryID, String subCategoryID,
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    await firebaseFirestore
        .collection("categories")
        .doc(categoryID)
        .collection("sub-categories")
        .doc(subCategoryID)
        .update(categoriesAndSubCategoryModel.toJson())
        .then((value) {
      print("Updated");
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    int subCategoriesLength = 0;
    await firebaseFirestore
        .collection("categories")
        .doc(categoryId)
        .collection("sub-categories")
        .get()
        .then((value) {
      subCategoriesLength = value.docs.length;
    });

    print(subCategoriesLength);

    if (subCategoriesLength == null || subCategoriesLength == 0) {
      firebaseFirestore
          .collection("categories")
          .doc(categoryId)
          .delete()
          .then((value) => print("delete"));
    }
  }

  Future<void> deleteSubCategory(
      String categoryId, String subCategoryId) async {
    List<ProductModel> products = await getProducts(subCategoryId);
    if (products.isEmpty) {
      firebaseFirestore
          .collection("categories")
          .doc(categoryId)
          .collection("sub-categories")
          .doc(subCategoryId)
          .delete()
          .then((value) => print("deleted"));
    }
  }

////
////
////
//////////////////////   <<<<<<<---------   Categories and Sub-Categories  /////////////////
////
////
////

////
////
////
//////////////////////   Products   ------->>>>>>> /////////////////
////
////
////
  Future<List<ProductModel>> getProducts(String subCategoryId) async {
    List<ProductModel> products = [];
    try {
      await firebaseFirestore
          .collection("products")
          .where("subCategoryID", isEqualTo: subCategoryId)
          .get()
          .then((value) {
        for (var element in value.docs) {
          ProductModel product = ProductModel.fromJson(element.data());
          product.id = element.id;
          products.add(product);
          print(element.data().toString());
        }
      });
    } catch (e) {
      print(e.toString());
    }

    return products;
  }

  Future<void> addProduct(ProductModel productModel) async {
    await firebaseFirestore
        .collection("products")
        .add(productModel.toJson())
        .then((value) => print(value.id));
  }

  Future<void> editProduct(ProductModel productModel) async {
    await firebaseFirestore
        .collection("products")
        .doc(productModel.id)
        .update(productModel.toJson())
        .then((value) {
      print("Updated");
    });
  }

  Future<void> deleteProduct(String productId) async {
    await firebaseFirestore
        .collection('products')
        .doc(productId)
        .delete()
        .then((value) => print(productId + " -->deleted"));
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
  Future<List<MaintenanceDeviceModel>> getDevicesInMaintenance(
      String status) async {
    List<MaintenanceDeviceModel> devices = [];
    await firebaseFirestore
        .collection("maintenanceDevices")
        .where("status", isEqualTo: status)
        .get()
        .then((value) {
      for (var element in value.docs) {
        devices.add(MaintenanceDeviceModel.fromJson(element.data()));
      }
    });

    return devices;
  }

  Future<void> addDeviceToMaintenance(
      MaintenanceDeviceModel maintenanceDeviceModel) async {
    await firebaseFirestore
        .collection("maintenanceDevices")
        .doc(maintenanceDeviceModel.id)
        .set(maintenanceDeviceModel.toJson())
        .then((value) => print("new device added"));
  }

  Future<void> editDeviceInMaintenance(
      String deviceID, MaintenanceDeviceModel maintenanceDeviceModel) async {
    await firebaseFirestore
        .collection("maintenanceDevices")
        .doc(deviceID)
        .update(maintenanceDeviceModel.toJson())
        .then((value) {
      print("Updated");
    });
  }

  Future<List<MaintenanceDeviceModel>> checkDeviceStatus(
      String phoneNumber) async {
    List<MaintenanceDeviceModel> devices = [];

    try {
      await firebaseFirestore
          .collection("maintenanceDevices")
          .where("phoneNumber", isEqualTo: phoneNumber)
          .get()
          .then((value) {
        for (var element in value.docs) {
          devices.add(MaintenanceDeviceModel.fromJson(element.data()));
        }
      });
    } catch (e) {}

    return devices;
  }

////
////
////
//////////////////////   <<<<<<<---------   Maintenance  /////////////////

////
////
//////////////////////   Favorites   ------->>>>>>> /////////////////
////
////
////

  Future<List<ProductModel>> getFavorites() async {
    List<ProductModel> products = [];
    try {
      await firebaseFirestore
          .collection("products")
          .where("favoriteList", arrayContains: firebaseAuth.currentUser!.uid)
          .get()
          .then((value) {
        for (var element in value.docs) {
          products.add(ProductModel.fromJson(element.data()));
          print(element.data().toString());
        }
      });
    } catch (e) {
      print(e.toString());
    }

    return products;
  }

  Future<void> updateFavorites(
      String productID, List<String> favoriteList) async {
    try {
      await firebaseFirestore
          .collection("products")
          .doc(productID)
          .update({"favoriteList": favoriteList}).then((value) {
        print("Updated");
      });
    } catch (e) {}
  }

////
////
////
////
//////////////////////   <<<<<<<---------   Favorites  /////////////////
////
////

////
////
//////////////////////   Brands   ------->>>>>>> /////////////////
////
////
////

  Future<List<BrandModel>> getBrands() async {
    List<BrandModel> brands = [];
    try {
      await firebaseFirestore.collection("brands").get().then((value) {
        for (var element in value.docs) {
          brands.add(BrandModel.fromJson(element.data()));
          print(element.data().toString());
        }
      });
    } catch (e) {
      print(e.toString());
    }

    return brands;
  }

  Future<BrandModel> getBrand(String brandID) async {
    late BrandModel brand;
    try {
      await firebaseFirestore
          .collection("brands")
          .where('name', isEqualTo: brandID)
          .get()
          .then((value) {
        brand = BrandModel.fromJson(value.docs.first.data());
      });
    } catch (e) {
      print(e.toString());
    }

    return brand;
  }

////
////
////
//////////////////////   <<<<<<<---------   Brands  /////////////////

}
