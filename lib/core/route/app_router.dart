import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';
import 'package:techno_store/features/app_update/cubit/app_update_cubit.dart';
import 'package:techno_store/features/home_page/cubit/home_cubit.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';
import 'package:techno_store/features/main_screen/views/main_screen.dart';
import 'package:techno_store/core/route/app_routes.dart';
import 'package:techno_store/core/widgets/main_progress_indicator.dart';
import 'package:techno_store/features/maintenance_list/cubit/maintenance_list_cubit.dart';
import 'package:techno_store/features/maintenance_list/view/maintenance_page.dart';
import 'package:techno_store/features/new_device_maintenance/cubit/new_device_cubit.dart';
import 'package:techno_store/features/new_device_maintenance/view/new_device_maintenance.dart';
import 'package:techno_store/features/new_user_admin_side/view/new_user_admin_side.dart';
import 'package:techno_store/features/product_details.dart/view/product_details_page.dart';

class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      //
      case AppRoutes.mainScreen:
        return CupertinoPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) {
                  final cubit = AuthCubit();
                  cubit.checkAuth();
                  return cubit;
                },
              ),
              BlocProvider(
                create: (context) => HomeCubit(),
              ),
              BlocProvider(
                create: (context) => MaintenanceListCubit(),
              ),
              BlocProvider(
                create: (context) => AppUpdateCubit(),
              ),
            ],
            child: const MainScreen(),
          ),
          settings: settings,
        );

      case AppRoutes.productDetailsPage:
        return CupertinoPageRoute(
          builder: (_) => const ProductDetailsPage(),
        );
      case AppRoutes.createAccountAdminSide:
        return CupertinoPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => AuthCubit(),
            child: const NewUserAdminSide(),
          ),
        );

      case AppRoutes.newDeviceMaintenance:
        final args = settings.arguments as Map<String, dynamic>?;
        final device = args?['device'] as MaintenanceDeviceModel?;

        debugPrint(
            '🔧 Navigating to NewDeviceMaintenance with device: ${device?.id}');
        return CupertinoPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => NewDeviceCubit(),
              ),
              BlocProvider(
                create: (context) => MaintenanceListCubit(),
              ),
            ],
            child: NewDeviceMaintenance(
              device: device,
            ), // سيتم تمرير الجهاز من خلال arguments
          ),
        );

      case AppRoutes.maintenancePage:
        final args = settings.arguments as Map<String, dynamic>;
        final homeCubit = args['homeCubit'] as HomeCubit;
        final authCubit = args['authCubit'] as AuthCubit;
        final maintenanceListCubit =
            args['maintenanceListCubit'] as MaintenanceListCubit;

        debugPrint('🔧 Creating MaintenancePage with shared Cubit');

        return CupertinoPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: homeCubit),
              BlocProvider.value(value: authCubit),
              BlocProvider.value(value: maintenanceListCubit),
            ],
            child: const MaintenancePage(),
          ),
          settings: settings,
        );

      default:
        return CupertinoPageRoute(
          builder: (_) => const MainProgressIndicator(),
        );
    }
  }
}
