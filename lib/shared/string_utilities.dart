class StringUtilities {
  static const double smallText = 12;
  static const double mediumText = 16;
  static const double largeText = 20;

  static bool stringEmptyOrNull(String text) {
    return text == null || text.isEmpty ? true : false;
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
}
