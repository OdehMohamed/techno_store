import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:techno_store/core/utils/utilities.dart';
import 'package:techno_store/core/utils/widget_utilities.dart';
import 'package:techno_store/core/utils/app_colors.dart';
import 'package:techno_store/core/widgets/custom_icon_inkwell.dart';

class MainFooter extends StatelessWidget {
  const MainFooter({super.key});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return SizedBox(
      height: width <= 500 ? 80 : 110,
      child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            // boxShadow: [
            //   BoxShadow(
            //     color: AppColors.primary,
            //   ),
            // ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Divider(
                color: AppColors.primary,
                thickness: 1,
                indent: width * 0.1,
                endIndent: width * 0.1,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WidgetUtilities.autoSizeText(
                    Utilities.isEnglish(context)
                        ? 'Contact us:'
                        : 'تواصل معنا:',
                    textStyle: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 15),
                  CustomIconInkwell(
                    icon: FontAwesome5.whatsapp,
                    size: width <= 500 ? 20 : 30,
                    url: 'https://wa.me/message/WGQOCNRN47W7M1?src=qr',
                    fallbackUrl: 'https://wa.me/message/WGQOCNRN47W7M1?src=qr',
                  ),
                  const SizedBox(width: 15),
                  CustomIconInkwell(
                    icon: FontAwesome5.facebook,
                    size: width <= 500 ? 20 : 30,
                    url: 'fb://profile/100088001516569',
                    fallbackUrl:
                        'facebook.com/people/Techno-Store-تكنو-ستور/100088001516569/',
                  ),
                  const SizedBox(width: 15),
                  CustomIconInkwell(
                    icon: FontAwesome5.instagram,
                    size: width <= 500 ? 20 : 30,
                    url: 'instagram://user?username=techno__store00',
                    fallbackUrl:
                        'https://www.instagram.com/techno__store00/?igshid=YmMyMTA2M2Y%3D',
                  ),
                  const SizedBox(width: 15),
                  CustomIconInkwell(
                    icon: FontAwesome5.snapchat,
                    size: width <= 500 ? 20 : 30,
                    url: 'https://www.snapchat.com/add/technostore0',
                    fallbackUrl: 'https://www.snapchat.com/add/technostore0',
                  ),
                  const SizedBox(width: 15),
                  CustomIconInkwell(
                    icon: Icons.tiktok,
                    size: width <= 500 ? 20 : 30,
                    url:
                        'https://www.tiktok.com/@technostore11?_t=8YtE7LC84os&_r=1',
                    fallbackUrl:
                        'https://www.tiktok.com/@technostore11?_t=8YtE7LC84os&_r=1',
                  ),
                ],
              ),
            ],
          )),
    );
  }
}
