import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/maintenance_list/view_model/maintenance_list_state.dart';
import 'package:techno_store/core/new_device_maintenance/view/new_device_maintenance.dart';
import 'package:techno_store/core/shared/model/maintenance_device_model.dart';
import 'package:techno_store/core/shared/view_model/shared_state.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:techno_store/shared/utilities.dart';

import '../../../shared/widget_utilities.dart';
import '../../shared/model/brand_model.dart';

class MaintinanceList extends StatefulWidget {
  const MaintinanceList({Key? key}) : super(key: key);

  @override
  State<MaintinanceList> createState() => _MaintinanceListState();
}

class _MaintinanceListState extends State<MaintinanceList> {

  String theStatus = "Fixed";
  List<Color> backgroundColor = [
    ColorUtilities.secondary,
    Colors.transparent,
    Colors.transparent,

  ];
  List<Color> textColor = [
    ColorUtilities.white,
    ColorUtilities.black,
    ColorUtilities.black,

  ];
  late MaintenanceListState maintenanceListState;
  late SharedState sharedState;
  late Future<List<MaintenanceDeviceModel>> deviceList;
  void changeStatus(int status) {
    switch (status) {
      case 0:
        {
          theStatus = "Fixed";
          backgroundColor = [
            ColorUtilities.secondary,
            Colors.transparent,
            Colors.transparent,

          ];
          textColor = [
            ColorUtilities.white,
            ColorUtilities.black,
            ColorUtilities.black,
          ];
          break;
        }
      case 1:
        {
          theStatus = "in maintenance";
          backgroundColor = [
            Colors.transparent,
            ColorUtilities.secondary,
            Colors.transparent
          ];
          textColor = [
            ColorUtilities.black,
            ColorUtilities.white,
            ColorUtilities.black
          ];
          break;
        }
      case 2:
        {
          theStatus = "Delivered";
          backgroundColor = [
            Colors.transparent,
            Colors.transparent,
            ColorUtilities.secondary
          ];
          textColor = [
            ColorUtilities.black,
            ColorUtilities.black,
            ColorUtilities.white
          ];
          break;
        }
      default:
        {
          theStatus = "Fixed";
          backgroundColor = [
            ColorUtilities.secondary,
            Colors.transparent,
            Colors.transparent,

          ];
          textColor = [
            ColorUtilities.white,
            ColorUtilities.black,
            ColorUtilities.black,
          ];
          break;
        }
    }
    deviceList = maintenanceListState.getDevicesInMaintenance(theStatus);
  }

