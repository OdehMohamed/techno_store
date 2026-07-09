/// Per-platform version gate info parsed from one platform entry of
/// `appConfig/global`. All fields are nullable — an absent or malformed
/// document parses to all-null fields, which callers must treat as "no
/// forced update" (fail open), never as an error.
class PlatformVersionInfo {
  final String? minRequiredVersion;
  final String? latestVersion; // reserved for a future soft-update nudge
  final String? storeIdentifier; // Android packageId or iOS appStoreId

  const PlatformVersionInfo({
    this.minRequiredVersion,
    this.latestVersion,
    this.storeIdentifier,
  });

  factory PlatformVersionInfo.fromMap(
    Map<String, dynamic>? map, {
    required String storeIdKey,
  }) {
    if (map == null) return const PlatformVersionInfo();
    return PlatformVersionInfo(
      minRequiredVersion: map['minRequiredVersion'] as String?,
      latestVersion: map['latestVersion'] as String?,
      storeIdentifier: map[storeIdKey] as String?,
    );
  }
}

/// Parses `appConfig/global` — see
/// docs/ai-workflow/FORCED_UPDATE_IMPLEMENTATION_PLAN.md. Only the `version`
/// key is read today; `maintenance`/`featureFlags` are reserved for later
/// and deliberately not modeled here yet.
class AppConfigModel {
  final PlatformVersionInfo android;
  final PlatformVersionInfo ios;

  const AppConfigModel({
    required this.android,
    required this.ios,
  });

  factory AppConfigModel.fromMap(Map<String, dynamic>? map) {
    final versionMap = map?['version'] as Map<String, dynamic>?;
    return AppConfigModel(
      android: PlatformVersionInfo.fromMap(
        versionMap?['android'] as Map<String, dynamic>?,
        storeIdKey: 'packageId',
      ),
      ios: PlatformVersionInfo.fromMap(
        versionMap?['ios'] as Map<String, dynamic>?,
        storeIdKey: 'appStoreId',
      ),
    );
  }
}
