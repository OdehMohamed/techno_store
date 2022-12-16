import 'package:flutter/material.dart';

class Utilities {
  static const double defaultPading = 0.8;

  static double getDeviceWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getDeviceheight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static EdgeInsets getDefaultPading() {
    return const EdgeInsets.all(defaultPading);
  }

  static EdgeInsets getDefaultTBPading() {
    return const EdgeInsets.fromLTRB(0, defaultPading, 0, defaultPading);
  }

  static EdgeInsets getDefaultLRPading() {
    return const EdgeInsets.fromLTRB(defaultPading, 0, defaultPading, 0);
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
