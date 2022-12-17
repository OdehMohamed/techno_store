import 'package:flutter/material.dart';
import 'package:techno_store/shared/color_utilities.dart';
class manageCategory extends StatefulWidget {
  const manageCategory({Key? key}) : super(key: key);

  @override
  State<manageCategory> createState() => _manageCategoryState();
}
bool enabled_sub_category=false;
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
String? sub_category_dropdown_value ;
String? category_dropdown_value ;
final edit_name_controller=TextEditingController();
final new_category_name_controller=TextEditingController();
final new_sub_category_controller=TextEditingController();

class _manageCategoryState extends State<manageCategory> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Widget card(String title,Icon icon,){
      return Column(
        children: [
          InkWell(
            onTap: (){},
            child: Container(
              padding: EdgeInsets.all(20),
              height: height*0.1,
              width: width,
              child: Column(
                children: [
                  Row(
                    children: [
                      icon,
                      Text(title,style: TextStyle(color: ColorUtilities.white),)
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
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body:Column(
        children: [
          Container(
            color:ColorUtilities.backgroundContainer,
            child: Container(
                padding: EdgeInsets.only(top:height*0.1),
                width: width,
                height: height*0.2,
                decoration: const BoxDecoration(
                  color:ColorUtilities.secondary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                  ),
                ),
                child:Container(child:
                Text("Manage Categories",style: TextStyle(color: ColorUtilities.white,fontSize: 22,),textAlign: TextAlign.center,)
                  ,)
            ),
          ),
          Container(
            color:ColorUtilities.secondary,
            child: Container (
                width: width,
                height: height*0.8,
                decoration: const BoxDecoration(
                  color:  ColorUtilities.backgroundContainer,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                  ),
                ),
                child: Container (
                  padding: EdgeInsets.only(left: 20,right: 20,top: 20,bottom: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text("Categories",style: TextStyle(fontSize: 20),),
                      Row(children: [
                        Container(
                          width: width*0.7,
                          margin: EdgeInsets.all(15),
                          child:
                          DropdownButton(
                            isExpanded: true,
                            underline: SizedBox(),
                            hint: Text("Category"),
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
                        InkWell(
                          child:Icon(Icons.add_circle_outlined,color: Colors.green,size: 30,),
                          onTap: (){

                            showDialog<Image>(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: Text("Add category"),
                                content: Container(
                                    width: width,
                                    height: height*0.2,
                                    child:
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Container(
                                          width: width*0.5,
                                          margin: EdgeInsets.only(top: 20),
                                          padding: EdgeInsets.only(left: 20,right: 20),
                                          decoration: BoxDecoration(
                                            color:ColorUtilities.white,
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          child :TextField(
                                            controller: new_category_name_controller,
                                            style: TextStyle(color: Colors.black),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: ' New Category',
                                              hintStyle:
                                              TextStyle(color:Colors.grey, fontSize: 16),),
                                          ),
                                        ),
                                      ],
                                    )
                                ),
                                actions: [
                                  Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton(onPressed: (){}, child:Text("Add"),style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green
                                            ),
                                        ),
                                        SizedBox(width: 30,),
                                        ElevatedButton(onPressed: (){Navigator.pop(context);}, child: Text("Cancel"),style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey
                            ),),

                                      ],
                                    ),
                                  )
                                ],
                              ),
                            );
                          }
                          ,)
                      ],),
                      Divider(thickness: 1,color: Colors.grey,),
                      Text("Sub-Categories",style: TextStyle(fontSize: 20),),
                      Row(children: [
                        Container(
                          width: width*0.7,
                          margin: EdgeInsets.all(15),
                          child:
                              InkWell(
                                child: DropdownButton(
                                    isExpanded: true,
                                    underline: SizedBox(),
                                    hint: Text("Sub-Categories",style: TextStyle(color: enabled_sub_category?Colors.black:Colors.black12),),
                                    value: sub_category_dropdown_value,
                                    icon:  Icon(Icons.keyboard_arrow_down,color:  enabled_sub_category?Colors.black:Colors.black12,),
                                    items: sub_categories.map((String items) {
                                      return DropdownMenuItem(
                                        value: items,
                                        child: Text(items),
                                      );
                                    }).toList(),
                                    onChanged: enabled_sub_category?(String? newValue) {
                                      setState(() {
                                        category_dropdown_value = newValue!;
                                      });
                                    }:null
                                ),
                                  onTap: (){
                                  enabled_sub_category=true;
                                  setState(() {});
                                  },
                              )
                        ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          enabled_sub_category?
                      InkWell(
                      child:
                      Icon(Icons.near_me_disabled,color: Colors.grey,size: 30,),
                  onTap: (){
                        enabled_sub_category=false;
                        setState(() {});
                  }
                  ,)
                    :Container(),
                          InkWell(
                            child:
                            Icon(Icons.add_circle_outlined,color: Colors.green,size: 30,),
                            onTap: (){
                              showDialog<Image>(
                                context: context,
                                builder: (BuildContext context) => AlertDialog(
                                  title: Text("Add Sub-category"),
                                  content: Container(
                                      width: width,
                                      height: height*0.25,
                                      child:
                                      Column(
                                        children: [
                                          Container(
                                            width: width*0.7,
                                            margin: EdgeInsets.all(15),
                                            child:
                                            DropdownButton(
                                              isExpanded: true,
                                              underline: SizedBox(),
                                              hint: Text("Category"),
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
                                            width: width*0.5,
                                            margin: EdgeInsets.only(top: 20),
                                            padding: EdgeInsets.only(left: 20,right: 20),
                                            decoration: BoxDecoration(
                                              color: ColorUtilities.white,
                                              border: Border.all(color: Colors.grey),
                                              borderRadius: BorderRadius.circular(5),
                                            ),
                                            child :TextField(
                                              controller: new_sub_category_controller,
                                              style: TextStyle(color: Colors.black),
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                hintText: ' New Sub-Category',
                                                hintStyle:
                                                TextStyle(color:Colors.grey, fontSize: 16),),
                                            ),
                                          ),
                                        ],
                                      )
                                  ),
                                  actions: [
                                    Center(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(onPressed: (){}, child:Text("Add"),style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green
                                          ),
                                          ),
                                          SizedBox(width: 30,),
                                          ElevatedButton(onPressed: (){Navigator.pop(context);}, child: Text("Cancel"),style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.grey
                                          ),),

                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            }
                            ,),
                        ],

                      )
                      ]
                      ),
                      Divider(thickness: 1,color: Colors.grey,),
                      Container(
                        width: width*0.5,
                        margin: EdgeInsets.only(top: 20),
                        padding: EdgeInsets.only(left: 20,right: 20),
                        decoration: BoxDecoration(
                          color: ColorUtilities.white,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child :TextField(
                          controller: edit_name_controller,
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: ' New Name ',
                            hintStyle:
                            TextStyle(color:Colors.grey, fontSize: 16),),
                        ),
                      ),
                      SizedBox(height: 20,),
                      Container(
                        width: width*0.5,
                        height: height*0.05,
                        child:
                      ElevatedButton(onPressed: (){}, child: Text("Change"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          textStyle: TextStyle(
                            fontSize: 20,),
                        ),
                      ),
                          ),
                      Container(
                        width: width*0.5,
                        height: height*0.05,
                        child:
                        ElevatedButton(onPressed: (){}, child: Text("Delete"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            textStyle: TextStyle(
                              fontSize: 20,),
                          ),
                        )
                      ),


                    ],
                  ),
                )
            ),
          )
        ],
      ),
    );
  }
}
