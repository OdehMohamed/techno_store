import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core2/model/user_data.dart';
import 'package:techno_store/core2/services/auth_services.dart';
import 'package:techno_store/core2/services/cache_services.dart';
import 'package:techno_store/core2/services/firestore_services.dart';
import 'package:techno_store/core2/utils/firestore_api_path.dart';
part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());
  final AuthServices _authServices = AuthServices();
  final FirestoreServices _firestoreServices = FirestoreServices.instance;
  final cacheServices = CacheServices();
  StreamSubscription<Map<String, dynamic>>? _activationSubscription;

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

  Future<void> signUp(
    String email,
    String password,
    String? photo,
    String? displayName,
    int? type,
  ) async {
    emit(AuthLoading());
    try {
      bool isRegistered = await _authServices.signUpWithEmailAndPassword(
        email,
        password,
        photo,
        displayName,
        type,
      );
      if (!isRegistered) {
        emit(AuthFailure('Failed to register user'));
        return;
      }
      emit(AuthSuccess());
    } catch (error) {
      debugPrint(error.toString());
      emit(AuthFailure(error.toString()));
    }
  }

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
