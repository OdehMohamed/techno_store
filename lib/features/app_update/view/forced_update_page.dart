import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:techno_store/core/model/app_config_model.dart';
import 'package:techno_store/core/utils/app_colors.dart';
import 'package:techno_store/core/widgets/main_button.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dedicated full-screen, non-dismissable block shown when
/// AppUpdateCubit emits AppUpdateForceRequired. Deliberately not a dialog:
/// no back-button escape, no barrier-tap dismiss, no cancel affordance —
/// see docs/ai-workflow/FORCED_UPDATE_IMPLEMENTATION_PLAN.md §8.
class ForcedUpdatePage extends StatelessWidget {
  final PlatformVersionInfo platformInfo;

  const ForcedUpdatePage({super.key, required this.platformInfo});

  String? get _storeUrl {
    final storeId = platformInfo.storeIdentifier;
    if (storeId == null || storeId.isEmpty) return null;
    if (kIsWeb) return null;
    if (Platform.isAndroid) {
      return 'https://play.google.com/store/apps/details?id=$storeId';
    }
    if (Platform.isIOS) {
      return 'https://apps.apple.com/app/id$storeId';
    }
    return null;
  }

  Future<void> _openStore() async {
    final url = _storeUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('❌ Error opening store URL for forced update: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeUrl = _storeUrl;
    return PopScope(
      // Non-dismissable: no back-button escape from this page.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.system_update_rounded,
                  size: 96,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  'Update Required'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'A new version of this app is required to continue. Please update to the latest version to keep using the app.'
                      .tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                if (storeUrl != null)
                  MainButton(
                    label: 'Update Now',
                    onPressed: _openStore,
                  )
                else
                  Text(
                    'Please check back later for the update.'.tr(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.red),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
