import 'package:flutter/material.dart';
import 'package:techno_store/core/shared/model/category_and_sub_category_model.dart';
import 'package:techno_store/core/utils/utilities.dart';
import 'package:techno_store/core/utils/widget_utilities.dart';
import 'package:techno_store/core2/utils/app_colors.dart';

class FilterButtons extends StatefulWidget {
  const FilterButtons({super.key});

  @override
  State<FilterButtons> createState() => _FilterButtonsState();
}

class _FilterButtonsState extends State<FilterButtons> {
  List<CategoriesAndSubCategoryModel> categories = [];
  List<CategoriesAndSubCategoryModel> subCategoryDevices = [];
  List<CategoriesAndSubCategoryModel> subCategoryAccessories = [];
  List<IconData> icons = [];
  List<String> ids = [];
  int selectedCategoryIndex = 0;
  int selectedSubCategoryIndex = 0;
  @override
  void initState() {
    super.initState();
    categories
        .add(CategoriesAndSubCategoryModel(arName: "اجهزة", enName: "Devices"));
    icons.add(Icons.devices);
    ids.add("3vNDw2Rz1QOCV4HH0Axi");
    categories.add(CategoriesAndSubCategoryModel(
      arName: "اكسسوارات",
      enName: "Accessories",
    ));
    icons.add(Icons.headphones);
    ids.add("NPNApiAjPdqWdXyI4IaZ");
    subCategoryDevices
        .add(CategoriesAndSubCategoryModel(arName: "أبل", enName: "Apple"));
    subCategoryDevices.add(
        CategoriesAndSubCategoryModel(arName: "سامسونج", enName: "Samsung"));
    subCategoryDevices
        .add(CategoriesAndSubCategoryModel(arName: "شاومي", enName: "Xiaomi"));

    subCategoryAccessories.add(CategoriesAndSubCategoryModel(
      arName: "ساعات ذكية",
      enName: "Smart Watch",
    ));
    subCategoryAccessories
        .add(CategoriesAndSubCategoryModel(arName: "شواحن", enName: "charger"));
    subCategoryAccessories
        .add(CategoriesAndSubCategoryModel(arName: "كفرات", enName: "covers"));

    icons.add(Icons.apple); //2
    icons.add(Icons.android); // 3
    icons.add(Icons.watch); // 5
    icons.add(Icons.charging_station_rounded); //5
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              debugPrint("index : $index");

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: (selectedCategoryIndex != index)
                        ? const LinearGradient(
                            colors: [
                              AppColors.secondary2,
                              AppColors.secondary,
                              // AppColors.secondary2,
                            ],
                          )
                        : const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedCategoryIndex = index;
                      });
                      // index != 0
                      //     ? Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //             builder: (context) => Store(
                      //                   category: categories[index - 1],
                      //                   categoryId: ids[index - 1],
                      //                 )),
                      //       ).then((value) => () {
                      //           setState(() {});
                      //         })
                      //     : null;
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        children: [
                          if (index != 0)
                            Center(
                              child: Icon(icons[index - 1]),
                            ),
                          if (index != 0)
                            const SizedBox(
                              width: 8,
                            ),
                          Center(
                            child: WidgetUtilities.autoSizeText(
                                (index == 0)
                                    ? "All"
                                    : (Utilities.isEnglish(context))
                                        ? categories[index - 1].enName!
                                        : categories[index - 1].arName!,
                                textStyle: TextStyle(
                                  color: (selectedCategoryIndex == index)
                                      ? AppColors.white
                                      : AppColors.black,
                                )),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (selectedCategoryIndex != 0)
          SizedBox(
            height: 50,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                debugPrint("index : $index");

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: (selectedSubCategoryIndex != index)
                          ? const LinearGradient(
                              colors: [
                                AppColors.secondary2,
                                AppColors.secondary,
                                // AppColors.secondary2,
                              ],
                            )
                          : const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedSubCategoryIndex = index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          children: [
                            if (index != 0)
                              Center(
                                child: Icon(icons[(selectedCategoryIndex == 2)
                                    ? index + selectedCategoryIndex + 1
                                    : index + selectedCategoryIndex]),
                              ),
                            if (index != 0)
                              const SizedBox(
                                width: 8,
                              ),
                            Center(
                              child: WidgetUtilities.autoSizeText(
                                  (index == 0)
                                      ? "All"
                                      : (Utilities.isEnglish(context))
                                          ? ((selectedCategoryIndex == 1)
                                              ? subCategoryDevices[index - 1]
                                                  .enName!
                                              : subCategoryAccessories[
                                                      index - 1]
                                                  .enName!)
                                          : ((selectedCategoryIndex == 1)
                                              ? subCategoryDevices[index - 1]
                                                  .arName!
                                              : subCategoryAccessories[
                                                      index - 1]
                                                  .arName!),
                                  textStyle: TextStyle(
                                    color: (selectedSubCategoryIndex == index)
                                        ? AppColors.white
                                        : AppColors.black,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
