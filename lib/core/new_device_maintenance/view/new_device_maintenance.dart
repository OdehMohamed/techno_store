import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:pattern_lock/pattern_lock.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/new_device_maintenance/view_model/new_device_maintenance_state.dart';
import 'package:techno_store/core/shared/model/brand_model.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/custom_widgets.dart';
import '../../../shared/message.dart';
import '../../../shared/widget_utilities.dart';
import '../../shared/model/maintenance_device_model.dart';
import '../../shared/view_model/shared_state.dart';

class NewDeviceMaintanace extends StatefulWidget {
  final MaintenanceDeviceModel? maintenanceDevice;
  final bool editable;
  NewDeviceMaintanace(
      {Key? key,
      manageCategory,
      this.maintenanceDevice,
      required this.editable})
      : super(key: key);

  @override
  State<NewDeviceMaintanace> createState() => _NewDeviceMaintanaceState();
}

class _NewDeviceMaintanaceState extends State<NewDeviceMaintanace> {
  List<int> patternList = [];
  List<int> drawingList = [];
  int i = 0;
  Timer? timer;
  Timer? secondTimer;
  final _formKey = GlobalKey<FormState>();

  late SharedState sharedState;
  late Future getBrandsFuture;
  BrandModel? selectedBrand;
  var problem = [
    "not working",
    "screen",
    "battery",
    "charging base",
    "service",
    "check",
    "selfie camera",
    "main camera",
    "internal headset",
    "external headset",
    "microphone",
    "touch screen",
    "fingerprint",
    "device back",
    "software",
    "open gmail",
    "open icloud",
    "volume button",
    "power button"
  ];
  String? selectedProblem;
  var times = [
    "30 min",
    "1 Hour",
    "2 Hours",
    "3 Hours",
    "4 Hours",
    "5 Hours",
    "6 Hours",
    "7 Hours",
    "8 Hours",
    "not determined"
  ];
  String? selectedTime;
  var status = ["Fixed", "in maintenance"];
  final name_controller = TextEditingController();
  final address_controller = TextEditingController();
  final phone_controller = TextEditingController();
  final model_controller = TextEditingController();
  final color_controller = TextEditingController();
  final IMEI_controller = TextEditingController();
  final pin_controller = TextEditingController();
  final notes_controller = TextEditingController();
  final price_controller = TextEditingController();
  final notes2_controller = TextEditingController();
  final pre_check_list_scratches_controller=TextEditingController();
  final pre_check_list_cracks_controller=TextEditingController();
  final pre_check_list_liquid_controller=TextEditingController();
  final pre_check_list_missing_parts_controller=TextEditingController();
  final pre_check_list_others_controller=TextEditingController();
  final replaced_part_controller=TextEditingController();

  List<bool> accessories =[
    false,false,false,false,false,false,false,false
  ];
  List<bool> pre_check_list =[
    false,false,false,false,false
  ];
  List<String> pre_check_list_notes =[

  ];
  late NewDeviceMaintenanceState newDeviceMaintenanceState;
  List<int> patternValue = [];
  String? status_value;
  late bool phoneValid;
  String phoneCode = "+970";
  late PhoneNumber number;

  //false = can edit , true = can't edit (disabled)
  bool name_priv = false;
  bool address_priv = false;
  bool phone_priv = false;
  bool model_priv = false;
  bool color_priv = false;
  bool IMEI_priv = false;
  bool pin_priv = false;
  bool problem_priv = false;
  bool notes_priv = false;
  bool accessoires_priv = false;
  bool price_priv = false;
  bool estimated_time_priv = false;
  bool notes2_priv = false;
  bool status_priv = false;
  bool brand_priv = false;
  bool check_list_priv=false;
  void privilagesManager() {
    if (sharedState.userType==3){
      pin_priv=true;
      return;
    }
    name_priv = true;
    address_priv = true;
    phone_priv = true;
    model_priv = true;
    color_priv = true;
    IMEI_priv = true;
    pin_priv = true;
    accessoires_priv = true;
    brand_priv = true;
    check_list_priv=true;
    if (sharedState.userType == 0) {
      problem_priv = true;
      notes_priv = true;
      notes2_priv = true;
      price_priv = true;
      estimated_time_priv = true;
      status_priv = true;
    }
  }

