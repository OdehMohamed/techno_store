import 'dart:async';
import 'package:flutter/material.dart';
import 'package:techno_store/core2/route/app_routes.dart';
import 'package:techno_store/core2/utils/app_colors.dart';

class MainProgressIndicator extends StatefulWidget {
  const MainProgressIndicator({Key? key}) : super(key: key);

  @override
  State<MainProgressIndicator> createState() => _MainProgressIndicatorState();
}

class _MainProgressIndicatorState extends State<MainProgressIndicator> {
  @override
  Widget build(BuildContext context) {
    Timer(const Duration(milliseconds: 7000), () {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.mainScreen,
      );
    });

    return Container(
      color: AppColors.secondary,
      child: Center(
        child: SizedBox(
          height: 400,
          width: 400,
          child: Image.asset(
            "assets/images/logo.gif",
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
