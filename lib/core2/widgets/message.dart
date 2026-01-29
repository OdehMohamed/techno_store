import 'package:another_flushbar/flushbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:techno_store/core/utils/color_utilities.dart';
import 'package:techno_store/core/utils/string_utilities.dart';
import 'package:techno_store/core2/utils/app_colors.dart';

class Message {
  static void showLongToastMessage(String message) {
    _showToastMessage(message);
  }

  static void showShortToastMessage(String message) {
    _showToastMessage(message, length: Toast.LENGTH_SHORT);
  }

  static void showErrorToastMessage(String message) {
    _showToastMessage(message,
        backgroundColor: Colors.red, textColor: Colors.white);
  }

  static void showSuccessToastMessage(String message) {
    _showToastMessage(message,
        backgroundColor: Colors.green, textColor: Colors.white);
  }

  static void showBottomMessage(BuildContext context, String message,
      {bool isError = false}) {
    if (isError == true) {
      if (message.contains('invalid-credential')) {
        message = "Your email or password is wrong.".tr();
      } else if (message.contains('too-many-requests')) {
        message = "Too many attempts. Please try again later.".tr();
      } else if (message.contains('network-request-failed')) {
        message = "Network error. Please check your connection.".tr();
      } else if (message.contains('email-already-in-use')) {
        message = "Email already in use. Please use a different email.".tr();
      } else {
        message = "An unexpected error occurred. Please try again.".tr();
      }
    }
    Flushbar(
      maxWidth: 600,
      message: message,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
      borderRadius: BorderRadius.circular(8),
      backgroundColor: isError ? AppColors.red : AppColors.green,
      flushbarPosition: FlushbarPosition.BOTTOM,
    ).show(context);
  }

  static void _showToastMessage(String message,
      {Toast length = Toast.LENGTH_LONG,
      Color backgroundColor = ColorUtilities.primary,
      Color textColor = ColorUtilities.textColor}) {
    Fluttertoast.showToast(
      timeInSecForIosWeb: 4,
      msg: message,
      toastLength: length,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: StringUtilities.largeText,
    );
  }
}
