import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:techno_store/core2/widgets/main_app_bar.dart';
import 'package:techno_store/features/main_screen/views/widgets/sign_in_form_email_method.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb && Theme.of(context).platform == TargetPlatform.iOS) {}
      if (!kIsWeb &&
          Platform.isAndroid &&
          const bool.fromEnvironment('dart.vm.product')) {
        checkForUpdate();
      }
    });
  }

  AppUpdateInfo? _updateInfo;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  Future<void> checkForUpdate() async {
    InAppUpdate.checkForUpdate().then((info) {
      setState(() {
        _updateInfo = info;
      });
      if (_updateInfo?.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        update();
      }
    }).catchError((e) {
      showSnack(e.toString());
    });
  }

  void showSnack(String text) {
    if (_scaffoldKey.currentContext != null) {
      ScaffoldMessenger.of(_scaffoldKey.currentContext!)
          .showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void update() {
    InAppUpdate.performImmediateUpdate().catchError((e) {
      showSnack(e.toString());
      return Future.value(AppUpdateResult.inAppUpdateFailed);
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    final _advancedDrawerController = AdvancedDrawerController();
    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(width <= 500 ? height * 0.05 : height * 0.08),
        child: MainAppBar(
          haveLeading: false,
          advancedDrawerController: _advancedDrawerController,
          title: '',
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: SizedBox(
          width: width,
          // height: height * 0.92,
          child: const SignInFormEmailMethod(),
        ),
      ),
    );
  }
}
