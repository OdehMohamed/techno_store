import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:techno_store/shared/utilities.dart';

class WidgetUtilities {
  static Widget divider() {
    return Divider(
      thickness: 1.0,
      color: ColorUtilities.dividerColor,
    );
  }

  static Widget autoSizeText(String text,
      {TextStyle textStyle = const TextStyle(
        color: ColorUtilities.textColor,
      ),
      textAlign = TextAlign.start}) {
    return AutoSizeText(text.tr(),
        style: textStyle,
        textAlign: textAlign,
        softWrap: true,
        overflow: TextOverflow.ellipsis,
        maxLines: 1);
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

  // static Widget loading(){
  // }
}
