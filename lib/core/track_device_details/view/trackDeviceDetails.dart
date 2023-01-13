import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';

import '../../../shared/color_utilities.dart';
import '../../../shared/widget_utilities.dart';
import '../../shared/model/maintenance_device_model.dart';
class TrackDeviceDetails extends StatefulWidget {
  final MaintenanceDeviceModel maintenanceDevice;
  const TrackDeviceDetails({Key? key,required this.maintenanceDevice}) : super(key: key);

  @override
  State<TrackDeviceDetails> createState() => _TrackDeviceDetailsState();
}

class _TrackDeviceDetailsState extends State<TrackDeviceDetails> {

  @override
  Widget build(BuildContext context) {
    List<String> TheReplaced=[
      "screen",
      "battery",
      "device back",
      "FRB",
      "software",
      "charging base",
      "volume button",
      "power button",
      "microphone",
      "body",
      "IC",
      "camera glass",
      "main camera",
      "selfie camera",
      "open icloud",
      "others",
    ];
    String Replaced="";
    for (int i=0;i<widget.maintenanceDevice.replaceParts!.length;i++){
      if (widget.maintenanceDevice.replaceParts![i]){
        Replaced+=TheReplaced[i].tr()+"\n";
      }
    }

    Icon statusIcon;
    switch (widget.maintenanceDevice.status) {
      case "Fixed":
        {
          statusIcon = Icon(
            FontAwesome5.check_circle,
            color: Colors.green,
            size: 25,
          );
          break;
        }
      case "Delivered":{
        statusIcon = Icon(
          Icons.done_all,
          color: Colors.green,
          size: 25,
        );
        break;
      }
      case "in maintenance":
        {
          statusIcon = Icon(
            Icons.precision_manufacturing,
            color: Colors.yellow,
            size: 25,
          );
          break;
        }
      default:
        {
          statusIcon = Icon(
            Icons.precision_manufacturing,
            color: Colors.yellow,
            size: 25,
          );
          break;
        }
    }
    bool hideReplaced=true;
    for (int i=0;i<widget.maintenanceDevice.replaceParts!.length;i++){
      if (widget.maintenanceDevice.replaceParts![i]){
        hideReplaced=false;
        break;
      }
    }
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return  Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Column(
          children: [
            Container(
              color: ColorUtilities.backgroundContainer,
              child: Container(
                  width: width,
                  height: height * 0.3,
                  decoration: const BoxDecoration(
                    color: ColorUtilities.secondary,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: SizedBox()),
                      Container(
                        width: width*0.4,
                        height: height*0.1,
                        child:Image.network(widget.maintenanceDevice.brandModel!.logo!,fit: BoxFit.fill,),
                      ),
                      Container(
                          child: WidgetUtilities.autoSizeText(widget.maintenanceDevice!.deviceModel!,textStyle: TextStyle(
                              fontSize: 28,
                              color: Colors.white
                          ))
                      ),
                      Expanded(child: SizedBox()),
                      Container(
                        margin: EdgeInsets.only(left: 20,right: 20,bottom: 20),
                        child: Row(children: [
                          Text(widget.maintenanceDevice!.status!.tr(),style: TextStyle(color: Colors.white,fontSize: 16),),
                          SizedBox(width: 5,),
                          statusIcon,
                          Expanded(child: SizedBox()),
                          Text(widget.maintenanceDevice!.price!+"ILS".tr(),style: TextStyle(color: Colors.white,fontSize: 16),),
                          SizedBox(width: 5,),
                          Icon(Icons.monetization_on,color: Colors.green,),
                        ],) ,
                      )
                    ],
                  )),
            ),
            Container(
              color: ColorUtilities.secondary,
              child: Container(
                  width: width,
                  height: height * 0.7,
                  decoration: const BoxDecoration(
                    color: ColorUtilities.backgroundContainer,
                  ),
                  child: Container(
                    padding: EdgeInsets.only(left: 20, right: 20),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: height * 0.05,
                          ),
                          Table(
                            children: [
                              TableRow(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child:   WidgetUtilities.autoSizeText("Owner name",
                                          textStyle: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child:  WidgetUtilities.autoSizeText(widget.maintenanceDevice.customerName!,
                                          textStyle: TextStyle(color: Colors.black)),
                                    ),
                                  ]
                              ),
                              TableRow(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child:  WidgetUtilities.autoSizeText("Device Model",
                                          textStyle: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child:   WidgetUtilities.autoSizeText(widget.maintenanceDevice.brandModel!.name!.tr()+" "+widget.maintenanceDevice.deviceModel!,
                                          textStyle: TextStyle(color: Colors.black)),
                                    ),
                                  ]
                              ),
                              TableRow(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child:  WidgetUtilities.autoSizeText("The problem",
                                          textStyle: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child:  WidgetUtilities.autoSizeText(widget.maintenanceDevice.problem!,
                                          textStyle: TextStyle(color: Colors.black)),
                                    ),
                                  ]
                              ),
                              TableRow(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: WidgetUtilities.autoSizeText("Color",
                                          textStyle: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Container(
                                        height: 15,
                                        decoration: BoxDecoration(
                                            color: Color(int.parse(widget.maintenanceDevice.color!)),
                                            borderRadius: BorderRadius.circular(50)
                                        ),
                                      )
                                    ),
                                  ]
                              ),
                              TableRow(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child:  WidgetUtilities.autoSizeText("Estimated Time",
                                          textStyle: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child:  WidgetUtilities.autoSizeText(widget.maintenanceDevice.estimatedTime!,
                                          textStyle: TextStyle(color: Colors.black,)),
                                    ),
                                  ]
                              ),
                              hideReplaced?TableRow(
                                  children: [
                                    Container(),Container()
                                  ]
                              ):
                              TableRow(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child:  WidgetUtilities.autoSizeText("Replaced parts",
                                          textStyle: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                                    ),
                                    SingleChildScrollView(
                                        child: Container(
                                            margin: EdgeInsets.all(10),
                                            child: Text(Replaced.toString(),
                                                style:
                                                TextStyle(color: Colors.black)
                                            )
                                        )
                                    ),
                                  ]
                              ),
                              TableRow(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: WidgetUtilities.autoSizeText("Notes",
                                          textStyle: TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                                    ),
                                    SingleChildScrollView(
                                        child: Container(
                                            margin: EdgeInsets.all(10),
                                            child: Text(widget.maintenanceDevice.notes!,
                                                style:
                                                TextStyle(color: Colors.black)
                                            )
                                        )
                                    ),
                                  ]
                              ),

                            ],
                          ),
                        ],
                      ),
                    )
                  )),
            )
          ],
        ),
      ),
    );
  }
}
