import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

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
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Widget card(
      String title,
      Icon icon,
    ) {
      return Column(
        children: [
          InkWell(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.all(20),
              height: height * 0.1,
              width: width,
              child: Column(
                children: [
                  Row(
                    children: [
                      icon,
                      Text(
                        title,
                        style: TextStyle(color: Colors.white),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          Divider(
            color: Colors.grey,
            thickness: 1,
          ),
        ],
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: Text("Tracking"),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          Container(
            color: Color.fromRGBO(239, 239, 239, 1),
            child: Container(
                padding: EdgeInsets.only(top: height * 0.1),
                width: width,
                height: height * 0.4,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(76, 127, 158, 1),
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
            color: Color.fromRGBO(76, 127, 158, 1),
            child: Container(
                width: width,
                height: height * 0.6,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(239, 239, 239, 1),
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
                      Text(
                        "From Here You can track your mobile \nstatus",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      SizedBox(
                        height: height * 0.07,
                      ),
                      InternationalPhoneNumberInput(
                        hintText: "Phone number",
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
                        autoValidateMode: AutovalidateMode.onUserInteraction,
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
                          print(phoneCode + phoneController.value.text);
                          await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: Colors.white,
                                content: Container(
                                  height: height * 0.6,
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
                                            Text(
                                              "Status",
                                              style: TextStyle(
                                                color: Color.fromRGBO(
                                                    0, 0, 0, 0.7),
                                                fontSize: width / 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Icon(
                                              FontAwesome5.check_circle,
                                              color: Colors.green,
                                              size: 40,
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                              "Fixed",
                                              style: TextStyle(
                                                  color: Colors.green),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text("Owner name : Abdullah ta"),
                                      Row(
                                        children: [
                                          Text("Mobile Type : Apple"),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Container(
                                              width: 30,
                                              height: 30,
                                              child: Image.asset(
                                                  "assets/images/appleLogo.png"))
                                        ],
                                      ),
                                      Text("Estimated Time : 5days"),
                                      Text("Estimated cost : 25JD"),
                                      Text(
                                          "Notes : Please Come to the store before 11/02/2022"),
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
                                                child: Text(
                                                  "Close",
                                                  style: TextStyle(
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
                        },
                        child: Container(
                            width: width * 0.4,
                            height: height * 0.07,
                            child: Center(
                              child: Text(
                                "Check Status",
                                textAlign: TextAlign.center,
                              ),
                            )),
                        style: ElevatedButton.styleFrom(
                          primary: Color.fromRGBO(24, 114, 151, 1),
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
