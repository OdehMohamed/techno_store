import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:techno_store/core/new_device_maintenance/view/new_device_maintenance.dart';

class MaintinanceList extends StatefulWidget {
  const MaintinanceList({Key? key}) : super(key: key);

  @override
  State<MaintinanceList> createState() => _MaintinanceListState();
}

List<Color> backgroundColor = [
  Colors.white,
  Colors.transparent,
  Colors.transparent
];
List<Color> textColor = [
  Color.fromRGBO(76, 127, 158, 1),
  Colors.white,
  Colors.white
];
void changeStatus(int status) {
  switch (status) {
    case 0:
      {
        backgroundColor = [
          Colors.white,
          Colors.transparent,
          Colors.transparent
        ];
        textColor = [
          Color.fromRGBO(76, 127, 158, 1),
          Colors.white,
          Colors.white
        ];
        break;
      }
    case 1:
      {
        backgroundColor = [
          Colors.transparent,
          Colors.white,
          Colors.transparent
        ];
        textColor = [
          Colors.white,
          Color.fromRGBO(76, 127, 158, 1),
          Colors.white
        ];
        break;
      }
    case 2:
      {
        backgroundColor = [
          Colors.transparent,
          Colors.transparent,
          Colors.white
        ];
        textColor = [
          Colors.white,
          Colors.white,
          Color.fromRGBO(76, 127, 158, 1)
        ];
        break;
      }
    default:
      {
        backgroundColor = [
          Colors.white,
          Colors.transparent,
          Colors.transparent
        ];
        textColor = [
          Color.fromRGBO(76, 127, 158, 1),
          Colors.white,
          Colors.white
        ];
        break;
      }
  }
}

class _MaintinanceListState extends State<MaintinanceList> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Widget card() {
      return InkWell(
        child: Container(
          width: width * 0.9,
          height: height * 0.2,
          margin: EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Color.fromRGBO(76, 127, 158, 1),
          ),
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.all(width * 0.05),
                width: width * 0.1,
                height: height * 0.07,
                child: Image.asset(
                  "assets/images/appleLogo.png",
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
                        Text(
                          "Ahmad Mohammad",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        Flexible(child: Container()),
                        Icon(
                          FontAwesome5.check_circle,
                          color: Colors.green,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text("fixed",
                            style: TextStyle(color: Colors.white, fontSize: 16))
                      ],
                    ),
                  ),
                  Container(
                    width: width * 0.67,
                    child: Row(
                      children: [
                        Text(
                          "Apple 13 Pro Max",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: width * 0.67,
                    child: Row(
                      children: [
                        Text("4 days",
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                        Flexible(child: Container()),
                        Text("30JD",
                            style: TextStyle(color: Colors.white, fontSize: 16))
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
            MaterialPageRoute(builder: (context) => NewDeviceMaintanace()),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Container(
            color: Color.fromRGBO(239, 239, 239, 1),
            child: Container(
                width: width,
                height: height * 0.25,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(76, 127, 158, 1),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                  ),
                ),
                child: Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: height * 0.13),
                      child: Text(
                        "Mobile List",
                        style: TextStyle(color: Colors.white, fontSize: 26),
                      ),
                    ),
                    Flexible(child: Container()),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      InkWell(
                        child: Container(
                          padding: EdgeInsets.only(
                              top: 5, bottom: 5, left: 10, right: 10),
                          decoration: BoxDecoration(
                              color: backgroundColor[0],
                              borderRadius: BorderRadius.circular(15)),
                          child: Text(
                            "All",
                            style: TextStyle(color: textColor[0], fontSize: 18),
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
                          child: Text(
                            "Fixing",
                            style: TextStyle(color: textColor[1], fontSize: 18),
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
                          child: Text(
                            "Done",
                            style: TextStyle(color: textColor[2], fontSize: 18),
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
            color: Color.fromRGBO(76, 127, 158, 1),
            child: Container(
                width: width,
                height: height * 0.75,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(239, 239, 239, 1),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Container(
                    margin: EdgeInsets.only(right: 20, left: 20),
                    padding: EdgeInsets.only(top: 30, bottom: 10),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          card(),
                          card(),
                          card(),
                          card(),
                          card(),
                          card(),
                          card(),
                        ],
                      ),
                    ))),
          )
        ],
      ),
    );
  }
}
