import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/core2/utils/app_colors.dart';

class MainButton extends StatelessWidget {
  final String? label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final Color bgColor;
  final Color textColor;
  final double width;
  final double height;

  const MainButton({
    super.key,
    this.label,
    this.isLoading = false,
    this.onPressed,
    this.bgColor = AppColors.primary,
    this.textColor = AppColors.white,
    this.width = double.infinity,
    this.height = 60,
  }) : assert(label != null || isLoading);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: bgColor,
          backgroundColor: bgColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const CircularProgressIndicator.adaptive(
                backgroundColor: AppColors.white,
              )
            : Text(
                label!.tr(),
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: textColor,
                    ),
              ),
      ),
    );
  }
}
