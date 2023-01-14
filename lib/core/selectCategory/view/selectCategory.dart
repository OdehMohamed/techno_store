import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/core/shared/model/category_and_sub_category_model.dart';
import 'package:techno_store/shared/utilities.dart';

import '../../../shared/color_utilities.dart';
import '../../../shared/widget_utilities.dart';
import '../../store/view/store.dart';
class SelectCategory extends StatefulWidget {
  const SelectCategory({Key? key}) : super(key: key);

  @override
  State<SelectCategory> createState() => _SelectCategoryState();
}

class _SelectCategoryState extends State<SelectCategory> {
  List<CategoriesAndSubCategoryModel> categories =[];
  List<IconData> icons=[];
  List<String> ids=[];
  @override
  void initState() {
    super.initState();
    categories.add(CategoriesAndSubCategoryModel(arName: "اجهزة",enName: "Devices"));
    icons.add(Icons.devices);
    ids.add("3vNDw2Rz1QOCV4HH0Axi");

    categories.add(CategoriesAndSubCategoryModel(arName: "اكسسوارات",enName: "Accessories",));
    icons.add(Icons.headphones);
    ids.add("NPNApiAjPdqWdXyI4IaZ");
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Widget gridCard(int index) {
      return InkWell(
        child: Container(
          height: height * 0.25,
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: width * 0.25,
                height: height * 0.05,
                child: Icon(icons[index],color: ColorUtilities.secondary,size: 60,)
              ),
              Utilities.isEnglish(context)?
              WidgetUtilities.autoSizeText(categories[index]!.enName!,
                  textStyle: TextStyle(color: Colors.black)):
              WidgetUtilities.autoSizeText(categories[index]!.arName!,
                  textStyle: TextStyle(color: Colors.black,fontSize: 18)),
            ],
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Store(
                  category: categories[index],
                  categoryId: ids[index],
                )),
          ).then((value) => () {
            setState(() {});
          });
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body:  Column(
              children: [
                Container(
                  color: ColorUtilities.backgroundContainer,
                  child: Container(
                      width: width,
                      height: height * 0.1,
                      decoration: const BoxDecoration(
                        color: ColorUtilities.secondary,
                      ),
                      child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                child: Column(children: [
                                  Container(
                                    padding: EdgeInsets.only(bottom: height*0.01),
                                    width: width * 0.75,
                                    child: Center(
                                      child: WidgetUtilities.autoSizeText("Select Category",
                                          textStyle: TextStyle(fontSize: width*0.05,color: Colors.white)),
                                    ),
                                  ),
                                  SizedBox(height: 5,),
                                ]),
                              )
                            ],
                          ))),
                ),
                Container(
                  color: Color.fromRGBO(76, 127, 158, 1),
                  child: Container(
                      width: width,
                      height: height * 0.9,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(239, 239, 239, 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(child: Container()),
                          Expanded(
                              child: Center(
                                child: GridView.builder(
                                  padding: EdgeInsets.all(10),
                                  itemCount: icons.length,
                                  gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                      childAspectRatio: (1 / 1),
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 1.0,
                                      mainAxisSpacing: 5),
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return gridCard(index);
                                  },
                                ),
                              )
                          ),
                          Expanded(child: Container()),
                        ]
    )
    )
    )]
    )
    );
  }
}
