import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techno_store/core/model/user_data.dart';
import 'package:techno_store/core/services/auth_services.dart';
import 'package:techno_store/core/services/cache_services.dart';
import 'package:techno_store/core/services/firestore_services.dart';
import 'package:techno_store/core/utils/firestore_api_path.dart';
import 'package:techno_store/core/utils/user_role.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial()) {
    _loadPendingVerification();
  }

  final AuthServices _authServices = AuthServices();
  final FirestoreServices _firestoreServices = FirestoreServices.instance;
  final cacheServices = CacheServices();

  // Staff-only: live-session enforcement, started after a successful staff
  // sign-in (fresh or restored). Never started for customers — this whole
  // mechanism doesn't apply to the phone-OTP path. See ADR-004's "Staff
  // Status Architecture Pass".
  StreamSubscription<Map<String, dynamic>?>? _staffStatusSubscription;
  StreamSubscription<Map<String, dynamic>?>? _staffRoleSubscription;

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

  /// Staff-only sign-in. Email/password is deliberately never used by
  /// customers (phone-OTP only) — see docs/product/PRD.md, Auth & Account
  /// Lifecycle. Enforces staff status here, not just at the UI layer:
  /// wrong account type, an unverifiable status, or a confirmed-inactive
  /// status are all rejected and signed out before AuthSuccess is ever
  /// emitted, never granted provisionally.
  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      await _authServices.signInWithEmailAndPassword(email, password);

      final userData = await _authServices.fetchCurrentUserData();
      if (userData == null) {
        await _authServices.signOut();
        emit(AuthFailure('Could not load your account. Please try again.'));
        return;
      }

      if (!UserRole.isStaff(userData.type)) {
        await _authServices.signOut();
        emit(AuthFailure('This sign-in is for staff accounts only.'));
        return;
      }

      final isActive = await _fetchStaffIsActive(userData.uid);
      if (isActive == null) {
        await _authServices.signOut();
        emit(AuthFailure(
          'Could not verify your account status. Please try again.',
        ));
        return;
      }
      if (!isActive) {
        await _authServices.signOut();
        emit(AuthFailure(
          'Your account has been deactivated. Contact your administrator.',
        ));
        return;
      }

      _watchStaffSession(userData.uid, userData.type);
      emit(AuthSuccess(userData));
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Staff sign-in Firebase error: ${e.code} - ${e.message}');
      emit(AuthFailure(_staffSignInErrorMessage(e)));
    } catch (error) {
      debugPrint('💥 Unexpected staff sign-in error: $error');
      emit(AuthFailure('An unexpected error occurred: $error'));
    }
  }

  String _staffSignInErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password';
      case 'too-many-requests':
        return 'Too many attempts, please try again later';
      case 'network-request-failed':
        return 'Network error, please check your connection';
      default:
        return e.message ?? 'An error occurred while signing in';
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

      // Linking any maintenance devices already received under this phone
      // number to the new account is handled server-side (Cloud Function,
      // triggered on users/{uid} creation) — see functions/index.js. The
      // client can no longer perform this itself: it requires a Firestore
      // query staff-only rules deny to a customer (matching by phoneNumber
      // rather than the caller's own uid) and a write to maintenanceDevices,
      // which is staff-only.
      // ✅ حذف حالة "إكمال الملف الشخصي" المعلقة
      await _deletePendingProfileCompletion();
      // Load the freshly created profile before signalling success so that
      // AuthSuccess always carries populated user data. MainScreen reads
      // state.userData on AuthSuccess; emitting it empty here caused a null
      // dereference (main_screen.dart) on the profile-completion path.
      final userData = await _authServices.fetchCurrentUserData();
      emit(userData != null ? AuthSuccess(userData) : AuthInitial());
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
    await _stopStaffSessionWatch();
    emit(LoggingOut());
    try {
      await _authServices.signOut();
      emit(AuthInitial());
    } catch (error) {
      emit(AuthFailure(error.toString()));
    }
  }

  /// Restores a session on app start. Staff status is re-verified here too
  /// — not just at fresh sign-in — since an account could have been
  /// deactivated while the app was closed. Fails closed on an unverifiable
  /// status, same as signIn.
  Future<void> checkAuth() async {
    final userData = await _authServices.fetchCurrentUserData();
    if (userData == null) {
      emit(AuthInitial());
      return;
    }

    if (UserRole.isStaff(userData.type)) {
      final isActive = await _fetchStaffIsActive(userData.uid);
      if (isActive == null) {
        await _authServices.signOut();
        emit(AuthFailure(
          'Could not verify your account status. Please sign in again.',
        ));
        return;
      }
      if (!isActive) {
        await _authServices.signOut();
        emit(AuthFailure(
          'Your account has been deactivated. Contact your administrator.',
        ));
        return;
      }
      _watchStaffSession(userData.uid, userData.type);
    }

    emit(AuthSuccess(userData));
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

  /// Fails closed: an absent staffStatus document, one without an explicit
  /// "active" value, or a read failure are all treated as not-active.
  /// Returns null specifically when the read itself failed, so callers can
  /// distinguish "confirmed inactive" from "couldn't verify" in their
  /// messaging — both still deny access, but for different reasons.
  Future<bool?> _fetchStaffIsActive(String uid) async {
    try {
      final data = await _firestoreServices.getDocumentOrNull(
        path: FirestoreApiPath.staffStatus(uid),
      );
      return data?['status'] == 'active';
    } catch (e) {
      debugPrint('❌ Error fetching staff status for $uid: $e');
      return null;
    }
  }

  /// Live-session enforcement for an already-signed-in staff account. Two
  /// independent listeners — status lives under users/{uid}/meta, role
  /// lives on users/{uid} itself, so one stream can't cover both. Each
  /// reacts only to an actual received value; a stream error (temporary
  /// network interruption) is deliberately ignored, not treated as a
  /// reason to sign out — see ADR-004's fail-open/fail-closed split.
  void _watchStaffSession(String uid, int roleAtSignIn) {
    _staffStatusSubscription?.cancel();
    _staffRoleSubscription?.cancel();

    _staffStatusSubscription = _firestoreServices
        .documentsStream(
      path: FirestoreApiPath.staffStatus(uid),
      builder: (data, documentID) => data,
    )
        .listen(
      (data) async {
        final isActive = data?['status'] == 'active';
        if (!isActive) {
          emit(AuthStaffDeactivated());
          await signOut();
        }
      },
      onError: (e) => debugPrint(
        '⚠️ Staff status listener error (ignored, no forced sign-out): $e',
      ),
    );

    _staffRoleSubscription = _firestoreServices
        .documentsStream(
      path: FirestoreApiPath.user(uid),
      builder: (data, documentID) => data,
    )
        .listen(
      (data) async {
        final currentType = data?['type'] as int?;
        if (currentType != null && currentType != roleAtSignIn) {
          emit(AuthStaffRoleChanged());
          await signOut();
        }
      },
      onError: (e) => debugPrint(
        '⚠️ Staff role listener error (ignored, no forced sign-out): $e',
      ),
    );
  }

  Future<void> _stopStaffSessionWatch() async {
    await _staffStatusSubscription?.cancel();
    await _staffRoleSubscription?.cancel();
    _staffStatusSubscription = null;
    _staffRoleSubscription = null;
  }
}
