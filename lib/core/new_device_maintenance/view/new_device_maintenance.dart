import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:pattern_lock/pattern_lock.dart';
import 'package:techno_store/shared/color_utilities.dart';

import '../../../shared/widget_utilities.dart';

class NewDeviceMaintanace extends StatefulWidget {
  const NewDeviceMaintanace({Key? key}) : super(key: key);

  @override
  State<NewDeviceMaintanace> createState() => _NewDeviceMaintanaceState();
}

bool phoneValid = false;
String phoneCode = "+962";
PhoneNumber number = PhoneNumber(isoCode: 'JO');
final name_controller = TextEditingController();
final address_controller = TextEditingController();
final phone_controller = TextEditingController();
final model_controller = TextEditingController();
final color_controller = TextEditingController();
final IMEI_controller = TextEditingController();
final pin_controller = TextEditingController();
final problem_controller = TextEditingController();
final status_controller = TextEditingController();
final notes_controller = TextEditingController();
final accessoires_controller = TextEditingController();
final price_controller = TextEditingController();
final estimated_time_controller = TextEditingController();
final notes2_controller = TextEditingController();

class _NewDeviceMaintanaceState extends State<NewDeviceMaintanace> {
  String? dropdownvalue;

  var items = [
    'Item 1',
    'Item 2',
    'Item 3',
    'Item 4',
    'Item 5',
  ];
  List<int>? patternValue;
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Column(
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
                          padding: EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: ColorUtilities.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: TextField(
                            controller: name_controller,
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Name'.tr(),
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
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: InternationalPhoneNumberInput(
                            hintText: "Phone number".tr(),
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
                                AutovalidateMode.onUserInteraction,
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
                          padding: EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: ColorUtilities.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: TextField(
                            controller: address_controller,
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Address'.tr(),
                              hintStyle:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
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
                          padding: EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: ColorUtilities.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: DropdownButton(
                            isExpanded: true,
                            underline: SizedBox(),
                            hint: WidgetUtilities.autoSizeText("Device Brand"),
                            value: dropdownvalue,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: items.map((String items) {
                              return DropdownMenuItem(
                                value: items,
                                child: WidgetUtilities.autoSizeText(items,textStyle: TextStyle(color: Colors.black)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                dropdownvalue = newValue!;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: ColorUtilities.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: TextField(
                            controller: model_controller,
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Device Model'.tr(),
                              hintStyle:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: ColorUtilities.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: TextField(
                            controller: color_controller,
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Color'.tr(),
                              hintStyle:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 10),
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
                                    await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
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
                                                        setUsed: [],
                                                      )),
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
                                            ));
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
                          padding: EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: ColorUtilities.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: TextField(
                            controller: problem_controller,
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'The problem'.tr(),
                              hintStyle:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: ColorUtilities.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: TextField(
                            controller: status_controller,
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Device Status'.tr(),
                              hintStyle:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 10),
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
                          padding: EdgeInsets.only(left: 10),
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
                              padding: EdgeInsets.only(left: 10),
                              decoration: BoxDecoration(
                                color: ColorUtilities.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: TextField(
                                controller: price_controller,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Price'.tr(),
                                  hintStyle: TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Container(
                              width: width * 0.4,
                              padding: EdgeInsets.only(left: 10),
                              decoration: BoxDecoration(
                                color: ColorUtilities.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: TextField(
                                controller: estimated_time_controller,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Estimated Time'.tr(),
                                  hintStyle: TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Container(
                          height: 100,
                          padding: EdgeInsets.only(left: 10),
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
                              onPressed: () {},
                              child: Container(
                                width: width * 0.2,
                                child: WidgetUtilities.autoSizeText(
                                  "Create",
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
                              onPressed: () {},
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
                  ),
                )),
          )
        ],
      ),
    );
  }
}
