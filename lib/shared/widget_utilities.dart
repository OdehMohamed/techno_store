import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:techno_store/shared/utilities.dart';
import 'dart:ui' as ui;

class WidgetUtilities {
  static Widget divider() {
    return Divider(
      thickness: 1.0,
      color: ColorUtilities.dividerColor,
    );
  }

  static Widget autoSizeText(String text,
      {double minFontSize = 12,
      int maxLine = 1,
      TextStyle textStyle = const TextStyle(
        color: ColorUtilities.textColor,
      ),
      textAlign = TextAlign.start}) {
    return AutoSizeText(text.tr(),
        minFontSize: minFontSize,
        style: textStyle,
        textAlign: textAlign,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        maxLines: maxLine);
  }

  static Widget noDataWidget() {
    return Center(
      child: Container(
        color: ColorUtilities.primary,
        child: Padding(
          padding: Utilities.getDefaultPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.do_not_disturb_alt_sharp,
                color: ColorUtilities.backGround,
              ),
              Padding(padding: Utilities.getDefaultTBPadding()),
              WidgetUtilities.autoSizeText("No Data Available")
            ],
          ),
        ),
      ),
    );
  }

  static PreferredSizeWidget customAppBar(BuildContext context) {
    String lang = context.locale == Locale("en") ? "ar" : "en";
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        Container(
          margin: EdgeInsets.only(right: 10, left: 10),
          child: Center(
            child: InkWell(
              onTap: () {
                context.setLocale(
                  context.locale == const Locale("en")
                      ? const Locale("ar")
                      : const Locale("en"),
                );
              },
              child: WidgetUtilities.autoSizeText(
                lang.tr(),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        )
      ],
    );
  }

  static Widget headerApp(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Container(
      color: ColorUtilities.backgroundContainer,
      child: Container(
        width: width,
        height: height * 0.15,
        decoration: const BoxDecoration(
          color: ColorUtilities.secondary,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.only(
                  top: width < 500
                      ? height * 0.05
                      : width < 1025
                          ? height * 0.001
                          : 0),
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "T.E.C.H.N.O",
                      style: TextStyle(
                          fontSize: width < 500
                              ? width * 0.08
                              : width < 1025
                                  ? width * 0.04
                                  : width * 0.03,
                          color: ColorUtilities.backgroundContainer,
                          letterSpacing: 3),
                      textAlign: TextAlign.center,
                    ),
                    Center(
                      child: Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: "Stor",
                              style: TextStyle(
                                fontSize: width < 500
                                    ? width * 0.05
                                    : width < 1025
                                        ? width * 0.03
                                        : width * 0.02,
                                color: ColorUtilities.backgroundContainer,
                                letterSpacing: 25,
                              ),
                            ),
                            TextSpan(
                              text: "e",
                              style: TextStyle(
                                fontSize: width < 500
                                    ? width * 0.05
                                    : width < 1025
                                        ? width * 0.03
                                        : width * 0.02,
                                color: ColorUtilities.backgroundContainer,
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
