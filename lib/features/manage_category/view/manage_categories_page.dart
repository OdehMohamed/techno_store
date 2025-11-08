import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/core2/widgets/main_app_bar.dart';
import 'package:techno_store/features/manage_category/widgets/grid_card.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final _advancedDrawerController = AdvancedDrawerController();
  int selectedIndex = 0;

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
          title: 'Manage Categories'.tr(),
          onLanguageChanged: () => setState(() {}),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: width <= 1025 ? width * 0.05 : width * 0.1,
          vertical: height * 0.05,
        ),
        child: Column(
          children: [
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: width < 500 ? 3 : 6,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: width <= 500
                    ? 1.2
                    : kIsWeb
                        ? 1.5
                        : 1,
              ),
              children: [
                GridCard(
                  label: 'Add new Category'.tr(),
                  onTap: () {
                    setState(() {
                      selectedIndex = 0;
                    });
                  },
                  isSelected: selectedIndex == 0 ? true : false,
                ),
                GridCard(
                  label: 'Add new Subcategory'.tr(),
                  onTap: () {
                    setState(() {
                      selectedIndex = 1;
                    });
                  },
                  isSelected: selectedIndex == 1 ? true : false,
                ),
                GridCard(
                  label: 'Edit Category'.tr(),
                  onTap: () {
                    setState(() {
                      selectedIndex = 2;
                    });
                  },
                  isSelected: selectedIndex == 2 ? true : false,
                ),
                GridCard(
                  label: 'Edit Subcategory'.tr(),
                  onTap: () {
                    setState(() {
                      selectedIndex = 3;
                    });
                  },
                  isSelected: selectedIndex == 3 ? true : false,
                ),
                GridCard(
                  label: 'Delete Category'.tr(),
                  onTap: () {
                    setState(() {
                      selectedIndex = 4;
                    });
                  },
                  isSelected: selectedIndex == 4 ? true : false,
                ),
                GridCard(
                  label: 'Delete Subcategory'.tr(),
                  onTap: () {
                    setState(() {
                      selectedIndex = 5;
                    });
                  },
                  isSelected: selectedIndex == 5 ? true : false,
                ),
              ],
            ),
            const Divider(
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
