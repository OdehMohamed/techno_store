import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:techno_store/core/new_device_maintenance/view/new_device_maintenance.dart';
import 'package:techno_store/shared/color_utilities.dart';

import '../../../shared/widget_utilities.dart';

class MaintinanceList extends StatefulWidget {
  const MaintinanceList({Key? key}) : super(key: key);

  @override
  State<MaintinanceList> createState() => _MaintinanceListState();
}

List<Color> backgroundColor = [
  Colors.white,
  Colors.transparent,
  Colors.transparent
];
List<Color> textColor = [
  ColorUtilities.secondary,
  ColorUtilities.white,
  ColorUtilities.white
];
void changeStatus(int status) {
  switch (status) {
    case 0:
      {
        backgroundColor = [
          ColorUtilities.white,
          Colors.transparent,
          Colors.transparent
        ];
        textColor = [
          ColorUtilities.secondary,
          ColorUtilities.white,
          ColorUtilities.white
        ];
        break;
      }
    case 1:
      {
        backgroundColor = [
          Colors.transparent,
          ColorUtilities.white,
          Colors.transparent
        ];
        textColor = [
          ColorUtilities.white,
          ColorUtilities.secondary,
          ColorUtilities.white
        ];
        break;
      }
    case 2:
      {
        backgroundColor = [
          Colors.transparent,
          Colors.transparent,
          ColorUtilities.white
        ];
        textColor = [
          ColorUtilities.white,
          ColorUtilities.white,
          ColorUtilities.secondary
        ];
        break;
      }
    default:
      {
        backgroundColor = [
          ColorUtilities.white,
          Colors.transparent,
          Colors.transparent
        ];
        textColor = [
          ColorUtilities.secondary,
          ColorUtilities.white,
          ColorUtilities.white,
        ];
        break;
      }
  }
}

class _MaintinanceListState extends State<MaintinanceList> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Widget card(){
      return InkWell(
        child:  Container(
          width: width*0.9,
          height: height*0.2,
          margin: EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: ColorUtilities.white,

          ),
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.all(width*0.05),
                width: width*0.1,
                height: height*0.07,
                child: Image.asset("assets/images/appleLogo.png",fit: BoxFit.fill,),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: width*0.67,
                    child: Row(children: [
                      WidgetUtilities.autoSizeText("Ahmad Mohammad",textStyle: TextStyle(color: Colors.black)),
                      Flexible(child: Container()),
                      Icon(FontAwesome5.check_circle,color: Colors.green,),
                      SizedBox(width: 5,),
                      WidgetUtilities.autoSizeText("Fixed",textStyle: TextStyle(color: Colors.black54))
                    ],),
                  ),
                  Container(
                    width: width*0.67,
                    child: Row(children: [
                      WidgetUtilities.autoSizeText("Apple 13 pro max",textStyle: TextStyle(color: Colors.black54))
                    ],),
                  ),
                  Container(
                    width: width*0.67,
                    child: Row(children: [
                      Container(child: Row(children: [
                        WidgetUtilities.autoSizeText("4",textStyle: TextStyle(color: Colors.black54)),
                        WidgetUtilities.autoSizeText("days",textStyle: TextStyle(color: Colors.black54)),
                      ],),),
                      Flexible(child: Container()),
                      Container(child: Row(children: [
                        WidgetUtilities.autoSizeText("30",textStyle: TextStyle(color: Colors.black54)),
                        WidgetUtilities.autoSizeText("JD",textStyle: TextStyle(color: Colors.black54)),
                      ],),),                    ],),
                  ),

                ],
              )
            ],
          ),
        ),
        onTap: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => NewDeviceMaintanace()),);
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
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: height * 0.13),
                      child: WidgetUtilities.autoSizeText("Mobile List",textStyle: TextStyle(fontSize: 20,color: ColorUtilities.textColor))
                    ),
                    Flexible(child: Container()),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      InkWell(
                        child: Container(
                          padding: EdgeInsets.only(
                              top: 5, bottom: 5, left: 10, right: 10),
                          decoration: BoxDecoration(
                              color: backgroundColor[0],
                              borderRadius: BorderRadius.circular(15)),
                          child: WidgetUtilities.autoSizeText(
                            "All",
                            textStyle: TextStyle(color: textColor[0], fontSize: 18),
                          ),
                        ),
                        onTap: () {
                          changeStatus(0);
                          setState(() {});
                        },
                      ),
                      InkWell(
                        child: Container(
                          padding: EdgeInsets.only(
                              top: 5, bottom: 5, left: 10, right: 10),
                          decoration: BoxDecoration(
                              color: backgroundColor[1],
                              borderRadius: BorderRadius.circular(25)),
                          child: WidgetUtilities.autoSizeText(
                            "Fixing",
                            textStyle: TextStyle(color: textColor[1], fontSize: 18),
                          ),
                        ),
                        onTap: () {
                          changeStatus(1);
                          setState(() {});
                        },
                      ),
                      InkWell(
                        child: Container(
                          padding: EdgeInsets.only(
                              top: 5, bottom: 5, left: 10, right: 10),
                          decoration: BoxDecoration(
                              color: backgroundColor[2],
                              borderRadius: BorderRadius.circular(25)),
                          child: WidgetUtilities.autoSizeText(
                            "Done",
                            textStyle: TextStyle(color: textColor[2], fontSize: 18),
                          ),
                        ),
                        onTap: () {
                          changeStatus(2);
                          setState(() {});
                        },
                      ),
                    ])
                  ],
                ))),
          ),
          Container(
            color: ColorUtilities.secondary,
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
                    margin: EdgeInsets.only(right: 20, left: 20),
                    padding: EdgeInsets.only(top: 30, bottom: 10),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          card(),
                          card(),
                          card(),
                          card(),
                          card(),
                          card(),
                          card(),
                        ],
                      ),
                    ))),
          )
        ],
      ),
    );
  }
}
