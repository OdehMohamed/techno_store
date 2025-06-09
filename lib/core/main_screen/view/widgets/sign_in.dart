import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/main_screen/view/widgets/sign_in_form.dart';
import 'package:techno_store/core/main_screen/view_model/main_screen_state.dart';
import 'package:techno_store/core/shared/view_model/shared_state.dart';
import 'package:techno_store/shared/color_utilities.dart';
import 'package:techno_store/shared/widget_utilities.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final login_email = TextEditingController();
  final login_password = TextEditingController();
  late MainScreenState mainScreenState;
  late SharedState sharedState;
  bool? isTesting;

  @override
  void initState() {
    mainScreenState = context.read<MainScreenState>();
    sharedState = context.read<SharedState>();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      getTestingValue();
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      checkForUpdate();
    }
    super.initState();
  }

  @override
  void dispose() {
    login_email.dispose();
    login_password.dispose();
    super.dispose();
  }

  AppUpdateInfo? _updateInfo;

  GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey();

  void getTestingValue() async {
    isTesting = await sharedState.isTesting();
  }

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
    mainScreenState = context.watch<MainScreenState>();
    sharedState = context.watch<SharedState>();

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: WidgetUtilities.customAppBar(context),
      body: ModalProgressHUD(
        inAsyncCall: mainScreenState.loading,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: Column(
            children: [
              WidgetUtilities.headerApp(context),
              Container(
                width: width,
                height: height * 0.85,
                decoration: const BoxDecoration(
                  color: ColorUtilities.backgroundContainer,
                ),
                child: SignInForm(
                    mainScreenState: mainScreenState,
                    sharedState: sharedState,
                    isTesting: isTesting),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
