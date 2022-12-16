import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Store extends StatefulWidget {
  const Store({Key? key}) : super(key: key);

  @override
  State<Store> createState() => _StoreState();
}

var categories = [
  'Devices',
  'Accessories',
  'Covers',
  'Screen protectors',
];
var sub_categories = [
  'Item 1',
  'Item 2',
  'Item 3',
  'Item 4',
  'Item 5',
];
String category_dropdown_value = 'Devices';
String? sub_category_dropdown_value;
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

class _StoreState extends State<Store> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
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
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: height * 0.13),
                      child: Text(
                        "Categoires ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                        ),
                      ),
                    ),
                    Flexible(child: Container()),
                    Row(children: [
                      Container(
                        width: width * 0.35,
                        padding: EdgeInsets.only(left: 40),
                        child: DropdownButton(
                          isExpanded: true,
                          underline: SizedBox(),
                          value: category_dropdown_value,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                          items: categories.map((String items) {
                            return DropdownMenuItem(
                              value: items,
                              child: Text(
                                items,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              category_dropdown_value = newValue!;
                            });
                          },
                        ),
                      ),
                      Container(
                        width: width * 0.65,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              InkWell(
                                child: Container(
                                  padding: EdgeInsets.only(
                                      top: 5, bottom: 5, left: 10, right: 10),
                                  decoration: BoxDecoration(
                                      color: backgroundColor[0],
                                      borderRadius: BorderRadius.circular(15)),
                                  child: Text(
                                    "Phones",
                                    style: TextStyle(
                                        color: textColor[0], fontSize: 14),
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
                                    "Laptops",
                                    style: TextStyle(
                                        color: textColor[1], fontSize: 14),
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
                                    "Tablets",
                                    style: TextStyle(
                                        color: textColor[2], fontSize: 14),
                                  ),
                                ),
                                onTap: () {
                                  changeStatus(2);
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      )
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
                        children: [],
                      ),
                    ))),
          )
        ],
      ),
    );
  }
}
