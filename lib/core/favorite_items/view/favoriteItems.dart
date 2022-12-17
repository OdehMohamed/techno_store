import 'package:flutter/material.dart';
import 'package:techno_store/shared/color_utilities.dart';

import '../../product_details/view/product_details.dart';
class favoraitItems extends StatefulWidget {
  const favoraitItems({Key? key}) : super(key: key);

  @override
  State<favoraitItems> createState() => _favoraitItemsState();
}
int gridNumber=2;
List <Color> gridIconColor = [Color.fromRGBO(76, 127, 158, 1),Colors.black];


class _favoraitItemsState extends State<favoraitItems> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    Widget listCard(){
      return InkWell(
        child:  Container(
          margin: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.all(width*0.01),
                width: width*0.3,
                height: height*0.4,
                child: Image.asset("assets/images/iPhone-14.png",fit: BoxFit.fill,),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    children: [
                      Text("Iphone 14 pro"),
                      SizedBox(width: 30,),
                      Text("1100JD"),
                    ],
                  ),
                  Text("this is iphone 14, ",maxLines: 4,)
                ],
              )
            ],
          ),
        ),
        onTap: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetails()),);
        },
      );
    }
    Widget gridCard(){
      return InkWell(
        child:  Container(
          height: height*0.2,
          decoration: BoxDecoration(
              color:Colors.white,
              borderRadius: BorderRadius.circular(10)
          ),
          margin: EdgeInsets.all(5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                margin:EdgeInsets.only(top: 10),
                width: width*0.3,
                height: height*0.15,
                child: Image.asset("assets/images/iPhone-14.png",fit: BoxFit.fill,),
              ),
              Text("Iphone 14 pro" ,style: TextStyle(color: Colors.black54),),
              SizedBox(height: 5,),
              Text("1100JD"),
              SizedBox(height: 5,),
            ],
          ),
        ),
        onTap: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetails()),);
        },
      );
    }
    void changeGridLength(int length){
      gridNumber =length;
      switch(length){

        case 1: {
          gridIconColor = [Colors.black,Color.fromRGBO(76, 127, 158, 1)];
          break;
        }
        case 2:{
          gridIconColor = [Color.fromRGBO(76, 127, 158, 1),Colors.black];
          break;
        }

      }
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body:  Column(
        children: [
          Container(
            color: ColorUtilities.backgroundContainer,
            child: Container(
                width: width,
                height: height*0.25,
                decoration: const BoxDecoration(
                  color:ColorUtilities.secondary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                  ),
                ),
                child:Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top:height*0.13),
                          child: Text("Favorites ",style: TextStyle(color: Colors.white,fontSize: 26,),),
                        ),
                      ],
                    )
                )
            ),
          ),
          Container(
            color:ColorUtilities.secondary,
            child: Container (
                width: width,
                height: height*0.75,
                decoration: const BoxDecoration(
                  color:   ColorUtilities.backgroundContainer,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                  ),
                ),
                child:Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 30),
                      child:    Row(mainAxisAlignment: MainAxisAlignment.center,children: [
                        InkWell(
                          child: Container(
                            margin: EdgeInsets.all(15),
                            child: Center(child:
                            Icon(Icons.grid_view_rounded,color: gridIconColor[0],size: 30,),),
                          ),
                          onTap: (){
                            changeGridLength(2);
                            setState(() {});
                          },
                        ),
                        InkWell(
                          child: Container(
                            margin: EdgeInsets.all(15),
                            child: Center(child:
                            Icon(Icons.format_list_bulleted,color: gridIconColor[1],size: 30,),),
                          ),
                          onTap: (){
                            changeGridLength(1);
                            setState(() {});
                          },
                        )
                      ]
                      ),
                    ),

                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.all(10),
                        itemCount: 5,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            childAspectRatio: gridNumber==2?(1 / 1):(1/0.5),
                            crossAxisCount: gridNumber,
                            crossAxisSpacing: 1.0,
                            mainAxisSpacing: 5
                        ), itemBuilder: (BuildContext context, int index) {
                        if (gridNumber==1){
                          return listCard();
                        }
                        return gridCard();
                      },
                      ),
                    )
                  ],
                )
            ),
          )
        ],
      ),
    );
  }
}
