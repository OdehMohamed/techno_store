import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/features/maintenance_list/view_model/maintenance_list_state.dart';
import 'package:techno_store/core/new_device_maintenance/view/new_device_maintenance.dart';
import 'package:techno_store/core/shared/model/maintenance_device_model.dart';
import 'package:techno_store/core/shared/view_model/shared_state.dart';
import 'package:techno_store/core/utils/color_utilities.dart';
import 'package:techno_store/core/utils/utilities.dart';

import '../../../core/utils/widget_utilities.dart';

class InnerMaintenanceList extends StatefulWidget {
  const InnerMaintenanceList({Key? key}) : super(key: key);

  @override
  State<InnerMaintenanceList> createState() => _InnerMaintenanceListState();
}

class _InnerMaintenanceListState extends State<InnerMaintenanceList> {
  String theStatus = "Fixed";
  List<Color> backgroundColor = [
    AppColors.primary,
    AppColors.white,
    AppColors.white,
  ];
  List<Color> textColor = [
    AppColors.white,
    AppColors.primary,
    AppColors.primary,
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
            AppColors.primary,
            AppColors.white,
            AppColors.white,
          ];
          textColor = [
            AppColors.white,
            AppColors.primary,
            AppColors.primary,
          ];
          break;
        }
      case 1:
        {
          theStatus = "in maintenance";
          backgroundColor = [
            AppColors.white,
            AppColors.primary,
            AppColors.white,
          ];
          textColor = [
            AppColors.primary,
            AppColors.white,
            AppColors.primary,
          ];
          break;
        }
      case 2:
        {
          theStatus = "Delivered";
          backgroundColor = [
            AppColors.white,
            AppColors.white,
            AppColors.primary,
          ];
          textColor = [
            AppColors.primary,
            AppColors.primary,
            AppColors.white,
          ];
          break;
        }
      default:
        {
          theStatus = "Fixed";
          backgroundColor = [
            AppColors.primary,
            AppColors.white,
            AppColors.white,
          ];
          textColor = [
            AppColors.white,
            AppColors.primary,
            AppColors.primary,
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
            statusIcon = const Icon(Icons.done, color: Colors.green);
            break;
          }
        case "Delivered":
          {
            statusIcon = const Icon(Icons.done_all, color: Colors.green);
            break;
          }
        default:
          {
            statusIcon = const Icon(
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
          margin: const EdgeInsets.only(top: 10),
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
                  SizedBox(
                    width: width * 0.67,
                    child: Row(
                      children: [
                        WidgetUtilities.autoSizeText(device.customerName!,
                            textStyle: const TextStyle(color: Colors.black)),
                        Flexible(child: Container()),
                        statusIcon,
                        const SizedBox(
                          width: 5,
                        ),
                        WidgetUtilities.autoSizeText(device.status!,
                            textStyle: const TextStyle(color: Colors.black54))
                      ],
                    ),
                  ),
                  SizedBox(
                    width: width * 0.67,
                    child: Row(
                      children: [
                        WidgetUtilities.autoSizeText(device.deviceModel!,
                            textStyle: const TextStyle(color: Colors.black54))
                      ],
                    ),
                  ),
                  SizedBox(
                    width: width * 0.67,
                    child: Row(
                      children: [
                        Row(
                          children: [
                            WidgetUtilities.autoSizeText(device.estimatedTime!,
                                textStyle:
                                    const TextStyle(color: Colors.black54)),
                          ],
                        ),
                        Flexible(child: Container()),
                        Row(
                          children: [
                            WidgetUtilities.autoSizeText(device.price!,
                                textStyle:
                                    const TextStyle(color: Colors.black54)),
                            WidgetUtilities.autoSizeText("ILS",
                                textStyle:
                                    const TextStyle(color: Colors.black54)),
                          ],
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
              NewDeviceMaintenance(
                maintenanceDevice: device,
                editable: true,
              ));
        },
      );
    }

    return Scaffold(
        floatingActionButton: sharedState.userType != 1
            ? FloatingActionButton(
                child: const Icon(
                  Icons.add,
                  color: AppColors.primary,
                ),
                backgroundColor: AppColors.white,
                onPressed: () {
                  Utilities.navigatorWithBack(
                      context,
                      const NewDeviceMaintenance(
                        editable: false,
                      ));
                },
              )
            : null,
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              maintenanceListState = context.read<MaintenanceListState>();
              sharedState = context.read<SharedState>();
              deviceList =
                  maintenanceListState.getDevicesInMaintenance(theStatus);
            });
          },
          child: Container(
              margin: const EdgeInsets.only(right: 20, left: 20),
              padding: const EdgeInsets.only(top: 30, bottom: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        child: Container(
                          padding: EdgeInsets.only(
                            top: 10,
                            bottom: 10,
                            left: width * 0.02,
                            right: width * 0.02,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 2,
                              color: AppColors.primary,
                            ),
                            color: backgroundColor[0],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: WidgetUtilities.autoSizeText(
                            "Fixed",
                            textStyle:
                                TextStyle(color: textColor[0], fontSize: 18),
                          ),
                        ),
                        onTap: () {
                          changeStatus(0);
                          setState(() {});
                        },
                      ),
                      InkWell(
                        child: Container(
                          margin: const EdgeInsets.only(left: 5, right: 5),
                          padding: EdgeInsets.only(
                            top: 10,
                            bottom: 10,
                            left: width * 0.02,
                            right: width * 0.02,
                          ),
                          decoration: BoxDecoration(
                              border: Border.all(
                                width: 2,
                                color: AppColors.primary,
                              ),
                              color: backgroundColor[1],
                              borderRadius: BorderRadius.circular(12)),
                          child: WidgetUtilities.autoSizeText(
                            "in maintenance",
                            textStyle:
                                TextStyle(color: textColor[1], fontSize: 18),
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
                            top: 10,
                            bottom: 10,
                            left: width * 0.02,
                            right: width * 0.02,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 2,
                              color: AppColors.primary,
                            ),
                            color: backgroundColor[2],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: WidgetUtilities.autoSizeText(
                            "Delivered",
                            textStyle:
                                TextStyle(color: textColor[2], fontSize: 18),
                          ),
                        ),
                        onTap: () {
                          changeStatus(2);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: FutureBuilder<List<MaintenanceDeviceModel>>(
                      future: deviceList,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: SizedBox(
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
                    ),
                  )
                ],
              )),
        ));
  }
}
