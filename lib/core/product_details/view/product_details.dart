import 'package:flutter/material.dart';

class ProductDetails extends StatefulWidget {
  const ProductDetails({Key? key}) : super(key: key);

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
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
                    "IPhone 14 Pro",
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
                        Container(
                          width: width * 0.6,
                          height: height * 0.3,
                          child: Image.asset(
                            "assets/images/iPhone-14.png",
                            fit: BoxFit.fill,
                          ),
                        ),
                        Text("1000 JD", style: TextStyle(fontSize: 18)),
                        Container(
                          width: width * 0.8,
                          height: height * 0.2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white,
                          ),
                          child: SingleChildScrollView(
                              child: Container(
                            margin: EdgeInsets.all(10),
                            child: Text("Details"),
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