  @override
  void initState() {
    super.initState();
    newDeviceMaintenanceState = context.read<NewDeviceMaintenanceState>();
    sharedState = context.read<SharedState>();
    getBrandsFuture = sharedState.getBrands();

    if (widget.editable != null && widget.editable) {
      pre_check_list_scratches_controller.text=widget.maintenanceDevice!.preCheckListNotes![0];
      pre_check_list_cracks_controller.text=widget.maintenanceDevice!.preCheckListNotes![1];
      pre_check_list_liquid_controller.text=widget.maintenanceDevice!.preCheckListNotes![2];
      pre_check_list_missing_parts_controller.text=widget.maintenanceDevice!.preCheckListNotes![3];
      pre_check_list_others_controller.text=widget.maintenanceDevice!.preCheckListNotes![4];
      pre_check_list=widget.maintenanceDevice!.preCheckList!;
      name_controller.text = widget.maintenanceDevice!.customerName!;
      address_controller.text = widget.maintenanceDevice!.address!;
      replaced_part_controller.text=widget.maintenanceDevice!.replaceParts!;
      String phone = widget.maintenanceDevice!.phoneNumber!.split("-").last;
      phoneCode = widget.maintenanceDevice!.phoneNumber!.split("-").first;
      number = PhoneNumber(
          dialCode: phoneCode,
          isoCode: PhoneNumber.getISO2CodeByPrefix(phoneCode),
          phoneNumber: phone);
      model_controller.text = widget.maintenanceDevice!.deviceModel!;
      color_controller.text = widget.maintenanceDevice!.color!;
      IMEI_controller.text = widget.maintenanceDevice!.imeiNumber!;
      pin_controller.text = widget.maintenanceDevice!.devicePassword!;
      selectedProblem = widget.maintenanceDevice!.problem!;
      notes_controller.text = widget.maintenanceDevice!.problemNotes!;
      accessories= widget.maintenanceDevice!.accessories!;
      price_controller.text = widget.maintenanceDevice!.price!;
      selectedTime = widget.maintenanceDevice!.estimatedTime!;
      notes2_controller.text = widget.maintenanceDevice!.notes!;
      patternList = widget.maintenanceDevice!.pattern!;
      status_value = widget.maintenanceDevice!.status;
      privilagesManager();
    } else {
      phoneValid = false;
      phoneCode = "+970";
      number = PhoneNumber(isoCode: 'PS');
      i = 0;
      patternList = [];
    }
  }

  void draw() {
    if (patternList.isEmpty) {
      timer?.cancel();
      secondTimer?.cancel();
      return;
    }
    drawingList.add(patternList[i]);
    i++;
    if (i == patternList.length) {
      timer?.cancel();
    }
    print(drawingList);
  }

  startDraw() {
    i = 0;
    drawingList = [];
    timer = Timer.periodic(Duration(milliseconds: 500), (Timer t) {
      draw();
    });
  }

