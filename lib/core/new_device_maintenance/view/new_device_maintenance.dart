import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:pattern_lock/pattern_lock.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/manage_categories/view/manageCategory.dart';
import 'package:techno_store/core/new_device_maintenance/view_model/new_device_maintenance_state.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/message.dart';
import '../../../shared/widget_utilities.dart';
import '../../shared/model/maintenance_device_model.dart';
List<int> patternList=[];
List<int> drawingList=[];

int i=0;
late Timer? timer;
late Timer? secondTimer;
class NewDeviceMaintanace extends StatefulWidget {
  final MaintenanceDeviceModel? maintenanceDevice;
  final bool editable;
  NewDeviceMaintanace({Key? key,manageCategory, this.maintenanceDevice,required this.editable}) : super(key: key);

  @override
  State<NewDeviceMaintanace> createState() => _NewDeviceMaintanaceState();
}
final _formKey = GlobalKey<FormState>();

class _NewDeviceMaintanaceState extends State<NewDeviceMaintanace> {
  var status = [
    "Fixed",
    "in maintenance",
    "under review"
  ];
  final name_controller = TextEditingController();
  final address_controller = TextEditingController();
  final phone_controller = TextEditingController();
  final model_controller = TextEditingController();
  final color_controller = TextEditingController();
  final IMEI_controller = TextEditingController();
  final pin_controller = TextEditingController();
  final problem_controller = TextEditingController();
  final notes_controller = TextEditingController();
  final accessoires_controller = TextEditingController();
  final price_controller = TextEditingController();
  final estimated_time_controller = TextEditingController();
  final notes2_controller = TextEditingController();

