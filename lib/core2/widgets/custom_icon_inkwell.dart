import 'package:flutter/material.dart';
import 'package:techno_store/core/utils/color_utilities.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomIconInkwell extends StatelessWidget {
  final IconData icon;
  final double size;
  final String url;
  final String fallbackUrl;
  const CustomIconInkwell({
    super.key,
    required this.icon,
    this.size = 30,
    required this.url,
    required this.fallbackUrl,
  });
  void _launchSocial(String url, String fallbackUrl) async {
    try {
      bool launched =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(Uri.parse(fallbackUrl),
            mode: LaunchMode.externalApplication);
      }
      debugPrint('Error launching URL: ');
    } catch (e) {
      await launchUrl(Uri.parse(fallbackUrl),
          mode: LaunchMode.externalApplication);
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      child: InkWell(
        child: Icon(
          icon,
          color: AppColors.secondary,
          size: size,
        ),
        onTap: () {
          _launchSocial(url, fallbackUrl);
        },
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(50),
      ),
    );
  }
}
