import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/shared/model/brand_model.dart';
import 'package:techno_store/core/track_phone_page/view_model/track_phone_page_state.dart';
import 'package:techno_store/core/utils/color_utilities.dart';

import '../../utils/widget_utilities.dart';
import '../../shared/model/maintenance_device_model.dart';
import '../../shared/view_model/shared_state.dart';
import '../../track_device_details/view/trackDeviceDetails.dart';

class TrackPhonePage extends StatefulWidget {
  const TrackPhonePage({Key? key}) : super(key: key);

  @override
  State<TrackPhonePage> createState() => _TrackPhonePageState();
}

class _TrackPhonePageState extends State<TrackPhonePage> {
  bool phoneValid = false;
  String phoneCode = "+970";
  PhoneNumber number = PhoneNumber(isoCode: 'PS');
  final phoneController = TextEditingController();
  late SharedState sharedState;
  late TrackPhonePageState trackPhonePageState;
  late bool? isTesting;

  @override
  void initState() {
    sharedState = context.read<SharedState>();
    trackPhonePageState = context.read<TrackPhonePageState>();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      getTestingValue();
    }
    super.initState();
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void getTestingValue() async {
    isTesting = await sharedState.isTesting();
    print(isTesting);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    trackPhonePageState = context.watch<TrackPhonePageState>();
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
                        Container(
                          child: Row(
                            children: [
                              WidgetUtilities.autoSizeText(
                                  device.estimatedTime!,
                                  textStyle:
                                      const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                        Flexible(child: Container()),
                        Container(
                          child: Row(
                            children: [
                              WidgetUtilities.autoSizeText(device.price!,
                                  textStyle:
                                      const TextStyle(color: Colors.black54)),
                              WidgetUtilities.autoSizeText("ILS",
                                  textStyle:
                                      const TextStyle(color: Colors.black54)),
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
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TrackDeviceDetails(
                      maintenanceDevice: device,
                    )),
          );
        },
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: WidgetUtilities.autoSizeText("Tracking"),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Column(
          children: [
            Container(
              color: ColorUtilities.backgroundContainer,
              child: Container(
                  padding: EdgeInsets.only(top: height * 0.1),
                  width: width,
                  height: height * 0.1,
                  decoration: const BoxDecoration(
                    color: ColorUtilities.secondary,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [],
                  )),
            ),
            Container(
              color: ColorUtilities.secondary,
              child: Container(
                  width: width,
                  height: height * 0.9,
                  decoration: const BoxDecoration(
                    color: ColorUtilities.backgroundContainer,
                  ),
                  child: Container(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: height * 0.05,
                        ),
                        WidgetUtilities.autoSizeText(
                            "From Here You can track your mobile",
                            textAlign: TextAlign.center,
                            textStyle: const TextStyle(color: Colors.black)),
                        SizedBox(
                          height: height * 0.03,
                        ),
                        defaultTargetPlatform == TargetPlatform.iOS
                            ? FutureBuilder<bool>(
                                future: sharedState.isTesting(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      (snapshot.data ?? false)) {
                                    return Column(
                                      children: [
                                        WidgetUtilities.autoSizeText(
                                            "Apple warranty",
                                            textAlign: TextAlign.center,
                                            textStyle: const TextStyle(
                                                color: Colors.red),
                                            maxLine: 2),
                                        SizedBox(
                                          height: height * 0.07,
                                        ),
                                      ],
                                    );
                                  } else {
                                    return const SizedBox();
                                  }
                                })
                            : const SizedBox(),
                        InternationalPhoneNumberInput(
                          errorMessage: "Invalid phone number".tr(),
                          hintText: "Phone number".tr(),
                          onInputChanged: (PhoneNumber number) {
                            phoneCode = number.dialCode!;
                          },
                          onInputValidated: (bool value) {
                            phoneValid = value;
                          },
                          selectorConfig: const SelectorConfig(
                            selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                          ),
                          ignoreBlank: false,
                          autoValidateMode: AutovalidateMode.always,
                          selectorTextStyle:
                              const TextStyle(color: Colors.black),
                          initialValue: number,
                          textFieldController: phoneController,
                          formatInput: false,
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: true,
                            decimal: true,
                          ),
                          inputBorder: const OutlineInputBorder(),
                        ),
                        SizedBox(height: height * 0.1),
                        ElevatedButton(
                          onPressed: () async {
                            if (phoneValid) {
                              showModalBottomSheet(
                                context: context,
                                builder: (BuildContext context) {
                                  return FutureBuilder<
                                          List<MaintenanceDeviceModel>>(
                                      future: trackPhonePageState
                                          .checkDeviceStatus(phoneCode +
                                              "-" +
                                              phoneController.text),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return Container(
                                            child:
                                                const CircularProgressIndicator(),
                                            height: height * 0.7,
                                            margin: EdgeInsets.all(width * 0.4),
                                          );
                                        } else if (snapshot.data!.isEmpty) {
                                          return Center(
                                            child: Text("No Data".tr()),
                                          );
                                        } else if (snapshot.hasData) {
                                          List<MaintenanceDeviceModel> devices =
                                              snapshot.data as List<
                                                  MaintenanceDeviceModel>;
                                          return ListView.builder(
                                              itemCount: devices.length,
                                              itemBuilder: (context, index) {
                                                return card(devices[index]);
                                              });
                                        } else {
                                          return Center(
                                            child: Text("Error".tr()),
                                          );
                                        }
                                      });
                                },
                              );
                            }
                          },
                          child: SizedBox(
                              width: width * 0.4,
                              height: height * 0.07,
                              child: Center(
                                child: WidgetUtilities.autoSizeText(
                                  "Check Status",
                                  textAlign: TextAlign.center,
                                ),
                              )),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorUtilities.secondary,
                            textStyle: const TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  )),
            )
          ],
        ),
      ),
    );
  }
}
