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

String theStatus = "Fixed";
List<Color> backgroundColor = [
  Colors.white,
  Colors.transparent,
  Colors.transparent,

];
List<Color> textColor = [
  ColorUtilities.secondary,
  ColorUtilities.white,
  ColorUtilities.white,

];

class _MaintinanceListState extends State<MaintinanceList> {
  late MaintenanceListState maintenanceListState;
  late SharedState sharedState;
  late Future<List<MaintenanceDeviceModel>> deviceList;
  void changeStatus(int status) {
    switch (status) {
      case 0:
        {
          theStatus = "Fixed";
          backgroundColor = [
            ColorUtilities.white,
            Colors.transparent,
            Colors.transparent,

          ];
          textColor = [
            ColorUtilities.secondary,
            ColorUtilities.white,
            ColorUtilities.white,
          ];
          break;
        }
      case 1:
        {
          theStatus = "in maintenance";
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
          theStatus = "Delivered";
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
          theStatus = "Fixed";
          backgroundColor = [
            ColorUtilities.white,
            Colors.transparent,
            Colors.transparent,

          ];
          textColor = [
            ColorUtilities.secondary,
            ColorUtilities.white,
            ColorUtilities.white,
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
                    height: height * 0.25,
                    decoration: const BoxDecoration(
                      color: ColorUtilities.secondary,
                    ),
                    child: Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            margin: EdgeInsets.only(top: height * 0.13),
                            child: WidgetUtilities.autoSizeText("Mobile List",
                                textStyle: TextStyle(
                                    fontSize: 20,
                                    color: ColorUtilities.textColor))),
                        Flexible(child: Container()),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                child: Container(
                                  padding: EdgeInsets.only(
                                      top: 5, bottom: 5, left: 10, right: 10),
                                  decoration: BoxDecoration(
                                      color: backgroundColor[0],
                                      borderRadius: BorderRadius.circular(15)),
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
                                  padding: EdgeInsets.only(
                                      top: 5, bottom: 5, left: 10, right: 10),
                                  decoration: BoxDecoration(
                                      color: backgroundColor[1],
                                      borderRadius: BorderRadius.circular(25)),
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
                                      top: 5, bottom: 5, left: 10, right: 10),
                                  decoration: BoxDecoration(
                                      color: backgroundColor[2],
                                      borderRadius: BorderRadius.circular(25)),
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
                    ),
                    child: Container(
                        margin: EdgeInsets.only(right: 20, left: 20),
                        padding: EdgeInsets.only(top: 30, bottom: 10),
                        child: FutureBuilder<List<MaintenanceDeviceModel>>(
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
                        ))),
              )
            ],
          ),
        ));
  }
}
