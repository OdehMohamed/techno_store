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
    Timer(const Duration(milliseconds: 4300), () {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.mainScreen,
      );
    });

    return Container(
      color: AppColors.white,
      child: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: Image.asset(
            "assets/images/logo.gif",
          ),
        ),
      ),
    );
  }
}
