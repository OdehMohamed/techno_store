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

final class AuthNeedActivation extends AuthState {}

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
