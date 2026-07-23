part of 'auth_cubit.dart';

sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthSuccess extends AuthState {
  UserData? userData;

  AuthSuccess([this.userData]);
}

final class AuthFailure extends AuthState {
  final String error;

  AuthFailure(this.error);
}

// Live-session enforcement (staff only) — transient states, always
// followed immediately by signOut()'s LoggingOut/AuthInitial. Kept
// distinct from each other so MainScreen can show a different message
// for each, and deliberately not named after the old, dead
// AuthNeedActivation — a new concept (staffStatus), not a revival.
final class AuthStaffDeactivated extends AuthState {}

final class AuthStaffRoleChanged extends AuthState {}

final class LoggingOut extends AuthState {}

final class PasswordSecretChanged extends AuthState {
  final bool isSecret;

  PasswordSecretChanged(this.isSecret);
}

final class PasswordResetLoading extends AuthState {}

final class PasswordResetFailure extends AuthState {
  final String error;
  PasswordResetFailure(this.error);
}

final class PasswordResetSuccess extends AuthState {}

final class VerifyAuthLoading extends AuthState {}

final class VerifyAuthSuccess extends AuthState {
  UserData? userData;
  VerifyAuthSuccess([this.userData]);
}

final class VerifyAuthFailure extends AuthState {
  final String error;
  VerifyAuthFailure(this.error);
}

final class AuthSendCodeLoading extends AuthState {}

final class AuthSendCodeSuccess extends AuthState {
  final String verifyId;
  AuthSendCodeSuccess(this.verifyId);
}

final class AuthSendCodeFailure extends AuthState {
  final String error;
  AuthSendCodeFailure(this.error);
}

// ✅ حالة جديدة لاستعادة التحقق المعلق
final class AuthRestoredPendingVerification extends AuthState {
  final String verifyId;
  final String phoneNumber;
  AuthRestoredPendingVerification(this.verifyId, this.phoneNumber);
}

// ✅ حالة جديدة: المستخدم يحتاج لإكمال ملفه الشخصي
final class AuthNeedsProfileCompletion extends AuthState {
  final String uid;
  final String phoneNumber;
  AuthNeedsProfileCompletion(this.uid, this.phoneNumber);
}
