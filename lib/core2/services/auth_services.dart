import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

  Future<String> signInWithPhoneNumber(String phoneNumber) async {
    // ✅ للويب: استخدام RecaptchaVerifier
    if (kIsWeb) {
      try {
        final confirmationResult =
            await firebaseAuth.signInWithPhoneNumber(phoneNumber);
        debugPrint('✅ Web: Code sent successfully');
        // حفظ confirmationResult للاستخدام لاحقاً
        return confirmationResult.verificationId;
      } catch (e) {
        debugPrint('❌ Web Error: $e');
        rethrow;
      }
    }

    // ✅ للموبايل (Android/iOS): الطريقة العادية
    final completer = Completer<String>();
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 120),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // ANDROID ONLY!
        // Sign the user in (or link) with the auto-generated credential
        await firebaseAuth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('❌ Verification failed: ${e.code} - ${e.message}');
        completer.completeError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) async {
        debugPrint('✅ Code sent: $verificationId');
        completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('⏱️ Auto retrieval timeout');
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );
    final verifyId = await completer.future;
    debugPrint("✅ Verification ID: $verifyId");
    return verifyId;
  }

  Future<UserCredential> verifySMSCode(String verifyId, String smsCode) async {
    debugPrint('🔐 Verifying code: $smsCode');
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verifyId,
      smsCode: smsCode,
    );
    final userCredential = await firebaseAuth.signInWithCredential(credential);
    debugPrint('✅ Sign in successful: ${userCredential.user?.uid}');

    return userCredential;
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

  Future<bool> completeUserProfile({
    required String name,
    required String nickname,
    String? photoURL,
    required String location,
  }) async {
    try {
      if (photoURL != null && photoURL.isNotEmpty) {
        photoURL = await firebaseStorageServices.uploadFile(
          file: File(photoURL),
          folderPath: StorageApiPath.profilesPhotos(),
        );
      }
      final userData = UserData(
        uid: firebaseAuth.currentUser!.uid,
        location: location,
        nickname: nickname,
        name: name,
        photoURL: photoURL,
        type: 1,
      );
      await firestoreServices.saveUserData(
        userData,
      );
      return true;
    } catch (e) {
      debugPrint('❌ Error completing profile: $e');
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
