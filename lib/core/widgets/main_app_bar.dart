import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:techno_store/core/utils/widget_utilities.dart';
import 'package:techno_store/core/utils/app_colors.dart';
import 'package:techno_store/core/utils/app_constants.dart';

class MainAppBar extends StatelessWidget {
  final String title;
  final VoidCallback? onLanguageChanged;
  final AdvancedDrawerController? advancedDrawerController;
  final bool haveLeading;
  const MainAppBar({
    super.key,
    required this.title,
    this.onLanguageChanged,
    required this.advancedDrawerController,
    this.haveLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    String lang = context.locale == const Locale("en") ? "ar" : "en";
    double width = MediaQuery.of(context).size.width;
    return AppBar(
      scrolledUnderElevation: 0,
      toolbarHeight: width <= 500 ? 30 : 100,
      leading: haveLeading
          ? IconButton(
              onPressed: _handleMenuButtonPressed,
              icon: ValueListenableBuilder<AdvancedDrawerValue>(
                valueListenable: advancedDrawerController!,
                builder: (_, value, __) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Semantics(
                      label: 'Menu',
                      onTapHint: 'expand drawer',
                      child: Icon(
                        value.visible ? Icons.clear : Icons.menu,
                        key: ValueKey<bool>(value.visible),
                      ),
                    ),
                  );
                },
              ),
            )
          : null,
      title: WidgetUtilities.autoSizeText(
        title,
        textAlign: TextAlign.center,
        textStyle: (title == AppConstants.appName)
            ? Theme.of(context).textTheme.displayLarge!.copyWith(
                  letterSpacing: 8,
                )
            : Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: AppColors.primary,
                ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10, left: 10),
          child: Center(
            child: InkWell(
              onTap: () {
                context.setLocale(
                  context.locale == const Locale("en")
                      ? const Locale("ar")
                      : const Locale("en"),
                );
                onLanguageChanged?.call();
              },
              child: WidgetUtilities.autoSizeText(
                lang.tr(),
                textAlign: TextAlign.center,
                textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: AppColors.primary,
                    ),
                maxFontSize: 16,
              ),
            ),
          ),
        )
      ],
    );
  }

  void _handleMenuButtonPressed() {
    // NOTICE: Manage Advanced Drawer state through the Controller.
    // _advancedDrawerController.value = AdvancedDrawerValue.visible();
    advancedDrawerController!.showDrawer();
  }
}
