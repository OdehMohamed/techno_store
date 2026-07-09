import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:techno_store/core/model/app_config_model.dart';
import 'package:techno_store/core/services/firestore_services.dart';
import 'package:techno_store/core/utils/firestore_api_path.dart';

class AppUpdateService {
  AppUpdateService._();

  static final instance = AppUpdateService._();

  final _firestoreServices = FirestoreServices.instance;

  /// Fetches `appConfig/global`. Returns null on any failure (offline,
  /// permission error, missing document) — callers MUST treat null the same
  /// as "no forced update needed" (fail open), per
  /// docs/ai-workflow/FORCED_UPDATE_IMPLEMENTATION_PLAN.md §4. The error is
  /// logged here; it must never be used to block the app.
  Future<AppConfigModel?> fetchAppConfig() async {
    try {
      final data = await _firestoreServices.getDocumentOrNull(
        path: FirestoreApiPath.appConfig(),
      );
      return AppConfigModel.fromMap(data);
    } catch (e) {
      debugPrint(
          '❌ Error fetching appConfig/global (failing open — no update will be forced): $e');
      return null;
    }
  }

  PlatformVersionInfo? _currentPlatformInfo(AppConfigModel config) {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return config.android;
    if (Platform.isIOS) return config.ios;
    return null;
  }

  /// True only if the installed app version is below this platform's
  /// configured minimum. Any missing config, missing platform entry,
  /// missing minimum version, or version-parsing failure returns false —
  /// fails open, never blocks on an inability to determine the answer.
  Future<bool> isForceUpdateRequired(AppConfigModel? config) async {
    if (config == null) return false;

    final platformInfo = _currentPlatformInfo(config);
    final minRequired = platformInfo?.minRequiredVersion;
    if (platformInfo == null || minRequired == null) return false;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final installed = Version.parse(packageInfo.version);
      final minimum = Version.parse(minRequired);
      return installed < minimum;
    } catch (e) {
      debugPrint(
          '❌ Error comparing app version (failing open — no update will be forced): $e');
      return false;
    }
  }
}
