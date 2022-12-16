import 'package:flutter/material.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

final email_controller = TextEditingController();

class _ResetPasswordState extends State<ResetPassword> {
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
                  child: Text(
                    "Reset Password",
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
                        Text(
                          "We will send an Email to reset your password ",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        Container(
                          padding: EdgeInsets.only(left: 20, right: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: TextField(
                            controller: email_controller,
                            style: TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: ' Please Enter your Email ',
                              hintStyle:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          child: Container(
                            width: width * 0.6,
                            height: height * 0.06,
                            child: Center(
                                child: Text(
                              "Send Email",
                              textAlign: TextAlign.center,
                            )),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: Color.fromRGBO(76, 127, 158, 1),
                            textStyle:
                                TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ))),
          )
        ],
      ),
    );
  }
}
