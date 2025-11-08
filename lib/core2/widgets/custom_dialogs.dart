import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/core2/widgets/main_button.dart';

class CustomDialogs {
  static Future<void> showDialogConfirm(
      {required BuildContext context,
      required String title,
      required String content,
      required void Function() onPressed}) {
    final width = MediaQuery.of(context).size.width;
    return showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: Text(title.tr()),
            content: Text(content.tr()),
            actions: [
              MainButton(
                label: 'Yes',
                width: width > 900 ? width * 0.2 : width * 0.3,
                onPressed: onPressed,
              ),
              MainButton(
                width: width > 900 ? width * 0.2 : width * 0.3,
                label: 'No',
                onPressed: () {
                  // Close the dialog
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
}