  @override
  void initState() {
    maintenanceListState = context.read<MaintenanceListState>();
    sharedState = context.read<SharedState>();
    deviceList = maintenanceListState.getDevicesInMaintenance(theStatus);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    maintenanceListState = context.watch<MaintenanceListState>();
    sharedState = context.watch<SharedState>();

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Widget card(MaintenanceDeviceModel device) {
      Icon statusIcon;
      switch (device.status) {
        case "Fixed":
          {
            statusIcon = Icon(FontAwesome5.check_circle, color: Colors.green);
            break;
          }
        case "Delivered":{
          statusIcon = Icon(Icons.done_all, color: Colors.green);
          break;
        }
        default:
          {
            statusIcon = Icon(
              Icons.precision_manufacturing,
              color: Colors.yellow,
            );
            break;
          }
      }
      return InkWell(
        child: Container(
          width: width * 0.9,
          height: height * 0.2,
          margin: EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: ColorUtilities.white,
          ),
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.all(width * 0.05),
                width: width * 0.1,
                height: height * 0.07,
                child: Image.network(
                  device.brandModel!.logo!,
                  fit: BoxFit.fill,
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: width * 0.67,
                    child: Row(
                      children: [
                        WidgetUtilities.autoSizeText(device.customerName!,
                            textStyle: TextStyle(color: Colors.black)),
                        Flexible(child: Container()),
                        statusIcon,
                        SizedBox(
                          width: 5,
                        ),
                        WidgetUtilities.autoSizeText(device.status!,
                            textStyle: TextStyle(color: Colors.black54))
                      ],
                    ),
                  ),
                  Container(
                    width: width * 0.67,
                    child: Row(
                      children: [
                        WidgetUtilities.autoSizeText(device.deviceModel!,
                            textStyle: TextStyle(color: Colors.black54))
                      ],
                    ),
                  ),
                  Container(
                    width: width * 0.67,
                    child: Row(
                      children: [
                        Container(
                          child: Row(
                            children: [
                              WidgetUtilities.autoSizeText(
                                  device.estimatedTime!,
                                  textStyle: TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                        Flexible(child: Container()),
                        Container(
                          child: Row(
                            children: [
                              WidgetUtilities.autoSizeText(device.price!,
                                  textStyle: TextStyle(color: Colors.black54)),
                              WidgetUtilities.autoSizeText("ILS",
                                  textStyle: TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        onTap: () {
          Utilities.navigatorWithBack(
              context,
              NewDeviceMaintanace(
                maintenanceDevice: device,
                editable: true,
              ));
        },
      );
    }

    return Scaffold(
        floatingActionButton: sharedState.userType == 2
            ? FloatingActionButton(
                child: Icon(
                  Icons.add,
                  color: ColorUtilities.secondary,
                ),
                backgroundColor: Colors.white,
                onPressed: () {
                  Utilities.navigatorWithBack(
                      context,
                      NewDeviceMaintanace(
                        editable: false,
                      ));
                },
              )
            : null,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        body: RefreshIndicator(
          onRefresh: () async {
           setState(() {
             maintenanceListState = context.read<MaintenanceListState>();
             sharedState = context.read<SharedState>();
             deviceList = maintenanceListState.getDevicesInMaintenance(theStatus);
           });
          },
          child: Column(
            children: [
              Container(
                color: ColorUtilities.backgroundContainer,
                child: Container(
                    width: width,
                    height: height * 0.15,
                    decoration: const BoxDecoration(
                      color: ColorUtilities.secondary,
                    ),
                    child: Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            margin: EdgeInsets.only(top: height * 0.08),
                            child: WidgetUtilities.autoSizeText("Mobile List",
                                textStyle: TextStyle(
                                    fontSize: 20,
                                    color: ColorUtilities.textColor))),
                        Flexible(child: Container()),
                      ],
                    ))),
              ),
              Container(
                color: ColorUtilities.secondary,
                child: Container(
                    width: width,
                    height: height * 0.85,
                    decoration: const BoxDecoration(
                      color: ColorUtilities.backgroundContainer,
                    ),
                    child: Container(
                        margin: EdgeInsets.only(right: 20, left: 20),
                        padding: EdgeInsets.only(top: 30, bottom: 10),
                        child:
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        InkWell(
                                          child: Container(
                                            padding: EdgeInsets.only(
                                                top: 10, bottom: 10, left: width*0.04, right: width*0.04),
                                            decoration: BoxDecoration(
                                                border: Border.all(width: 1,color: ColorUtilities.secondary),
                                                color: backgroundColor[0],
                                                borderRadius: BorderRadius.circular(5)),
                                            child: WidgetUtilities.autoSizeText(
                                              "Fixed",
                                              textStyle: TextStyle(
                                                  color: textColor[0], fontSize: 18),
                                            ),
                                          ),
                                          onTap: () {
                                            changeStatus(0);
                                            setState(() {});
                                          },
                                        ),
                                        InkWell(
                                          child: Container(
                                            margin: EdgeInsets.only(left: 5,right: 5),
                                            padding: EdgeInsets.only(
                                                top: 10, bottom: 10, left: width*0.04, right: width*0.04),
                                            decoration: BoxDecoration(
                                                border: Border.all(width: 1,color: ColorUtilities.secondary),
                                                color: backgroundColor[1],
                                                borderRadius: BorderRadius.circular(5)),
                                            child: WidgetUtilities.autoSizeText(
                                              "in maintenance",
                                              textStyle: TextStyle(
                                                  color: textColor[1], fontSize: 18),
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
                                                top: 10, bottom: 10, left: width*0.04, right: width*0.04),
                                            decoration: BoxDecoration(
                                                border: Border.all(width: 1,color: ColorUtilities.secondary),
                                                color: backgroundColor[2],
                                                borderRadius: BorderRadius.circular(5)),
                                            child: WidgetUtilities.autoSizeText(
                                              "Delivered",
                                              textStyle: TextStyle(
                                                  color: textColor[2], fontSize: 18),
                                            ),
                                          ),
                                          onTap: () {
                                            changeStatus(2);
                                            setState(() {});
                                          },
                                        ),
                                      ]),
                                  Flexible(
                                    child:
                                  FutureBuilder<List<MaintenanceDeviceModel>>(
                                    future: deviceList,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: Container(
                                              width: 50,
                                              height: 50,
                                              child: CircularProgressIndicator(),
                                            ));
                                      } else if (snapshot.hasData) {
                                        List<MaintenanceDeviceModel> devices =
                                        snapshot.data as List<MaintenanceDeviceModel>;
                                        if (devices.isEmpty) {
                                          return Center(
                                            child: Text("No Data".tr()),
                                          );
                                        }
                                        return ListView.builder(
                                            padding: EdgeInsets.zero,
                                            itemCount: devices.length,
                                            itemBuilder: (context, index) {
                                              return card(devices[index]);
                                            });
                                      } else if (snapshot.data!.isEmpty) {
                                        return Center(
                                          child: Text("No Data".tr()),
                                        );
                                      } else {
                                        return Center(
                                          child: Text("Error".tr()),
                                        );
                                      }
                                    },
                                  )
                                    ,)
                              ],)
                    )
                ),
              )
            ],
          ),
        ));
  }
}
