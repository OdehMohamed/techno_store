import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:techno_store/shared/color_utilities.dart';

import '../../../shared/widget_utilities.dart';

class ProductDetails extends StatefulWidget {
  const ProductDetails({Key? key}) : super(key: key);

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}
bool favourite = false;
List<String> images=[
  "assets/images/iPhone-14.png",
  "assets/images/iPhone-14-2.png",
  "assets/images/iPhone-14-3.png",
];
class _ProductDetailsState extends State<ProductDetails> {
  @override
  Widget build(BuildContext context) {
    void changeFavourite(){
      favourite=!favourite;
      setState(() {});
    }
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          Container(
            color: ColorUtilities.backgroundContainer,
            child: Container(
                width: width,
                height: height * 0.25,
                decoration: const BoxDecoration(
                  color: ColorUtilities.secondary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                  ),
                ),
                child: Center(
                  child: WidgetUtilities.autoSizeText(
                    "IPhone 14 Pro",
                      textStyle: TextStyle(color: ColorUtilities.textColor,
                        fontSize: 20
                      ),
                  ),
                )),
          ),
          Container(
            color:ColorUtilities.secondary,
            child: Container(
                width: width,
                height: height * 0.75,
                decoration: const BoxDecoration(
                  color: ColorUtilities.backgroundContainer,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Container(
                    margin: EdgeInsets.only(right: 40, left: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            InkWell(
                              child:favourite?
                              Icon(CupertinoIcons.heart_fill,color:Colors.red,size: 35,):
                              Icon(CupertinoIcons.heart,color: Color.fromRGBO(76, 127, 158, 1),size: 35),
                              onTap: (){
                                changeFavourite();
                              },
                            ),

                          ],
                        ),
                        Container(
                            width: width*0.6,
                            height: height*0.3,
                            child:  ListView(
                              scrollDirection: Axis.horizontal,
                              children: List.generate(
                                3,
                                    (i) => Container(
                                    width: width*0.5,
                                    alignment: Alignment.center,
                                    child:Container(margin: EdgeInsets.all(10),child:GestureDetector(
                                        child: InkWell(child: Image.asset(images[i]),
                                          onTap: ()  {
                                            showDialog<Image>(
                                              context: context,
                                              builder: (BuildContext context) => AlertDialog(
                                                content: Container(
                                                  width: width,
                                                  height: width,
                                                  child:
                                                  PhotoView(
                                                    backgroundDecoration:BoxDecoration(color: Colors.transparent),
                                                    imageProvider: AssetImage(images[i]),
                                                  ),
                                                ),
                                              ),
                                            );

                                          },)
                                    ))
                                ),
                              ),
                            )
                        ),
                        WidgetUtilities.autoSizeText("1000"+"JD".tr(),textStyle: TextStyle(color: Colors.black)),
                        Container(
                          width: width * 0.8,
                          height: height * 0.2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: ColorUtilities.white,
                          ),
                          child: SingleChildScrollView(
                              child: Container(
                            margin: EdgeInsets.all(10),
                            child: WidgetUtilities.autoSizeText("Details",textStyle: TextStyle(color: Colors.black))
                          )),
                        )
                      ],
                    ))),
          )
        ],
      ),
    );
  }
}
