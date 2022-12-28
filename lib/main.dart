import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/main_screen/view/main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:techno_store/core/maintenance_list/view_model/maintenance_list_state.dart';
import 'package:techno_store/core/product_details/view_model/product_details_state.dart';
import 'package:techno_store/core/welcome_page/view_model/welcome_page_state.dart';
import 'core/main_screen/view_model/main_screen_state.dart';
import 'core/manage_categories/view_model/manage_categories_state.dart';
import 'core/new_device_maintenance/view_model/new_device_maintenance_state.dart';
import 'core/new_product/view_model/new_product_state.dart';
import 'core/reset_password/view_model/reset_password_state.dart';
import 'core/shared/view_model/shared_state.dart';
import 'core/store/view_model/store_state.dart';
import 'core/track_phone_page/view_model/track_phone_page_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await EasyLocalization.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    EasyLocalization(
      supportedLocales: [Locale('en'), Locale('ar')],
      path:
          'assets/translations', // <-- change the path of the translation files
      fallbackLocale: Locale('en'),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MainScreenState()),
        ChangeNotifierProvider(create: (_) => WelcomePageState()),
        ChangeNotifierProvider(create: (_) => SharedState()),
        ChangeNotifierProvider(create: (_) => NewProductState()),
        ChangeNotifierProvider(create: (_) => StoreState()),
        ChangeNotifierProvider(create: (_) => NewDeviceMaintenanceState()),
        ChangeNotifierProvider(create: (_) => TrackPhonePageState()),
        ChangeNotifierProvider(create: (_) => ManageCategories()),
        ChangeNotifierProvider(create: (_) => ResetPasswordState()),
        ChangeNotifierProvider(create: (_) => MaintenanceListState()),
        ChangeNotifierProvider(create: (_) => ProductDetailsState()),

      ],
      child: MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    Timer(Duration(milliseconds: 4500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const MainScreen()),
      );
    });

    return Container(
      color: Colors.white,
      child: Center(
        child: Container(
          width: 200,
          height: 200,
          child: Image.asset(
            "assets/images/logo.gif",
          ),
        ),
      ),
    );
  }
}
