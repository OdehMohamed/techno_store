import 'dart:io';

import 'package:flutter/material.dart';

class NewProduct extends StatefulWidget {
  const NewProduct({Key? key}) : super(key: key);

  @override
  State<NewProduct> createState() => _NewProductState();
}

String photoPath = "";
final title_controller = TextEditingController();
final description_controller = TextEditingController();
final price_controller = TextEditingController();

var categories = [
  'Item 1',
  'Item 2',
  'Item 3',
  'Item 4',
  'Item 5',
];
var sub_categories = [
  'Item 1',
  'Item 2',
  'Item 3',
  'Item 4',
  'Item 5',
];
String? category_dropdown_value;
String? sub_category_dropdown_value;

class _NewProductState extends State<NewProduct> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
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
                  child: Text(
                    "New Product",
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                )),
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
                    margin: EdgeInsets.only(right: 40, left: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Stack(
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.4),
                                      blurRadius: 20,
                                      offset: Offset(0, 15),
                                    ),
                                  ],
                                ),
                                width: width * 0.4,
                                height: height * 0.23,
                                child: photoPath.isNotEmpty
                                    ? Image.file(
                                        File(photoPath),
                                        fit: BoxFit.fill,
                                      )
                                    : Image.asset(
                                        "assets/images/defaultImg.png",
                                        fit: BoxFit.fill,
                                      )),
                            Container(
                                width: width * 0.4,
                                height: height * 0.25,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        InkWell(
                                          child: Container(
                                            padding: EdgeInsets.all(15),
                                            decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(50)),
                                            child: Center(
                                              child: Icon(
                                                Icons.add,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          onTap: () async {
                                            //
                                            //
                                            //
                                            //Use image picker here
                                            //
                                            //
                                            //

                                            // final result = await FilePicker
                                            //     .platform
                                            //     .pickFiles(
                                            //   type: FileType.image,
                                            // );
                                            // if (result != null) {
                                            //   final file = result.files.first;

                                            //   setState(() {
                                            //     photoPath = file.path!;
                                            //   });
                                            // }
                                          },
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        InkWell(
                                          child: Container(
                                            padding: EdgeInsets.all(15),
                                            decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(50)),
                                            child: Center(
                                              child: Icon(
                                                Icons.delete,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                          onTap: () {
                                            setState(() {
                                              photoPath = "";
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                )),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 20, right: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: TextField(
                            controller: title_controller,
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: ' Title ',
                              hintStyle:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ),
                        Container(
                          height: 100,
                          padding: EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: TextField(
                            controller: description_controller,
                            style: TextStyle(color: Colors.black),
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: ' Description ',
                              hintStyle:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: width * 0.35,
                              padding: EdgeInsets.only(left: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: DropdownButton(
                                isExpanded: true,
                                underline: SizedBox(),
                                hint: Text("Device Category"),
                                value: category_dropdown_value,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                items: categories.map((String items) {
                                  return DropdownMenuItem(
                                    value: items,
                                    child: Text(items),
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
                              width: width * 0.35,
                              padding: EdgeInsets.only(left: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: DropdownButton(
                                isExpanded: true,
                                underline: SizedBox(),
                                hint: Text("Device sub-category"),
                                value: sub_category_dropdown_value,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                items: sub_categories.map((String items) {
                                  return DropdownMenuItem(
                                    value: items,
                                    child: Text(items),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    sub_category_dropdown_value = newValue!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: width * 0.35,
                              padding: EdgeInsets.only(left: 20, right: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: TextField(
                                controller: price_controller,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: ' price ',
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {},
                              child: Container(
                                width: width * 0.3,
                                height: height * 0.06,
                                child: Center(
                                    child: Text(
                                  "Create",
                                  textAlign: TextAlign.center,
                                )),
                              ),
                              style: ElevatedButton.styleFrom(
                                primary: Color.fromRGBO(76, 127, 158, 1),
                                textStyle: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                width: width * 0.3,
                                height: height * 0.06,
                                child: Center(
                                    child: Text(
                                  "Cancel",
                                  textAlign: TextAlign.center,
                                )),
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
                          height: 10,
                        ),
                      ],
                    ))),
          )
        ],
      ),
    );
  }
}
