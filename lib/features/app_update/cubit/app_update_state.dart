part of 'app_update_cubit.dart';

sealed class AppUpdateState {}

final class AppUpdateInitial extends AppUpdateState {}

final class AppUpdateLoading extends AppUpdateState {}

final class AppUpdateUpToDate extends AppUpdateState {}

/// The installed version is below this platform's configured minimum.
/// Carries the platform's store identifier so the blocking page can build
/// the correct store link without re-fetching or re-deriving anything.
final class AppUpdateForceRequired extends AppUpdateState {
  final PlatformVersionInfo platformInfo;

  AppUpdateForceRequired({required this.platformInfo});
}
