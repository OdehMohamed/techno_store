import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techno_store/core2/model/user_data.dart';
import 'package:techno_store/core2/services/auth_services.dart';
import 'package:techno_store/core2/services/cache_services.dart';
import 'package:techno_store/core2/services/firestore_services.dart';
import 'package:techno_store/core2/utils/firestore_api_path.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial()) {
    _loadPendingVerification();
  }

  final AuthServices _authServices = AuthServices();
  final FirestoreServices _firestoreServices = FirestoreServices.instance;
  final cacheServices = CacheServices();
  StreamSubscription<Map<String, dynamic>>? _activationSubscription;

  // download the saved state on app start
  Future<void> _loadPendingVerification() async {
    final pref = await SharedPreferences.getInstance();

    // ✅ أولاً: التحقق من وجود حالة "إكمال الملف الشخصي" معلقة
    final pendingUid = pref.getString(_pendingProfileUidKey);
    final pendingPhone = pref.getString(_pendingProfilePhoneKey);

    if (pendingUid != null && pendingPhone != null) {
      debugPrint('📝 Found pending profile completion for: $pendingPhone');
      emit(AuthNeedsProfileCompletion(pendingUid, pendingPhone));
      return; // إيقاف البحث عن حالات أخرى
    }

    // ثانياً: التحقق من وجود حالة "التحقق من الكود" معلقة
    final verificationId = pref.getString(_verificationIdKey);
    final phoneNumber = pref.getString(_phoneNumberKey);

    if (verificationId != null && phoneNumber != null) {
      debugPrint('📲 Found pending verification for: $phoneNumber');
      await _deletePendingVerification();
      emit(AuthRestoredPendingVerification(verificationId, phoneNumber));
    }
  }

  Future<void> _deletePendingVerification() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_verificationIdKey);
    await pref.remove(_phoneNumberKey);
  }

  Future<void> _savePendingProfileCompletion(
      String uid, String phoneNumber) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString(_pendingProfileUidKey, uid);
    await pref.setString(_pendingProfilePhoneKey, phoneNumber);
    debugPrint('💾 Saved pending profile completion state');
  }

  Future<void> _deletePendingProfileCompletion() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove(_pendingProfileUidKey);
    await pref.remove(_pendingProfilePhoneKey);
    debugPrint('🗑️ Deleted pending profile completion state');
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      bool isAuthenticated =
          await _authServices.signInWithEmailAndPassword(email, password);

      debugPrint(isAuthenticated.toString());

      emit(AuthSuccess());
    } catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }

  // Storage keys
  static const String _verificationIdKey = 'pending_verification_id';
  static const String _phoneNumberKey = 'pending_phone_number';
  static const String _pendingProfileUidKey = 'pending_profile_uid';
  static const String _pendingProfilePhoneKey = 'pending_profile_phone';

  Future<void> signInWithPhone(String phoneNumber) async {
    emit(AuthSendCodeLoading());
    try {
      debugPrint('📱 Sending code to: $phoneNumber');
      final verifyId = await _authServices.signInWithPhoneNumber(phoneNumber);
      debugPrint('✅ Code sent, verifyId: $verifyId');

      final pref = await SharedPreferences.getInstance();
      await pref.setString(_verificationIdKey, verifyId);
      await pref.setString(_phoneNumberKey, phoneNumber);

      emit(AuthSendCodeSuccess(verifyId));
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Error: ${e.code} - ${e.message}');
      String errorMessage;

      switch (e.code) {
        case 'invalid-phone-number':
          errorMessage = 'Invalid phone number';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests, please try again later';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Phone Authentication service is not enabled';
          break;
        default:
          errorMessage =
              e.message ?? 'An error occurred while sending the code';
      }

      emit(AuthSendCodeFailure(errorMessage));
    } catch (e) {
      debugPrint('💥 Unexpected Error: $e');
      emit(
          AuthSendCodeFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> verifySMSCode(String verifyId, String smsCode) async {
    emit(VerifyAuthLoading());
    try {
      debugPrint('🔐 Verifying code: $smsCode with ID: $verifyId');

      final userCredential =
          await _authServices.verifySMSCode(verifyId, smsCode);

      if (userCredential.user != null) {
        debugPrint('✅ User signed in: ${userCredential.user!.uid}');

        await _deletePendingVerification();

        emit(VerifyAuthSuccess());
        await Future.delayed(const Duration(milliseconds: 500));

        // ✅ التحقق من بيانات المستخدم في Firestore
        try {
          final userData = await _firestoreServices.getDocument<UserData?>(
            path: FirestoreApiPath.user(userCredential.user!.uid),
            builder: (data, documentID) => UserData.fromMap(data, documentID),
          );

          if (userData == null ||
              userData.name == null ||
              userData.name!.isEmpty) {
            // ✅ المستخدم جديد أو لا يوجد له بيانات
            debugPrint('⚠️ User needs to complete profile');
            // ✅ حفظ الحالة في SharedPreferences
            await _savePendingProfileCompletion(
              userCredential.user!.uid,
              userCredential.user!.phoneNumber ?? '',
            );
            emit(AuthNeedsProfileCompletion(
              userCredential.user!.uid,
              userCredential.user!.phoneNumber ?? '',
            ));
          } else {
            // ✅ المستخدم لديه بيانات كاملة
            debugPrint('✅ User has complete profile');
            emit(AuthSuccess(userData));
          }
        } catch (e) {
          // إذا فشل جلب البيانات، افترض أنه مستخدم جديد
          debugPrint('⚠️ Error fetching user data: $e');
          // ✅ حفظ الحالة في SharedPreferences
          await _savePendingProfileCompletion(
            userCredential.user!.uid,
            userCredential.user!.phoneNumber ?? '',
          );
          emit(AuthNeedsProfileCompletion(
            userCredential.user!.uid,
            userCredential.user!.phoneNumber ?? '',
          ));
        }
      } else {
        emit(VerifyAuthFailure('Code verification failed'));
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Error: ${e.code} - ${e.message}');
      String errorMessage;

      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'The entered code is incorrect';
          break;
        case 'session-expired':
          errorMessage = 'The code has expired, please request a new one';
          // ✅ Clear expired data
          final pref = await SharedPreferences.getInstance();
          await pref.remove(_verificationIdKey);
          await pref.remove(_phoneNumberKey);
          break;
        case 'invalid-verification-id':
          errorMessage = 'Invalid verification ID';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during verification';
      }

      emit(VerifyAuthFailure(errorMessage));
    } catch (e) {
      debugPrint('💥 Unexpected Error: $e');
      emit(VerifyAuthFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> cancelPhoneVerification() async {
    await _deletePendingVerification();
    emit(AuthInitial());
  }

  // ✅ حفظ بيانات المستخدم بعد إكمال الملف الشخصي
  Future<void> completeUserProfile({
    required String name,
    required String nickname,
    String? photo,
    required String location,
  }) async {
    emit(AuthLoading());
    try {
      bool isCompleted = await _authServices.completeUserProfile(
        name: name,
        nickname: nickname,
        photoURL: photo,
        location: location,
      );
      if (!isCompleted) {
        emit(AuthFailure('Failed to complete user profile'));
        return;
      }
      // ✅ حذف حالة "إكمال الملف الشخصي" المعلقة
      await _deletePendingProfileCompletion();
      emit(AuthSuccess());
    } catch (error) {
      debugPrint(error.toString());
      emit(AuthFailure(error.toString()));
    }
  }

  // Future<void> signUp(
  //   String email,
  //   String password,
  //   String? photo,
  //   String? displayName,
  //   int? type,
  // ) async {
  //   emit(AuthLoading());
  //   try {
  //     bool isRegistered = await _authServices.signUpWithEmailAndPassword(
  //       email,
  //       password,
  //       photo,
  //       displayName,
  //       type,
  //     );
  //     if (!isRegistered) {
  //       emit(AuthFailure('Failed to register user'));
  //       return;
  //     }
  //     emit(AuthSuccess());
  //   } catch (error) {
  //     debugPrint(error.toString());
  //     emit(AuthFailure(error.toString()));
  //   }
  // }

  Future<void> signOut() async {
    emit(LoggingOut());
    try {
      await _authServices.signOut();
      emit(AuthInitial());
    } catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }

  void checkAuth() {
    final user = _authServices.currentUser;
    if (user != null) {
      emit(AuthSuccess());
    } else {
      emit(AuthInitial());
    }
  }

  void passwordSecretChanged(bool isSecret) {
    emit(PasswordSecretChanged(isSecret));
  }

  Future<void> resetPassword(String email) async {
    emit(PasswordResetLoading());
    try {
      await _authServices.resetPassword(email);
      emit(PasswordResetSuccess());
    } catch (error) {
      emit(PasswordResetFailure(error.toString()));
    }
  }

  void _listenToActivation([UserData? userData]) async {
    await _activationSubscription?.cancel();
    final uid = _authServices.currentUser!.uid;
    _activationSubscription = _firestoreServices
        .documentsStream(
      path: FirestoreApiPath.userMeta(uid),
      builder: (data, documentID) => data!,
    )
        .listen((data) async {
      debugPrint('Activation data: $data');
      if (data['isActivated'] != true) {
        emit(AuthNeedActivation());
        await signOut();
      } else {
        if (userData != null) {
          emit(AuthSuccess(userData));
        } else {
          emit(AuthSuccess());
        }
      }
    });
  }
}
