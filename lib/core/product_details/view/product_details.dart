import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/new_product/view/new_product.dart';
import 'package:techno_store/core/product_details/view_model/product_details_state.dart';
import 'package:techno_store/core/shared/model/productModel.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:techno_store/shared/message.dart';
import 'package:techno_store/shared/utilities.dart';

import '../../../shared/widget_utilities.dart';
import '../../shared/view_model/shared_state.dart';

class ProductDetails extends StatefulWidget {
  final ProductModel product ;
  ProductDetails({Key? key, required this.product}) : super(key: key);
  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}
class _ProductDetailsState extends State<ProductDetails> {
  @override
  late ProductDetailsState productDetailsState;
  late SharedState sharedState;

  bool favourite = false;
  @override
  void initState() {
    sharedState = context.read<SharedState>();
    productDetailsState=context.read<ProductDetailsState>();
    if (widget.product.favoriteList!.contains(sharedState.userId)){
      favourite=true;
    }

    super.initState();
  }
  Widget build(BuildContext context) {
    productDetailsState=context.watch<ProductDetailsState>();
    sharedState = context.watch<SharedState>();
    favoriteChangeMessage (bool value,String msg){
      if (value){
        Message.showShortToastMessage(msg.tr());
        setState(() {});
      }
    }

    void changeFavourite(){
      String msg="";
      favourite=!favourite;
      if (widget.product.favoriteList!.contains(sharedState.userId)){
        widget.product.favoriteList?.remove(sharedState.userId);
        msg = "Removed from favorite";
      }
      else {
        widget.product.favoriteList?.add(sharedState.userId!);
        msg = "Added to favorite";
      }
      productDetailsState.updateFavorites(widget.product.id!, widget.product.favoriteList!).then((value) => favoriteChangeMessage(value,msg)) ;
    }
    deleteMessage (bool value){
        if (value){
        Message.showLongToastMessage("Deleted".tr());
        Navigator.pop(context);
        Navigator.pop(context);
        }
    }
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
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
                    context.locale==Locale("en")?widget.product.enName!:widget.product.arName!,
                      textStyle: TextStyle(color: ColorUtilities.textColor,
                        fontSize: 20
                      ),
                  ),
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
                    margin: EdgeInsets.only(right: 40, left: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            sharedState.userType==0?
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                InkWell(
                                  child :Icon(Icons.edit,color: ColorUtilities.secondary,size: 35),
                                  onTap: (){
                                    //Utilities.navigatorWithBack(context, NewProduct(widget.product,true));
                                  },
                                ),
                                SizedBox(width: width*0.05,),
                                InkWell(
                                  child :Icon(CupertinoIcons.delete,color: Colors.red,size: 35),
                                  onTap: (){
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return  AlertDialog(
                                          title: Text("Delete warning".tr()),
                                          content: Text("Are you sure you want to delete this product?".tr()),
                                          actions: [
                                        TextButton(
                                        child: Text("Delete".tr(),style: TextStyle(color: Colors.red),),
                                        onPressed: () {
                                          productDetailsState.deleteProduct(widget.product.id!).then((value) => deleteMessage(value));
                                        },
                                        ),
                                        TextButton(
                                        child: Text("Cancel".tr()),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        )
                                          ],
                                        );;
                                      },
                                    );
                                  },
                                ),
                              ],
                            ):SizedBox(),
                            InkWell(
                              child:favourite?
                              Icon(CupertinoIcons.heart_fill,color:Colors.red,size: 35,):
                              Icon(CupertinoIcons.heart,color: Color.fromRGBO(76, 127, 158, 1),size: 35),
                              onTap: (){
                                changeFavourite();
                              },
                            ),
                          ],
                        ),
                        Container(
                            width: width*0.6,
                            height: height*0.3,
                            child: widget.product.photo!.isNotEmpty? ListView(
                              scrollDirection: Axis.horizontal,
                              children: List.generate(
                                widget.product.photo!.length,
                                    (i) => Container(
                                    width: width*0.5,
                                    alignment: Alignment.center,
                                    child:Container(margin: EdgeInsets.all(10),child:GestureDetector(
                                        child: InkWell(child: Image.network(widget.product.photo![i]),
                                          onTap: ()  {
                                            showDialog<Image>(
                                              context: context,
                                              builder: (BuildContext context) => AlertDialog(
                                                content: Container(
                                                  width: width,
                                                  height: width,
                                                  child:
                                                  PhotoView(
                                                    backgroundDecoration:BoxDecoration(color: Colors.transparent),
                                                    imageProvider: NetworkImage(widget.product.photo![i]),
                                                  ),
                                                ),
                                              ),
                                            );

                                          },)
                                    ))
                                ),
                              ),
                            ):
                                Image.asset("assets/images/defaultProductImage.png")
                        ),
                        WidgetUtilities.autoSizeText(widget.product.price.toString()+"JD".tr(),textStyle: TextStyle(color: Colors.black)),
                        Container(
                          width: width * 0.8,
                          height: height * 0.2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: ColorUtilities.white,
                          ),
                          child: SingleChildScrollView(
                              child: Container(
                            margin: EdgeInsets.all(10),
                            child: Text(widget.product.description!,style: TextStyle(color: Colors.black))
                          )),
                        )
                      ],
                    ))),
          )
        ],
      ),
    );
  }
}
