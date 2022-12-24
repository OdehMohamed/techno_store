import 'package:flutter/cupertino.dart';
import 'package:techno_store/shared/utilities.dart';

class StringUtilities {
  static const double smallText = 12;
  static const double mediumText = 16;
  static const double largeText = 20;

  static bool stringEmptyOrNull(String? text) {
    return text == null || text.isEmpty;
  }

  static String concatenateStrings(List<String> strings) {
    String text = "";

    for (String element in strings) {
      if (!stringEmptyOrNull(element)) {
        text += element + " ";
      }
    }

    return text.trim();
  }

  static String getStringByLanguage(
      BuildContext context, String? arString, String? enString) {
    String? text;

    Utilities.isEnglish(context)
        ? stringEmptyOrNull(enString)
            ? stringEmptyOrNull(arString)
                ? text = ""
                : text = arString
            : text = enString
        : stringEmptyOrNull(arString)
            ? stringEmptyOrNull(enString)
                ? text = ""
                : text = enString
            : text = arString;

    return text!;
  }
}
