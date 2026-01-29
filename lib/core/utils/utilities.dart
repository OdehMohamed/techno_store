import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class Utilities {
  static const double defaultPading = 0.8;

  static double getDeviceWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getDeviceHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static EdgeInsets getDefaultPadding() {
    return const EdgeInsets.all(defaultPading);
  }

  static EdgeInsets getDefaultTBPadding() {
    return const EdgeInsets.fromLTRB(0, defaultPading, 0, defaultPading);
  }

  static EdgeInsets getDefaultLRPadding() {
    return const EdgeInsets.fromLTRB(defaultPading, 0, defaultPading, 0);
  }

  static bool isEnglish(BuildContext context) {
    return context.locale == Locale("en");
  }

  static navigator(BuildContext context, Widget screen) {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (BuildContext context) => screen),
        ModalRoute.withName(''));
  }

  static navigatorWithBack(BuildContext context, Widget screen) {
    return Navigator.push(
        context, MaterialPageRoute(builder: (context) => screen));
  }
}
