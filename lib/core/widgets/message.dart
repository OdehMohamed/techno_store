import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:techno_store/core/utils/app_colors.dart';

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

  /// Displays exactly the message it's given — isError only controls
  /// styling (red vs. green), never the text. Error interpretation belongs
  /// once, at the boundary where a technical exception becomes a
  /// user-facing string (AuthCubit and other cubits' curated messages),
  /// not here. This used to also pattern-match error text against
  /// hardcoded Firebase error-code substrings and silently replace
  /// whatever the caller passed — which meant a caller's own correctly
  /// curated message (e.g. "Incorrect email or password") never actually
  /// reached the screen, since it didn't contain the raw code substring
  /// this was matching on. Found via live device testing during the Staff
  /// Auth vertical slice review (2026-07-23) — affected every caller that
  /// already curated its own message, including the customer phone-OTP
  /// error path, not just the code that surfaced it.
  static void showBottomMessage(BuildContext context, String message,
      {bool isError = false}) {
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

  static void _showToastMessage(
    String message, {
    Toast length = Toast.LENGTH_LONG,
    Color backgroundColor = AppColors.primary,
    Color textColor = AppColors.white,
  }) {
    Fluttertoast.showToast(
      timeInSecForIosWeb: 4,
      msg: message,
      toastLength: length,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 20,
    );
  }
}