  @override
  void dispose() {
    name_controller.dispose();
    address_controller.dispose();
    phone_controller.dispose();
    model_controller.dispose();
    color_controller.dispose();
    IMEI_controller.dispose();
    pin_controller.dispose();
    notes_controller.dispose();
    price_controller.dispose();
    notes2_controller.dispose();
    pre_check_list_scratches_controller.dispose();
    pre_check_list_cracks_controller.dispose();
    pre_check_list_liquid_controller.dispose();
    pre_check_list_missing_parts_controller.dispose();
    pre_check_list_others_controller.dispose();
    replaced_part_controller.dispose();
    timer?.cancel();
    secondTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    newDeviceMaintenanceState = context.watch<NewDeviceMaintenanceState>();
    sharedState = context.watch<SharedState>();

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),
        extendBodyBehindAppBar: true,
        body: SingleChildScrollView(
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
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
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(50),
                        ),
                      ),
                      child: Center(
                          child: WidgetUtilities.autoSizeText(
                              "Device Maintenance",
                              textStyle: TextStyle(
                                  color: ColorUtilities.textColor,
                                  fontSize: 20)))),
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
                        margin: EdgeInsets.all(30),
                        child: SingleChildScrollView(
                            child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                height: 30,
                              ),
                              WidgetUtilities.autoSizeText(
                                  "Customer Information",
                                  textStyle: TextStyle(color: Colors.black)),
                              SizedBox(
                                height: 30,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                  enabled: !name_priv,
                                  controller: name_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    label: Row(children: [
                                      Text("Name".tr()),
                                      Text(" *",style: TextStyle(color: Colors.red),),
                                    ]),
                                    labelStyle: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter".tr() +
                                          " " +
                                          "Name".tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: InternationalPhoneNumberInput(
                                  isEnabled: !phone_priv,
                                  hintText: "Phone number".tr(),
                                  errorMessage: "Invalid phone number".tr(),
                                  onInputChanged: (PhoneNumber number) {
                                    phoneCode = number.dialCode!;
                                  },
                                  onInputValidated: (bool value) {
                                    phoneValid = value;
                                  },
                                  selectorConfig: SelectorConfig(
                                    selectorType:
                                        PhoneInputSelectorType.BOTTOM_SHEET,
                                  ),
                                  ignoreBlank: false,
                                  autoValidateMode: AutovalidateMode.always,
                                  selectorTextStyle:
                                      TextStyle(color: Colors.black),
                                  initialValue: number,
                                  textFieldController: phone_controller,
                                  formatInput: false,
                                  keyboardType: TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                                  inputBorder: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                  enabled: !address_priv,
                                  controller: address_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    label: Row(children: [
                                      Text("Address".tr()),
                                      Text(" *",style: TextStyle(color: Colors.red),),
                                    ]),
                                    labelStyle: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter".tr() +
                                          " " +
                                          "Address".tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              Divider(
                                thickness: 1,
                                color: Colors.black,
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              WidgetUtilities.autoSizeText("Device Information",
                                  textStyle: TextStyle(color: Colors.black)),
                              SizedBox(
                                height: 30,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: FutureBuilder(
                                    future: getBrandsFuture,
                                    builder: (context, AsyncSnapshot snapshot) {
                                      if (snapshot.hasData) {
                                        List<BrandModel> futureBrands =
                                            snapshot.data;
                                        if (widget.editable &&
                                            selectedBrand == null) {
                                          for (int i = 0;
                                              i < futureBrands.length;
                                              i++) {
                                            if (futureBrands[i].name ==
                                                widget.maintenanceDevice!
                                                    .brandID) {
                                              selectedBrand = futureBrands[i];
                                              break;
                                            }
                                          }
                                        }
                                        return FormValidatorDropdown<
                                            BrandModel>(
                                          name: "BrandName",
                                          dropDownValue: selectedBrand,
                                          onChanged: !brand_priv
                                              ? (newValue) {
                                                  selectedBrand = newValue;
                                                  setState(() {});
                                                }
                                              : null,
                                          items: List.generate(
                                              futureBrands.length,
                                              (index) =>
                                                  DropdownMenuItem<BrandModel>(
                                                    value: futureBrands[index],
                                                    child: Text(
                                                        futureBrands[index]
                                                            .name!),
                                                  )),
                                          label: "Device Brand".tr()+ " * ",
                                        );
                                      }
                                      return SizedBox();
                                    }),
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                  enabled: !model_priv,
                                  controller: model_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    label: Row(children: [
                                      Text("Device Model".tr()),
                                      Text(" *",style: TextStyle(color: Colors.red),),
                                    ]),
                                    labelStyle: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter".tr() +
                                          " " +
                                          "Device Model".tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                  enabled: !color_priv,
                                  controller: color_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    label: Row(children: [
                                      Text("Color".tr()),
                                      Text(" *",style: TextStyle(color: Colors.red),),
                                    ]),
                                    labelStyle: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter".tr() +
                                          " " +
                                          "Color".tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextField(
                                  enabled: !IMEI_priv,
                                  controller: IMEI_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    labelText: 'IMEI Number'.tr(),
                                    labelStyle: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                  decoration: BoxDecoration(
                                    color: ColorUtilities.white,
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(5),
                                        bottomLeft: Radius.circular(5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: width * 0.5,
                                        child: TextField(
                                          enabled: !pin_priv,
                                          controller: pin_controller,
                                          style: TextStyle(color: Colors.black),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            labelText: 'PIN'.tr(),
                                            labelStyle: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 16),
                                          ),
                                        ),
                                      ),
                                      Flexible(child: Container()),
                                      InkWell(
                                        child: Container(
                                          width: width * 0.2,
                                          height: height * 0.09,
                                          color: Colors.green,
                                          child: Center(
                                            child: WidgetUtilities.autoSizeText(
                                              "Pattern".tr(),
                                            ),
                                          ),
                                        ),
                                        onTap: () async {
                                          secondTimer = null;
                                          startDraw();
                                          await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return StatefulBuilder(builder:
                                                  (context,
                                                      StateSetter setState) {
                                                if (secondTimer == null) {
                                                  secondTimer = Timer.periodic(
                                                      Duration(
                                                          milliseconds: 500),
                                                      (Timer t) {
                                                    setState(() {});
                                                  });
                                                }
                                                if (drawingList.length ==
                                                    patternList.length) {
                                                  setState(() {});
                                                  secondTimer?.cancel();
                                                }
                                                return AlertDialog(
                                                    backgroundColor:
                                                        ColorUtilities.white,
                                                    content: Container(
                                                      height: height * 0.5,
                                                      width: width,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: [
                                                          Container(
                                                              height:
                                                                  height * 0.4,
                                                              width: width,
                                                              child:
                                                                  AbsorbPointer(
                                                                absorbing: widget
                                                                    .editable,
                                                                child:
                                                                    PatternLock(
                                                                  selectedColor:
                                                                      Colors
                                                                          .blue,
                                                                  pointRadius:
                                                                      8,
                                                                  showInput:
                                                                      true,
                                                                  dimension: 3,
                                                                  relativePadding:
                                                                      0.7,
                                                                  selectThreshold:
                                                                      25,
                                                                  fillPoints:
                                                                      true,
                                                                  onInputComplete:
                                                                      (List<int>
                                                                          input) {
                                                                    patternValue =
                                                                        input;
                                                                    print(
                                                                        patternValue);
                                                                  },
                                                                  setUsed:
                                                                      drawingList,
                                                                ),
                                                              )),
                                                          InkWell(
                                                            child: Container(
                                                                width:
                                                                    width * 0.2,
                                                                height: height *
                                                                    0.05,
                                                                decoration: BoxDecoration(
                                                                    color: Colors
                                                                        .green,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            5)),
                                                                child: Center(
                                                                  child: WidgetUtilities
                                                                      .autoSizeText(
                                                                    "Save".tr(),
                                                                  ),
                                                                )),
                                                            onTap: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          )
                                                        ],
                                                      ),
                                                    ));
                                              });
                                            },
                                          );
                                        },
                                      )
                                    ],
                                  )),
                              SizedBox(
                                height: 30,
                              ),
                              Divider(
                                thickness: 1,
                                color: Colors.black,
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              WidgetUtilities.autoSizeText(
                                  "Maintenance Information",
                                  textStyle: TextStyle(color: Colors.black)),
                              SizedBox(
                                height: 30,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: DropdownButtonFormField(
                                  isExpanded: true,
                                  value: selectedProblem,
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    label: Row(
                                      children: [
                                        Text("The problem".tr()),
                                        Text(" * ",style: TextStyle(color: Colors.red),)
                                      ],
                                    ),
                                    border: InputBorder.none,
                                    labelStyle: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                  items: problem.map((String problem_value) {
                                    return DropdownMenuItem(
                                      value: problem_value,
                                      child: WidgetUtilities.autoSizeText(
                                          problem_value,
                                          textStyle:
                                          TextStyle(color: Colors.black)),
                                    );
                                  }).toList(),
                                  onChanged: !problem_priv
                                      ? (String? newValue) {
                                    setState(() {
                                      selectedProblem = newValue!;
                                    });
                                  }
                                      : null,
                                  validator: (value) {
                                    if (value == null) {
                                      return "Please Enter".tr() +
                                          " " +
                                          "The problem".tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: DropdownButtonFormField(
                                  isExpanded: true,
                                  value: status_value,
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    label: Row(
                                      children: [
                                        Text("Device Status".tr()),
                                        Text(" * ",style: TextStyle(color: Colors.red),)
                                      ],
                                    ),
                                    border: InputBorder.none,
                                    labelStyle: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                  items: status.map((String status) {
                                    return DropdownMenuItem(
                                      value: status,
                                      child: WidgetUtilities.autoSizeText(
                                          status,
                                          textStyle:
                                              TextStyle(color: Colors.black)),
                                    );
                                  }).toList(),
                                  onChanged: !status_priv
                                      ? (String? newValue) {
                                          setState(() {
                                            status_value = newValue!;
                                          });
                                        }
                                      : null,
                                  validator: (value) {
                                    if (value == null) {
                                      return "Please Enter".tr() +
                                          " " +
                                          "Device Status".tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                height: 100,
                                padding: EdgeInsets.only(left: 10, right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextField(
                                  enabled: !notes_priv,
                                  controller: notes_controller,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    labelText: 'Notes'.tr() + "(hidden)".tr(),
                                    labelStyle: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10, right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child:  Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 10,),
                                    Text("Accessories".tr(),style: TextStyle(color: Colors.grey)),
                                    Table(
                                      children: [
                                        TableRow(
                                          children: [
                                            CheckboxListTile(
                                              enabled: !accessoires_priv,
                                              title: Text("pen".tr()),
                                              value: accessories[0],
                                              onChanged: (newValue) {
                                                setState(() {
                                                  accessories[0]=newValue!;
                                                });
                                              },
                                              controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                                            ),
                                            CheckboxListTile(
                                              enabled: !accessoires_priv,
                                              title: Text("battery".tr()),
                                              value: accessories[1],
                                              onChanged: (newValue) {
                                                setState(() {
                                                  accessories[1]=newValue!;
                                                });
                                              },
                                              controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                                            ),
                                          ]
                                        ),
                                        TableRow(
                                          children: [
                                            CheckboxListTile(
                                              enabled: !accessoires_priv,
                                              title: Text("cover".tr()),
                                              value: accessories[2],
                                              onChanged: (newValue) {
                                                setState(() {
                                                  accessories[2]=newValue!;
                                                });
                                              },
                                              controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                                            ),
                                            CheckboxListTile(
                                              enabled: !accessoires_priv,
                                              title: Text("sd card".tr()),
                                              value:  accessories[3],
                                              onChanged: (newValue) {
                                                setState(() {
                                                  accessories[3]=newValue!;
                                                });
                                              },
                                              controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                                            ),
                                          ]
                                        ),
                                        TableRow(
                                            children: [
                                              CheckboxListTile(
                                                enabled: !accessoires_priv,
                                                title: Text("sim card".tr()),
                                                value:  accessories[4],
                                                onChanged: (newValue) {
                                                  setState(() {
                                                    accessories[4]=newValue!;
                                                  });
                                                },
                                                controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                                              ),
                                              CheckboxListTile(
                                                enabled: !accessoires_priv,
                                                title: Text("device box".tr()),
                                                value:  accessories[5],
                                                onChanged: (newValue) {
                                                  setState(() {
                                                    accessories[5]=newValue!;
                                                  });
                                                },
                                                controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                                              ),
                                            ]
                                        ),
                                        TableRow(
                                            children: [
                                              CheckboxListTile(
                                                enabled: !accessoires_priv,
                                                title: Text("charger".tr()),
                                                value:  accessories[6],
                                                onChanged: (newValue) {
                                                  setState(() {
                                                    accessories[6]=newValue!;
                                                  });
                                                },
                                                controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                                              ),
                                              CheckboxListTile(
                                                enabled: !accessoires_priv,
                                                title: Text("headphones".tr()),
                                                value:  accessories[7],
                                                onChanged: (newValue) {
                                                  setState(() {
                                                    accessories[7]=newValue!;
                                                  });
                                                },
                                                controlAffinity: ListTileControlAffinity.leading,  //  <-- leading Checkbox
                                              ),
                                            ]
                                        )
                                      ],
                                    ),
                                  ],
                                )
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                  padding: EdgeInsets.only(left: 10, right: 10),
                                  decoration: BoxDecoration(
                                    color: ColorUtilities.white,
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child:  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 10,),
                                      Text("Device status when received".tr(),style: TextStyle(color: Colors.grey)),
                                      Table(
                                        children: [
                                          TableRow(
                                              children: [
                                                CheckboxListTile(
                                                  enabled: !check_list_priv,
                                                  title: Text("scratches".tr()),
                                                  value: pre_check_list[0],
                                                  onChanged: (newValue) {
                                                    setState(() {
                                                      pre_check_list[0]=newValue!;
                                                    });
                                                  },
                                                  controlAffinity: ListTileControlAffinity.trailing,  //  <-- leading Checkbox
                                                ),
                                                TextFormField(
                                                  enabled: !check_list_priv,
                                                  controller: pre_check_list_scratches_controller,
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    labelText: 'Notes'.tr(),
                                                    labelStyle: TextStyle(
                                                        color: Colors.grey, fontSize: 16),
                                                  ),
                                                ),
                                              ]
                                          ),
                                          TableRow(
                                              children: [
                                                CheckboxListTile(
                                                  enabled: !check_list_priv,
                                                  title: Text("Cracks".tr()),
                                                  value: pre_check_list[1],
                                                  onChanged: (newValue) {
                                                    setState(() {
                                                      pre_check_list[1]=newValue!;
                                                    });
                                                  },
                                                  controlAffinity: ListTileControlAffinity.trailing,  //  <-- leading Checkbox
                                                ),
                                                TextFormField(
                                                  enabled: !check_list_priv,
                                                  controller: pre_check_list_cracks_controller,
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    labelText: 'Notes'.tr(),
                                                    labelStyle: TextStyle(
                                                        color: Colors.grey, fontSize: 16),
                                                  ),
                                                ),
                                              ]
                                          ),
                                          TableRow(
                                              children: [
                                                CheckboxListTile(
                                                  enabled: !check_list_priv,
                                                  title: Text("Liquid".tr()),
                                                  value: pre_check_list[2],
                                                  onChanged: (newValue) {
                                                    setState(() {
                                                      pre_check_list[2]=newValue!;
                                                    });
                                                  },
                                                  controlAffinity: ListTileControlAffinity.trailing,  //  <-- leading Checkbox
                                                ),
                                                TextFormField(
                                                  enabled: !check_list_priv,
                                                  controller: pre_check_list_liquid_controller,
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    labelText: 'Notes'.tr(),
                                                    labelStyle: TextStyle(
                                                        color: Colors.grey, fontSize: 16),
                                                  ),
                                                ),
                                              ]
                                          ),
                                          TableRow(
                                              children: [
                                                CheckboxListTile(
                                                  enabled: !check_list_priv,
                                                  title: Text("Missing Parts".tr()),
                                                  value: pre_check_list[3],
                                                  onChanged: (newValue) {
                                                    setState(() {
                                                      pre_check_list[3]=newValue!;
                                                    });
                                                  },
                                                  controlAffinity: ListTileControlAffinity.trailing,  //  <-- leading Checkbox
                                                ),
                                                TextFormField(
                                                  enabled: !check_list_priv,
                                                  controller: pre_check_list_missing_parts_controller,
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    labelText: 'Notes'.tr(),
                                                    labelStyle: TextStyle(
                                                        color: Colors.grey, fontSize: 16),
                                                  ),
                                                ),
                                              ]
                                          ),
                                          TableRow(
                                              children: [
                                                CheckboxListTile(
                                                  enabled: !check_list_priv,
                                                  title: Text("others".tr()),
                                                  value: pre_check_list[4],
                                                  onChanged: (newValue) {
                                                    setState(() {
                                                      pre_check_list[4]=newValue!;
                                                    });
                                                  },
                                                  controlAffinity: ListTileControlAffinity.trailing,  //  <-- leading Checkbox
                                                ),
                                                TextFormField(
                                                  enabled: !check_list_priv,
                                                  controller: pre_check_list_others_controller,
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    labelText: 'Notes'.tr(),
                                                    labelStyle: TextStyle(
                                                        color: Colors.grey, fontSize: 16),
                                                  ),
                                                ),
                                              ]
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: width * 0.4,
                                    padding:
                                        EdgeInsets.only(left: 10, right: 10),
                                    decoration: BoxDecoration(
                                      color: ColorUtilities.white,
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: TextFormField(
                                      enabled: !price_priv,
                                      controller: price_controller,
                                      style: TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        labelText: 'Price'.tr(),
                                        labelStyle: TextStyle(
                                            color: Colors.grey, fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Container(
                                    width: width * 0.4,
                                    padding: EdgeInsets.only(left: 10, right: 10),
                                    decoration: BoxDecoration(
                                      color: ColorUtilities.white,
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: DropdownButtonFormField(
                                      isExpanded: true,
                                      value: selectedTime,
                                      icon: const Icon(Icons.keyboard_arrow_down),
                                      style: TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        label: Row(
                                          children: [
                                            Text("Estimated Time".tr()),
                                            Text(" * ",style: TextStyle(color: Colors.red),)
                                          ],
                                        ),
                                        border: InputBorder.none,
                                        labelStyle: TextStyle(
                                            color: Colors.grey, fontSize: 16),
                                      ),
                                      items: times.map((String time_value) {
                                        return DropdownMenuItem(
                                          value: time_value,
                                          child: WidgetUtilities.autoSizeText(
                                              time_value,
                                              textStyle:
                                              TextStyle(color: Colors.black)),
                                        );
                                      }).toList(),
                                      onChanged: !estimated_time_priv
                                          ? (String? newValue) {
                                        setState(() {
                                          selectedTime = newValue!;
                                        });
                                      }
                                          : null,
                                      validator: (value) {
                                        if (value == null) {
                                          return "Please Enter".tr() +
                                              " " +
                                              "Estimated Time".tr();
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                height: 100,
                                padding: EdgeInsets.only(left: 10, right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextField(
                                  enabled: !notes2_priv,
                                  controller: notes2_controller,
                                  style: TextStyle(color: Colors.black),
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    labelText: 'Notes'.tr(),
                                    labelStyle: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              sharedState.userType==3?
                              Container(
                                height: 100,
                                padding: EdgeInsets.only(left: 10, right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextField(
                                  controller: replaced_part_controller,
                                  style: TextStyle(color: Colors.black),
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    labelText: 'Replaced parts'.tr(),
                                    labelStyle: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                ),
                              )
                                  :SizedBox(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  sharedState.userType != 0
                                      ? ElevatedButton(
                                          onPressed: () {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              if (widget.editable) {
                                                pre_check_list_notes.clear();
                                                pre_check_list_notes.add(pre_check_list_scratches_controller.text);
                                                pre_check_list_notes.add(pre_check_list_cracks_controller.text);
                                                pre_check_list_notes.add(pre_check_list_liquid_controller.text);
                                                pre_check_list_notes.add(pre_check_list_missing_parts_controller.text);
                                                pre_check_list_notes.add(pre_check_list_others_controller.text);
                                                widget.maintenanceDevice?.preCheckListNotes=pre_check_list_notes;
                                                widget.maintenanceDevice?.preCheckList=pre_check_list;
                                                widget.maintenanceDevice?.replacedParts=replaced_part_controller.text;
                                                widget.maintenanceDevice
                                                        ?.customerName =
                                                    name_controller.text;
                                                widget.maintenanceDevice
                                                        ?.phoneNumber =
                                                    phoneCode +
                                                        "-" +
                                                        phone_controller.text;
                                                widget.maintenanceDevice
                                                        ?.address =
                                                    address_controller.text;
                                                widget.maintenanceDevice
                                                        ?.brandID =
                                                    selectedBrand?.name;
                                                widget.maintenanceDevice
                                                        ?.deviceModel =
                                                    model_controller.text;
                                                widget.maintenanceDevice
                                                        ?.color =
                                                    color_controller.text;
                                                widget.maintenanceDevice
                                                        ?.devicePassword =
                                                    pin_controller.text;
                                                widget.maintenanceDevice
                                                        ?.imeiNumber =
                                                    IMEI_controller.text;
                                                widget.maintenanceDevice
                                                        ?.problem =
                                                    selectedProblem;
                                                widget.maintenanceDevice
                                                    ?.status = status_value;
                                                widget.maintenanceDevice
                                                        ?.problemNotes =
                                                    notes_controller.text;
                                                widget.maintenanceDevice
                                                        ?.accessories =
                                                    accessories;
                                                widget.maintenanceDevice
                                                        ?.price =
                                                    price_controller.text;
                                                widget.maintenanceDevice
                                                        ?.estimatedTime =
                                                    selectedTime;
                                                widget.maintenanceDevice
                                                        ?.notes =
                                                    notes2_controller.text;
                                                widget.maintenanceDevice
                                                    ?.pattern = patternList;
                                                newDeviceMaintenanceState
                                                    .editDeviceInMaintenance(
                                                        widget
                                                            .maintenanceDevice!
                                                            .id!,
                                                        widget
                                                            .maintenanceDevice!)
                                                    .then((value) async {
                                                  {
                                                    Message.showLongToastMessage(
                                                        "Edited successfully"
                                                            .tr());
                                                    if (status_value ==
                                                        "Fixed") {
                                                      String message = "Dear Mr/Ms " +
                                                          name_controller.text +
                                                          "\nHello from TECHNO Store team\n\nwe would like to inform you that your device " +
                                                          model_controller
                                                              .text +
                                                          " is Fixed\n\nThank you for choosing TECHNO Store";
                                                      String phone = phoneCode +
                                                          phone_controller.text;
                                                      if (Platform.isAndroid) {
                                                        try {
                                                          bool launched =
                                                              await launch(
                                                                  "whatsapp://send?phone=$phone&text=${Uri.parse(message)}",
                                                                  forceSafariVC:
                                                                      false,
                                                                  forceWebView:
                                                                      false);
                                                          if (!launched) {
                                                            print(
                                                                "inside fallback");
                                                            await launch(
                                                                "whatsapp://send?phone=$phone&text=${Uri.parse(message)}",
                                                                forceSafariVC:
                                                                    false,
                                                                forceWebView:
                                                                    false);
                                                          }
                                                        } catch (e) {
                                                          await launch(
                                                              "whatsapp://send?phone=$phone&text=${Uri.parse(message)}",
                                                              forceSafariVC:
                                                                  false,
                                                              forceWebView:
                                                                  false);
                                                        }
                                                      } else if (Platform
                                                          .isIOS) {
                                                        try {
                                                          bool launched =
                                                              await launch(
                                                                  "whatsapp://send?phone=$phone&text=${Uri.parse(message)}",
                                                                  forceSafariVC:
                                                                      false,
                                                                  forceWebView:
                                                                      false);
                                                          if (!launched) {
                                                            print(
                                                                "inside fallback");
                                                            await launch(
                                                                "whatsapp://send?phone=$phone&text=${Uri.parse(message)}",
                                                                forceSafariVC:
                                                                    false,
                                                                forceWebView:
                                                                    false);
                                                          }
                                                        } catch (e) {
                                                          await launch(
                                                              "whatsapp://send?phone=$phone&text=${Uri.parse(message)}",
                                                              forceSafariVC:
                                                                  false,
                                                              forceWebView:
                                                                  false);
                                                        }
                                                      }
                                                    }
                                                    Navigator.pop(
                                                        context, true);
                                                  }
                                                });
                                              } else {
                                                pre_check_list_notes.clear();
                                                pre_check_list_notes.add(pre_check_list_scratches_controller.text);
                                                pre_check_list_notes.add(pre_check_list_cracks_controller.text);
                                                pre_check_list_notes.add(pre_check_list_liquid_controller.text);
                                                pre_check_list_notes.add(pre_check_list_missing_parts_controller.text);
                                                pre_check_list_notes.add(pre_check_list_others_controller.text);

                                                newDeviceMaintenanceState
                                                    .addDeviceToMaintenance(MaintenanceDeviceModel(
                                                  replacedParts: replaced_part_controller.text,
                                                  preCheckListNotes: pre_check_list_notes,
                                                        preCheckList: pre_check_list,
                                                        customerName:
                                                            name_controller
                                                                .text,
                                                        phoneNumber:
                                                            phoneCode.toString() +
                                                                "-" +
                                                                phone_controller
                                                                    .text,
                                                        address:
                                                            address_controller
                                                                .text,
                                                        brandID:
                                                            selectedBrand?.name,
                                                        deviceModel:
                                                            model_controller
                                                                .text,
                                                        color: color_controller
                                                            .text,
                                                        devicePassword:
                                                            pin_controller.text,
                                                        imeiNumber:
                                                            IMEI_controller
                                                                .text,
                                                        problem:
                                                            selectedProblem,
                                                        status: status_value,
                                                        problemNotes:
                                                            notes_controller
                                                                .text,
                                                        accessories:
                                                            accessories,
                                                        price: price_controller
                                                            .text,
                                                        estimatedTime:
                                                            selectedTime,
                                                        notes: notes2_controller
                                                            .text,
                                                        pattern: patternValue))
                                                    .then((value) {
                                                  Message.showLongToastMessage(
                                                      "Added successfully"
                                                          .tr());
                                                  Navigator.pop(context, true);
                                                });
                                              }
                                            }
                                          },
                                          child: Container(
                                            width: width * 0.2,
                                            child: WidgetUtilities.autoSizeText(
                                              widget.editable
                                                  ? "Save"
                                                  : "Create",
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            primary: ColorUtilities.secondary,
                                            textStyle: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white),
                                          ),
                                        )
                                      : SizedBox(),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(),
                                      width: width * 0.2,
                                      child: WidgetUtilities.autoSizeText(
                                        "Cancel",
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      primary: Color.fromRGBO(128, 128, 128, 1),
                                      textStyle: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 30,
                              ),
                            ],
                          ),
                        )),
                      )),
                )
              ],
            ),
          ),
        ));
  }
}
