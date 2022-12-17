import 'dart:io';

import 'package:flutter/material.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:file_picker/file_picker.dart';

import '../../../shared/widget_utilities.dart';

class NewProduct extends StatefulWidget {
  const NewProduct({Key? key}) : super(key: key);

  @override
  State<NewProduct> createState() => _NewProductState();
}

List<String> photoPaths=[];
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
                    "New Product",
                      textStyle: TextStyle(color: ColorUtilities.textColor,fontSize: 20)
                  ),
                )),
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
                    margin: EdgeInsets.only(right: 40, left: 40,bottom: 15,top: 15),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                              decoration: BoxDecoration(
                                color:ColorUtilities.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color:Color.fromRGBO(0, 0, 0, 0.4),
                                    blurRadius: 20,
                                    offset: Offset(0, 15),
                                  ),
                                ],
                              ),
                              height: height*0.4,
                              child:photoPaths.isNotEmpty? ListView(
                                scrollDirection: Axis.horizontal,
                                children: List.generate(
                                  photoPaths.length,
                                      (i) => Container(
                                      width: width*0.4,
                                      alignment: Alignment.center,
                                      child:Container(margin: EdgeInsets.all(10),
                                          child:Stack(
                                            children: [
                                              Image.file(
                                                File(photoPaths[i]),
                                                fit: BoxFit.fill,
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  InkWell(
                                                    child: Icon(Icons.cancel,color: Colors.red,size: 30,),
                                                    onTap: (){
                                                      photoPaths.remove(photoPaths[i]);
                                                      setState(() {});
                                                    },
                                                  )
                                                ],
                                              ),
                                            ],
                                          )
                                      )
                                  ),
                                ),
                              )
                                  :Image.asset("assets/images/defaultProdoctImage.png")
                          ),
                          SizedBox(height: 15,),
                          Container(
                            width: width*0.4,
                            child:
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  child:
                                  Container(
                                    padding: EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(50)
                                    ),
                                    child:  Center(child:Icon(Icons.add,size: 20,),),
                                  ),
                                  onTap: () async {
                                    final result = await FilePicker
                                        .platform
                                        .pickFiles(
                                        allowMultiple: true,
                                        type: FileType.image
                                    );
                                    if (result != null) {
                                      result.files.forEach((file) {
                                        photoPaths.add(file.path!);
                                      });
                                      print("\n\n\n\nhere"+photoPaths.toString()+"\n\n\n\n");
                                      setState(() {});
                                    }
                                  },
                                ),
                                SizedBox(width: 10,),
                                InkWell(
                                  child:
                                  Container(
                                    padding: EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(50)
                                    ),
                                    child:  Center(child:Icon(Icons.delete,size: 20,),),
                                  ),
                                  onTap: ()  {
                                    setState(() {
                                      photoPaths=[];
                                    });
                                  },
                                ),
                              ],),
                          ),
                          SizedBox(height: 15,),
                          Container(
                            padding: EdgeInsets.only(left: 20,right: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child :TextField(
                              controller: title_controller,
                              style: TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: ' Title ',
                                hintStyle:
                                TextStyle(color:Colors.grey, fontSize: 16),),
                            ),
                          ),
                          SizedBox(height: 15,),
                          Container(
                            height: 100,
                            padding: EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(
                              color: ColorUtilities.white,
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
                          SizedBox(height: 15,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: width*0.35,
                                padding: EdgeInsets.only(left: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
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
                                      child: WidgetUtilities.autoSizeText(items ,textStyle: TextStyle(color: Colors.black)),
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
                                width: width*0.35,
                                padding: EdgeInsets.only(left: 10),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
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
                                      child: WidgetUtilities.autoSizeText(items,textStyle: TextStyle(color: Colors.black)),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      sub_category_dropdown_value = newValue!;
                                    });
                                  },
                                ),
                              ),
                            ],),
                          SizedBox(height: 15,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: width*0.35,
                                padding: EdgeInsets.only(left: 20,right: 20),
                                decoration: BoxDecoration(
                                  color: ColorUtilities.white,
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child :TextField(
                                  controller: price_controller,
                                  style: TextStyle(color: Colors.black),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: ' price ',
                                    hintStyle:
                                    TextStyle(color:Colors.grey, fontSize: 16),),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15,),
                          SizedBox(height: 15,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: (){},
                                child: Container(
                                  width: width*0.2,
                                  child: WidgetUtilities.autoSizeText("Create",textAlign: TextAlign.center,),
                                ),
                                style: ElevatedButton.styleFrom(
                                  primary: ColorUtilities.secondary,
                                  textStyle:
                                  TextStyle(fontSize: 16, color: Colors.white),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: (){},
                                child: Container(
                                  width: width*0.2,
                                  child: WidgetUtilities.autoSizeText("Cancel",textAlign: TextAlign.center,),
                                ),
                                style: ElevatedButton.styleFrom(
                                  primary: Color.fromRGBO(128, 128, 128, 1),
                                  textStyle:
                                  TextStyle(fontSize: 16, color: Colors.white),
                                ),
                              ),

                            ],
                          ),
                          SizedBox(height: 10,),


                        ],
                      ),
                    )
                )
            ),
          )
        ],
      ),
    );
  }
}
