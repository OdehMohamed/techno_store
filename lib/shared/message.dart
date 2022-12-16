import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:techno_store/shared/string_utilities.dart';

class Message {
  static void showLongToastMessage(String message) {
    _showToastMessage(message);
  }

  static void showShortToastMessage(String message) {
    _showToastMessage(message, length: Toast.LENGTH_SHORT);
  }

  static void showErrorToastMessage(String message) {
    _showToastMessage(message,
        backgroundColor: Colors.red,
        textColor: Colors.white);
  }

  static void _showToastMessage(String message,
      {Toast length = Toast.LENGTH_LONG,
      Color backgroundColor = ColorUtilities.primary,
      Color textColor = ColorUtilities.textColor}) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: length,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: StringUtilities.smallText);
  }
}
