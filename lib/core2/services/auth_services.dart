import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:techno_store/core2/model/user_data.dart';
import 'package:techno_store/core2/services/cache_services.dart';
import 'package:techno_store/core2/services/firebase_storage_services.dart';
import 'package:techno_store/core2/services/firestore_services.dart';
import 'package:techno_store/core2/utils/storage_api_path.dart';

class AuthServices {
  final firebaseAuth = FirebaseAuth.instance;
  final firestoreServices = FirestoreServices.instance;
  final firebaseStorageServices = FirebaseStorageServices.instance;
  final cacheServices = CacheServices();

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    debugPrint(userCredential.user.toString());
    if (userCredential.user != null) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> signUpWithEmailAndPassword(
    String email,
    String password,
    String? photo,
    String? displayName,
    int? type,
  ) async {
    final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);

    if (userCredential.user != null) {
      if (photo != null && photo.isNotEmpty) {
        photo = await firebaseStorageServices.uploadFile(
          file: File(photo),
          folderPath: StorageApiPath.profilesPhotos(),
        );
      }
      final userData = UserData(
        uid: userCredential.user!.uid,
        email: email,
        photoURL: photo,
        name: displayName,
        type: type ?? 1,
      );
      await firestoreServices.saveUserData(
        userData,
      );
      return true;
    } else {
      return false;
    }
  }

  User? get currentUser {
    return firebaseAuth.currentUser;
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
    await cacheServices.clear();
  }

  Future<bool> resetPassword(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      debugPrint('Error resetting password: $e');
      return false;
    }
  }
}
