import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
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

  Future<bool> signIn(String email, String password) async {
    try {
      await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password)
          .then((value) => print(value.user?.email));

      return true;
    } on FirebaseAuthException catch (e) {
      Message.showErrorToastMessage(e.message.toString());
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
  }

  Future<bool> signUp(String email, String password,
      CreateUserAccountModel createUserAccountModel) async {
    try {
      await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password)
          .then((value) => saveUserInfo(createUserAccountModel));

      return true;
    } on FirebaseAuthException catch (e) {
      Message.showErrorToastMessage(e.message.toString());
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
  }

  Future<bool> sinUpByAdmin(String email, String password,
      CreateUserAccountModel createUserAccountModel) async {
    bool response = true;

    FirebaseApp app = await Firebase.initializeApp(
        name: 'Secondary', options: Firebase.app().options);
    try {
      await FirebaseAuth.instanceFor(app: app)
          .createUserWithEmailAndPassword(email: email, password: password)
          .then((value) =>
              saveUserInfo(createUserAccountModel, uid: value.user?.uid));
    } on FirebaseAuthException catch (e) {
      Message.showErrorToastMessage(e.message.toString());
      response = false;
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
      response = false;
    }

    await app.delete();

    return response;
  }

  Future<bool> signOut() async {
    try {
      await firebaseAuth.signOut();

      return true;
    } on FirebaseAuthException catch (e) {
      Message.showErrorToastMessage(e.message.toString());
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
  }

  Future<bool> resetPassword(String email) async {
    try {
      await firebaseAuth
          .sendPasswordResetEmail(email: email)
          .onError((error, stackTrace) => print(error));

      return true;
    } on FirebaseAuthException catch (e) {
      Message.showErrorToastMessage(e.message.toString());
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
  }

  Future<bool> sendEmailVerification() async {
    try {
      await firebaseAuth.currentUser?.sendEmailVerification();

      return true;
    } on FirebaseAuthException catch (e) {
      Message.showErrorToastMessage(e.message.toString());
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
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

  Future<bool> saveUserInfo(CreateUserAccountModel createUserAccountModel,
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

      return true;
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
  }

  Future<CreateUserAccountModel?> getUserInfo(String uid) async {
    CreateUserAccountModel? createUserAccountModel;
    try {
      await firebaseFirestore.collection("users").doc(uid).get().then((value) {
        createUserAccountModel = CreateUserAccountModel.fromJson(value.data()!);
      });
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

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

  Future<String?> uploadPhoto(String photo) async {
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
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return null;
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
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return categories;
  }

  Future<bool> addCategory(
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    try {
      await firebaseFirestore
          .collection("categories")
          .add(categoriesAndSubCategoryModel.toJson())
          .then((value) => print(value.id));

      return true;
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
  }

  Future<bool> editCategory(String categoryID,
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    try {
      await firebaseFirestore
          .collection("categories")
          .doc(categoryID)
          .update(categoriesAndSubCategoryModel.toJson())
          .then((value) => print("Updated"));

      return true;
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
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
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return subCategories;
  }

  Future<bool> addSubCategory(String categoryID,
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    try {
      await firebaseFirestore
          .collection("categories")
          .doc(categoryID)
          .collection("sub-categories")
          .add(categoriesAndSubCategoryModel.toJson())
          .then((value) {
        print(value.id);
      });

      return true;
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
  }

  Future<bool> editSubCategories(String categoryID, String subCategoryID,
      CategoriesAndSubCategoryModel categoriesAndSubCategoryModel) async {
    try {
      await firebaseFirestore
          .collection("categories")
          .doc(categoryID)
          .collection("sub-categories")
          .doc(subCategoryID)
          .update(categoriesAndSubCategoryModel.toJson())
          .then((value) {
        print("Updated");
      });

      return true;
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
  }

  Future<bool> deleteCategory(String categoryId) async {
    try {
      int subCategoriesLength = 0;
      await firebaseFirestore
          .collection("categories")
          .doc(categoryId)
          .collection("sub-categories")
          .get()
          .then((value) {
        subCategoriesLength = value.docs.length;
      });

      if (subCategoriesLength == null || subCategoriesLength == 0) {
        firebaseFirestore
            .collection("categories")
            .doc(categoryId)
            .delete()
            .then((value) => print("delete"));

        return true;
      } else {
        Message.showErrorToastMessage("subCategoryMustBeEmpty".tr());
        return false;
      }
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
  }

  Future<bool> deleteSubCategory(
      String categoryId, String subCategoryId) async {
    try {
      List<ProductModel> products = await getProducts(subCategoryId);
      if (products.isEmpty) {
        firebaseFirestore
            .collection("categories")
            .doc(categoryId)
            .collection("sub-categories")
            .doc(subCategoryId)
            .delete()
            .then((value) => print("deleted"));

        return true;
      } else {
        Message.showErrorToastMessage("thereAreProductsInSubCategory".tr());
        return false;
      }
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
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
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return products;
  }

  Future<bool> addProduct(ProductModel productModel) async {
    try {
      await firebaseFirestore.collection("products").add(productModel.toJson());

      return true;
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
  }

  Future<bool> editProduct(ProductModel productModel) async {
    try {
      await firebaseFirestore
          .collection("products")
          .doc(productModel.id)
          .update(productModel.toJson());

      return true;
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await firebaseFirestore.collection('products').doc(productId).delete();
      return true;
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
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

    try {
      await firebaseFirestore
          .collection("maintenanceDevices")
          .where("status", isEqualTo: status)
          .get()
          .then((value) async {
        for (var element in value.docs) {
          MaintenanceDeviceModel? maintenanceDeviceModel =
              MaintenanceDeviceModel.fromJson(element.data());
          if (maintenanceDeviceModel.brandID != null) {
            maintenanceDeviceModel.brandModel =
                await getBrand(maintenanceDeviceModel.brandID!);
          }
          devices.add(maintenanceDeviceModel);
        }
      });
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return devices;
  }

  Future<bool> addDeviceToMaintenance(
      MaintenanceDeviceModel maintenanceDeviceModel) async {
    try {
      await firebaseFirestore
          .collection("maintenanceDevices")
          .doc(maintenanceDeviceModel.id)
          .set(maintenanceDeviceModel.toJson());
      return true;
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
  }

  Future<bool> editDeviceInMaintenance(
      String deviceID, MaintenanceDeviceModel maintenanceDeviceModel) async {
    try {
      await firebaseFirestore
          .collection("maintenanceDevices")
          .doc(deviceID)
          .update(maintenanceDeviceModel.toJson());
      return true;
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
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
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

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
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return products;
  }

  Future<bool> updateFavorites(
      String productID, List<String> favoriteList) async {
    try {
      await firebaseFirestore
          .collection("products")
          .doc(productID)
          .update({"favoriteList": favoriteList});

      return true;
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return false;
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
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return brands;
  }

  Future<BrandModel?> getBrand(String brandID) async {
    BrandModel? brand;
    try {
      await firebaseFirestore
          .collection("brands")
          .where('name', isEqualTo: brandID)
          .get()
          .then((value) {
        brand = BrandModel.fromJson(value.docs.first.data());
      });
    } catch (e) {
      Message.showErrorToastMessage("somethingWentWrong".tr());
    }

    return brand;
  }

////
////
////
//////////////////////   <<<<<<<---------   Brands  /////////////////

}