  late NewDeviceMaintenanceState newDeviceMaintenanceState;
  List<int> patternValue=[];
  var brands = [
    'Item 1',
    'Item 2',
    'Item 3',
    'Item 4',
    'Item 5',
  ];
  String? brand_value;
  String? status_value;
  late bool phoneValid ;
  String phoneCode ="+962";
  late PhoneNumber number;
  @override
  void initState() {
    super.initState();
    if (widget.editable!=null && widget.editable){
      name_controller.text = widget.maintenanceDevice!.customerName!;
      address_controller.text = widget.maintenanceDevice!.address!;
      String phone =  widget.maintenanceDevice!.phoneNumber!.split("-").last;
      phoneCode =  widget.maintenanceDevice!.phoneNumber!.split("-").first;
      number=PhoneNumber(dialCode: phoneCode,isoCode: PhoneNumber.getISO2CodeByPrefix(phoneCode),phoneNumber: phone);
      model_controller.text = widget.maintenanceDevice!.deviceModel!;
      color_controller.text = widget.maintenanceDevice!.color!;
      IMEI_controller.text = widget.maintenanceDevice!.imeiNumber!;
      pin_controller.text = widget.maintenanceDevice!.devicePassword!;
      problem_controller.text = widget.maintenanceDevice!.problem!;
      notes_controller.text = widget.maintenanceDevice!.problemNotes!;
      accessoires_controller.text = widget.maintenanceDevice!.accessories!;
      price_controller.text = widget.maintenanceDevice!.price!;
      estimated_time_controller.text = widget.maintenanceDevice!.estimatedTime!;
      notes2_controller.text = widget.maintenanceDevice!.notes!;
      patternList=widget.maintenanceDevice!.pattern!;
      //brand_value=widget.maintenanceDevice!.brandID;
      status_value=widget.maintenanceDevice!.status;
    }
    else{
       phoneValid = false;
       phoneCode = "+962";
       number = PhoneNumber(isoCode: 'JO');
       i=0;
       patternList=[];
    }
  }
  void draw(){
    if (patternList.isEmpty) {
      timer?.cancel();
      secondTimer?.cancel();
      return;
    }
    drawingList.add(patternList[i]);
    i++;
    if (i==patternList.length){
      timer?.cancel();
    }
    print (drawingList);
  }
  startDraw(){
    i=0;
    drawingList=[];
    timer = Timer.periodic(Duration(milliseconds:500), (Timer t) {
      draw();
    }
    );
  }
  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    newDeviceMaintenanceState=context.read<NewDeviceMaintenanceState>();
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
    problem_controller.dispose();
    notes_controller.dispose();
    accessoires_controller.dispose();
    price_controller.dispose();
    estimated_time_controller.dispose();
    notes2_controller.dispose();
    timer?.cancel();
    secondTimer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    newDeviceMaintenanceState=context.watch<NewDeviceMaintenanceState>();

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color:ColorUtilities.backgroundContainer,
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
                      child: WidgetUtilities.autoSizeText("Device Maintenance",textStyle: TextStyle(color: ColorUtilities.textColor,fontSize: 20))
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
                              WidgetUtilities.autoSizeText("Customer Information",textStyle: TextStyle(color: Colors.black)),
                              SizedBox(
                                height: 30,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10,right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                  controller: name_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Name'.tr(),
                                    hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter".tr()+" "+"Name".tr();
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
                                  hintText: "Phone number".tr(),
                                  errorMessage: "Invalid phone number".tr(),
                                  onInputChanged: (PhoneNumber number) {
                                    phoneCode = number.dialCode!;
                                  },
                                  onInputValidated: (bool value) {
                                    phoneValid = value;
                                  },
                                  selectorConfig: SelectorConfig(
                                    selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                                  ),
                                  ignoreBlank: false,
                                  autoValidateMode:
                                  AutovalidateMode.always,
                                  selectorTextStyle: TextStyle(color: Colors.black),
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
                                padding: EdgeInsets.only(left: 10,right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                  controller: address_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Address'.tr(),
                                    hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter".tr()+" "+"Address".tr();
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
                              WidgetUtilities.autoSizeText("Device Information",textStyle: TextStyle(color: Colors.black)),
                              SizedBox(
                                height: 30,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10,right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: DropdownButtonFormField(
                                  isExpanded: true,
                                  hint: WidgetUtilities.autoSizeText("Device Brand",textStyle: TextStyle(color: Colors.grey)),
                                  value: brand_value,
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  items: brands.map((String items) {
                                    return DropdownMenuItem(
                                      value: items,
                                      child: WidgetUtilities.autoSizeText(items,textStyle: TextStyle(color: Colors.black)),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      brand_value = newValue!;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null ) {
                                      return "Please Enter".tr()+" "+"Device Brand".tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 30,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10,right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                  controller: model_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Device Model'.tr(),
                                    hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter".tr()+" "+"Device Model".tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10,right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                  controller: color_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Color'.tr(),
                                    hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter".tr()+" "+"Color".tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10,right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextField(
                                  controller: IMEI_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'IMEI Number'.tr(),
                                    hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
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
                                          controller: pin_controller,
                                          style: TextStyle(color: Colors.black),
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: 'PIN'.tr(),
                                            hintStyle: TextStyle(
                                                color: Colors.grey, fontSize: 16),
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
                                          secondTimer=null;
                                          startDraw();
                                          await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return StatefulBuilder(builder: (context,StateSetter setState){
                                                if( secondTimer==null){
                                                  secondTimer = Timer.periodic(Duration(milliseconds:500), (Timer t) {
                                                    setState(() {});
                                                  });
                                                }
                                                if (drawingList.length==patternList.length){
                                                  setState((){});
                                                  secondTimer?.cancel();
                                                }
                                                return  AlertDialog(
                                                    backgroundColor: ColorUtilities.white,
                                                    content: Container(
                                                      height: height * 0.5,
                                                      width: width,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                        children: [
                                                          Container(
                                                              height: height * 0.4,
                                                              width: width,
                                                              child: AbsorbPointer(
                                                                absorbing: widget.editable,
                                                                child: PatternLock(
                                                                  selectedColor:
                                                                  Colors.blue,
                                                                  pointRadius: 8,
                                                                  showInput: true,
                                                                  dimension: 3,
                                                                  relativePadding: 0.7,
                                                                  selectThreshold: 25,
                                                                  fillPoints: true,
                                                                  onInputComplete:
                                                                      (List<int> input) {
                                                                    patternValue = input;
                                                                    print(patternValue);
                                                                  },
                                                                  setUsed: drawingList,
                                                                ),
                                                              )
                                                          ),
                                                          InkWell(
                                                            child: Container(
                                                                width: width * 0.2,
                                                                height: height * 0.05,
                                                                decoration: BoxDecoration(
                                                                    color: Colors.green,
                                                                    borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                        5)),
                                                                child: Center(
                                                                  child: WidgetUtilities.autoSizeText(
                                                                    "Save".tr(),
                                                                  ),
                                                                )),
                                                            onTap: () {
                                                              Navigator.pop(context);
                                                            },
                                                          )
                                                        ],
                                                      ),
                                                    )
                                                );
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
                              WidgetUtilities.autoSizeText("Maintenance Information",textStyle: TextStyle(color: Colors.black)),
                              SizedBox(
                                height: 30,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10,right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextFormField(
                                  controller: problem_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'The problem'.tr(),
                                    hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please Enter".tr()+" "+"The problem".tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10,right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: DropdownButtonFormField(
                                  isExpanded: true,
                                  hint: WidgetUtilities.autoSizeText("Device Status",textStyle: TextStyle(color: Colors.grey)),
                                  value: status_value,
                                  icon: const Icon(Icons.keyboard_arrow_down),

                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Device Status'.tr(),
                                    hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                  items: status.map((String status) {
                                    return DropdownMenuItem(
                                      value: status,
                                      child: WidgetUtilities.autoSizeText(status,textStyle: TextStyle(color: Colors.black)),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      status_value = newValue!;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null ) {
                                      return "Please Enter".tr()+" "+"Device Brand".tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                padding: EdgeInsets.only(left: 10,right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextField(
                                  controller: notes_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Notes'.tr(),
                                    hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Container(
                                height: 100,
                                padding: EdgeInsets.only(left: 10,right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextField(
                                  controller: accessoires_controller,
                                  style: TextStyle(color: Colors.black),
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Accessories'.tr(),
                                    hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: width * 0.4,
                                    padding: EdgeInsets.only(left: 10,right: 10),
                                    decoration: BoxDecoration(
                                      color: ColorUtilities.white,
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: TextFormField(
                                      controller: price_controller,
                                      style: TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Price'.tr(),
                                        hintStyle: TextStyle(
                                            color: Colors.grey, fontSize: 16),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty ) {
                                          return "Please Enter".tr()+" "+"Price".tr();
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Container(
                                    width: width * 0.4,
                                    padding: EdgeInsets.only(left: 10,right: 10),
                                    decoration: BoxDecoration(
                                      color: ColorUtilities.white,
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: TextFormField(
                                      controller: estimated_time_controller,
                                      style: TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Estimated Time'.tr(),
                                        hintStyle: TextStyle(
                                            color: Colors.grey, fontSize: 16),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Please Enter".tr()+" "+"Estimated Time".tr();
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
                                padding: EdgeInsets.only(left: 10,right: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: TextField(
                                  controller: notes2_controller,
                                  style: TextStyle(color: Colors.black),
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Notes'.tr(),
                                    hintStyle:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        if (widget.editable) {
                                          widget.maintenanceDevice?.customerName=name_controller.text;
                                          widget.maintenanceDevice?.phoneNumber=phoneCode+"-"+phone_controller.text;
                                          widget.maintenanceDevice?.address=address_controller.text;
                                          //brandID: brand_value,
                                          widget.maintenanceDevice?.deviceModel=model_controller.text;
                                          widget.maintenanceDevice?.color=color_controller.text;
                                          widget.maintenanceDevice?.devicePassword=pin_controller.text;
                                          widget.maintenanceDevice?.imeiNumber=IMEI_controller.text;
                                          widget.maintenanceDevice?.problem=problem_controller.text;
                                          widget.maintenanceDevice?.status=status_value;
                                          widget.maintenanceDevice?.problemNotes=notes_controller.text;
                                          widget.maintenanceDevice?.accessories=accessoires_controller.text;
                                          widget.maintenanceDevice?.price=price_controller.text;
                                          widget.maintenanceDevice?.estimatedTime=estimated_time_controller.text;
                                          widget.maintenanceDevice?.notes=notes2_controller.text;
                                          widget.maintenanceDevice?.pattern=patternList;
                                          newDeviceMaintenanceState.editDeviceInMaintenance(
                                              widget.maintenanceDevice!.id!,
                                              widget.maintenanceDevice!
                                          ).then((value) async {
                                            {
                                              Message.showLongToastMessage(
                                                  "Edited successfully".tr());
                                              if (status_value=="Fixed"){
                                                String message = "Dear Mr/Ms " +name_controller.text+ "\nHello from TECHNO Store team\n\nwe would like to inform you that your device "+ model_controller.text +" is Fixed\n\nThank you for choosing TECHNO Store";
                                                String phone = phoneCode+phone_controller.text;
                                                if (Platform.isAndroid) {
                                                  try {
                                                    bool launched =
                                                    await launch(
                                                        "whatsapp://send?phone=$phone&text=${Uri.parse(message)}",
                                                        forceSafariVC: false,
                                                        forceWebView: false);
                                                    if (!launched) {
                                                      print("inside fallback");
                                                      await launch(
                                                          "whatsapp://send?phone=$phone&text=${Uri.parse(message)}",
                                                          forceSafariVC: false,
                                                          forceWebView: false);
                                                    }
                                                  } catch (e) {
                                                    await launch(
                                                        "whatsapp://send?phone=$phone&text=${Uri.parse(message)}",
                                                        forceSafariVC: false,
                                                        forceWebView: false);
                                                  }
                                                }
                                                else if (Platform.isIOS){
                                                  try {
                                                    bool launched =
                                                    await launch(
                                                        "whatsapp://send?phone=$phone&text=${Uri.parse(message)}",
                                                        forceSafariVC: false,
                                                        forceWebView: false);
                                                    if (!launched) {
                                                      print("inside fallback");
                                                      await launch(
                                                          "whatsapp://send?phone=$phone&text=${Uri.parse(message)}",
                                                          forceSafariVC: false,
                                                          forceWebView: false);
                                                    }
                                                  } catch (e) {
                                                    await launch(
                                                        "whatsapp://send?phone=$phone&text=${Uri.parse(message)}",
                                                        forceSafariVC: false,
                                                        forceWebView: false);
                                                  }
                                                }
                                              }
                                              Navigator.pop(context);
                                            }
                                          });
                                        }
                                        else {
                                          newDeviceMaintenanceState
                                              .addDeviceToMaintenance(
                                              MaintenanceDeviceModel(
                                                  customerName: name_controller
                                                      .text,
                                                  phoneNumber: phoneCode
                                                      .toString() + "-" +
                                                      phone_controller.text,
                                                  address: address_controller.text,
                                                  ////
                                                  ///please add brand id here
                                                  //brandID: brand_value,
                                                  ///
                                                  deviceModel: model_controller
                                                      .text,
                                                  color: color_controller.text,
                                                  devicePassword:pin_controller.text,
                                                  imeiNumber: IMEI_controller.text,
                                                  problem: problem_controller.text,
                                                  status: status_value,
                                                  problemNotes: notes_controller
                                                      .text,
                                                  accessories: accessoires_controller
                                                      .text,
                                                  price: price_controller.text,
                                                  estimatedTime: estimated_time_controller
                                                      .text,
                                                  notes: notes2_controller.text,
                                                  pattern: patternValue
                                              )
                                          ).then((value) {
                                            Message.showLongToastMessage(
                                                "Added successfully".tr());
                                            Navigator.pop(context);
                                          }
                                          );
                                        }
                                      }
                                    },
                                    child: Container(
                                      width: width * 0.2,
                                      child: WidgetUtilities.autoSizeText(
                                        widget.editable?"Save":"Create",
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      primary: ColorUtilities.secondary,
                                      textStyle: TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Container(
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
                        )
                    ),
                  )),
            )
          ],
        ),
      )
    );
  }
}
