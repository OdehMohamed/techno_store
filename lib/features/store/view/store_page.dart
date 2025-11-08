import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:techno_store/core2/widgets/main_app_bar.dart';
import 'package:techno_store/features/store_page/view/inner_store_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final _advancedDrawerController = AdvancedDrawerController();
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(width <= 500 ? height * 0.05 : height * 0.08),
        child: MainAppBar(
          haveLeading: false,
          advancedDrawerController: _advancedDrawerController,
          title: 'Store'.tr(),
          onLanguageChanged: () => setState(() {}),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: width <= 1025 ? width * 0.05 : width * 0.1,
        ),
        child: const InnerStorePage(),
      ),
    );
  }
}
