import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:techno_store/core/favorite_items/view_model/favorite_items_state.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:techno_store/features/maintenance_list/view_model/maintenance_list_state.dart';
import 'package:techno_store/core/product_details/view_model/product_details_state.dart';
import 'package:techno_store/core2/route/app_router.dart';
import 'package:techno_store/core2/route/app_routes.dart';
import 'package:techno_store/core/shared/view_model/shared_state.dart';
import 'package:techno_store/core2/utils/app_constants.dart';
import 'package:techno_store/core2/utils/app_theme.dart';
import 'package:techno_store/firebase_options.dart';
import 'core/manage_categories/view_model/manage_categories_state.dart';
import 'core/new_device_maintenance/view_model/new_device_maintenance_state.dart';
import 'core/new_product/view_model/new_product_state.dart';
import 'core/store/view_model/store_state.dart';
import 'core/track_phone_page/view_model/track_phone_page_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await EasyLocalization.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path:
          'assets/translations', // <-- change the path of the translation files
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // ChangeNotifierProvider(create: (_) => WelcomePageState()),
        ChangeNotifierProvider(create: (_) => SharedState()),
        ChangeNotifierProvider(create: (_) => NewProductState()),
        ChangeNotifierProvider(create: (_) => StoreState()),
        ChangeNotifierProvider(create: (_) => NewDeviceMaintenanceState()),
        ChangeNotifierProvider(create: (_) => TrackPhonePageState()),
        ChangeNotifierProvider(create: (_) => ManageCategories()),
        ChangeNotifierProvider(create: (_) => MaintenanceListState()),
        ChangeNotifierProvider(create: (_) => ProductDetailsState()),
        ChangeNotifierProvider(create: (_) => FavoriteItemsState()),
      ],
      child: MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        // theme: AppTheme.darkTheme,
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRoutes.main,
      ),
    );
  }
}
