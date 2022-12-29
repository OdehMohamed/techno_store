import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/new_device_maintenance/view_model/new_device_maintenance_state.dart';
import 'package:techno_store/core/shared/model/brand_model.dart';
import 'package:techno_store/core/track_phone_page/view_model/track_phone_page_state.dart';
import 'package:techno_store/shared/color_utilities.dart';

import '../../../shared/widget_utilities.dart';
import '../../shared/model/maintenance_device_model.dart';
import '../../shared/view_model/shared_state.dart';

class TrackPhonePage extends StatefulWidget {
  const TrackPhonePage({Key? key}) : super(key: key);

  @override
  State<TrackPhonePage> createState() => _TrackPhonePageState();
}

class _TrackPhonePageState extends State<TrackPhonePage> {
  bool phoneValid = false;
  String phoneCode = "+962";
  PhoneNumber number = PhoneNumber(isoCode: 'JO');
  final phoneController = TextEditingController();
  late TrackPhonePageState trackPhonePageState;


  @override
  void initState() {
    trackPhonePageState= context.read<TrackPhonePageState>();
  }

  @override
  Widget build(BuildContext context) {
    trackPhonePageState= context.watch<TrackPhonePageState>();
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    showStatus(MaintenanceDeviceModel device,String brandImgUrl){
      showDialog(
        context: context,
        builder: (BuildContext context) {
          Icon statusIcon;
          switch (device.status){
            case "Fixed" :{
              statusIcon=Icon(FontAwesome5.check_circle,color: Colors.green,size: 40,);
              break;
            }
            case "under review":{
              statusIcon=Icon(Icons.person_search,color: Colors.orange,size: 40,);
              break;
            }
            default:{
              statusIcon=Icon(Icons.precision_manufacturing,color: Colors.yellow,size: 40,);
              break;
            }
          }
          return AlertDialog(
            backgroundColor:ColorUtilities.white,
            content: Container(
              height: height * 0.6,
              width: width,
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,
                      children: [
                        WidgetUtilities.autoSizeText(
                          "Status",
                          textStyle: TextStyle(
                            color: Color.fromRGBO(
                                0, 0, 0, 0.7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        statusIcon,
                        SizedBox(
                          height: 10,
                        ),
                        WidgetUtilities.autoSizeText(
                            device.status!,
                            textStyle: TextStyle(color: Colors.green)
                        )
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    WidgetUtilities.autoSizeText("Owner name",textStyle: TextStyle(color: Colors.black)),
                    WidgetUtilities.autoSizeText(device.customerName!,textStyle: TextStyle(color: Colors.grey)),

                  ],),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      WidgetUtilities.autoSizeText("Device Brand",textStyle: TextStyle(color: Colors.black)),
                      WidgetUtilities.autoSizeText(device.deviceModel!,textStyle: TextStyle(color: Colors.grey)),

                      SizedBox(
                        width: 10,
                      ),
                      Container(
                          width: 30,
                          height: 30,
                          child: Image.network(
                              brandImgUrl))
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      WidgetUtilities.autoSizeText("Estimated Time",textStyle: TextStyle(color: Colors.black)),
                      Row(children: [
                        WidgetUtilities.autoSizeText(device.estimatedTime!,textStyle: TextStyle(color: Colors.grey)),
                        WidgetUtilities.autoSizeText("days",textStyle: TextStyle(color: Colors.grey)),
                      ],)


                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                    WidgetUtilities.autoSizeText("Estimated cost",textStyle: TextStyle(color: Colors.black)),
                    Row(children: [
                      WidgetUtilities.autoSizeText(device.price!,textStyle: TextStyle(color: Colors.grey)),
                      WidgetUtilities.autoSizeText("JD",textStyle: TextStyle(color: Colors.grey)),
                    ],)
                    ],),
                  Row(
                    children: [
                      WidgetUtilities.autoSizeText("Notes",textStyle: TextStyle(color: Colors.black)),
                      WidgetUtilities.autoSizeText(device.notes!,textStyle: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly,
                    children: [
                      InkWell(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                            BorderRadius.circular(10),
                            color: Colors.green,
                          ),
                          width: width / 2,
                          height: height / 20,
                          child: Center(
                            child:  WidgetUtilities.autoSizeText(
                              "Close",
                              textStyle: TextStyle(
                                color: Colors.white,
                                fontSize: width / 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    Widget card(MaintenanceDeviceModel device) {
      Icon statusIcon;
      switch (device.status){
        case "Fixed" :{
          statusIcon=Icon(FontAwesome5.check_circle,color: Colors.green);
          break;
        }
        case "under review":{
          statusIcon=Icon(Icons.person_search,color: Colors.orange);
          break;
        }
        default:{
          statusIcon=Icon(Icons.precision_manufacturing,color: Colors.yellow,);
          break;
        }
      }
      String? brandImgUrl="https://firebasestorage.googleapis.com/v0/b/technostore-86118.appspot.com/o/Images%2Fapple_logo.png?alt=media";
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
                    child: Image.network(brandImgUrl,fit: BoxFit.fill,),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: width*0.67,
                        child: Row(children: [
                          WidgetUtilities.autoSizeText(device.customerName!,textStyle: TextStyle(color: Colors.black)),
                          Flexible(child: Container()),
                          statusIcon,
                          SizedBox(width: 5,),
                          WidgetUtilities.autoSizeText(device.status!,textStyle: TextStyle(color: Colors.black54))
                        ],),
                      ),
                      Container(
                        width: width*0.67,
                        child: Row(children: [
                          WidgetUtilities.autoSizeText(device.deviceModel!,textStyle: TextStyle(color: Colors.black54))
                        ],),
                      ),
                      Container(
                        width: width*0.67,
                        child: Row(children: [
                          Container(child: Row(children: [
                            WidgetUtilities.autoSizeText(device.estimatedTime!,textStyle: TextStyle(color: Colors.black54)),
                            WidgetUtilities.autoSizeText("days",textStyle: TextStyle(color: Colors.black54)),
                          ],),),
                          Flexible(child: Container()),
                          Container(child: Row(children: [
                            WidgetUtilities.autoSizeText(device.price!,textStyle: TextStyle(color: Colors.black54)),
                            WidgetUtilities.autoSizeText("JD",textStyle: TextStyle(color: Colors.black54)),
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
            onTap: (){
              showStatus(device,brandImgUrl);
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
      body: Column(
        children: [
          Container(
            color: ColorUtilities.backgroundContainer,
            child: Container(
                padding: EdgeInsets.only(top: height * 0.1),
                width: width,
                height: height * 0.4,
                decoration: const BoxDecoration(
                  color: ColorUtilities.secondary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 150,
                      height: 100,
                      child: Image.asset(
                        "assets/images/logo.png",
                        fit: BoxFit.fill,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )),
          ),
          Container(
            color: ColorUtilities.secondary,
            child: Container(
                width: width,
                height: height * 0.6,
                decoration: const BoxDecoration(
                  color: ColorUtilities.backgroundContainer,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.only(left: 20, right: 20),
                  child: Column(
                    children: [
                      SizedBox(
                        height: height * 0.05,
                      ),
                      WidgetUtilities.autoSizeText(
                        "From Here You can track your mobile",
                        textAlign: TextAlign.center,
                        textStyle: TextStyle(color: Colors.black)
                      ),
                      SizedBox(
                        height: height * 0.07,
                      ),
                      InternationalPhoneNumberInput(
                        errorMessage: "Invalid phone number".tr(),
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
                        autoValidateMode: AutovalidateMode.always,
                        selectorTextStyle: TextStyle(color: Colors.black),
                        initialValue: number,
                        textFieldController: phoneController,
                        formatInput: false,
                        keyboardType: TextInputType.numberWithOptions(
                          signed: true,
                          decimal: true,
                        ),
                        inputBorder: OutlineInputBorder(),
                      ),
                      Expanded(child: Container()),
                      ElevatedButton(
                        onPressed: () async {
                          if (phoneValid) {
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return
                                  FutureBuilder<List<MaintenanceDeviceModel>>
                                    (future: trackPhonePageState.checkDeviceStatus(phoneCode+"-"+phoneController.text),
                                    builder: (context, snapshot){
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Container(child:CircularProgressIndicator(),height: height*0.7,margin: EdgeInsets.all(width*0.4),);
                                      }
                                      else if (snapshot.data!.isEmpty){
                                        return Center(child: Text("No Data".tr()),);
                                      }
                                      else if(snapshot.hasData){
                                        List<MaintenanceDeviceModel> devices= snapshot.data as List<MaintenanceDeviceModel>;
                                        return ListView.builder(
                                            itemCount: devices.length,
                                            itemBuilder:(context,index)
                                            {
                                              return card(
                                                  devices[index]
                                              );
                                            }
                                            );
                                      }
                                      else {
                                        return Center(child: Text("Error".tr()),);
                                      }
                                    });
                              },
                            );
                          }
                          },
                        child: Container(
                            width: width * 0.4,
                            height: height * 0.07,
                            child: Center(
                              child: WidgetUtilities.autoSizeText(
                                "Check Status",
                                textAlign: TextAlign.center,
                              ),
                            )),
                        style: ElevatedButton.styleFrom(
                          primary: ColorUtilities.secondary,
                          textStyle:
                              TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      Expanded(child: Container())
                    ],
                  ),
                )),
          )
        ],
      ),
    );
  }
}
