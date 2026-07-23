import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';
import 'package:techno_store/core/model/user_data.dart';
import 'package:techno_store/core/utils/user_role.dart';
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
  // Route-level authorization: role-gated screens are protected only by the
  // drawer not showing their entry point unless this check also confirms
  // it server-side... which it can't (no backend call here) — this is
  // defense-in-depth against reaching the screen via a direct pushNamed
  // call, not a substitute for the Firestore rules / Cloud Function checks
  // that remain the actual enforcement backstop for any write. See ADR-004
  // ("Route-level authorization") — this closes the gap it flagged.
  static Route<dynamic> _unauthorizedRoute() => CupertinoPageRoute(
        builder: (_) => const MainProgressIndicator(),
      );

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
        final args = settings.arguments as Map<String, dynamic>?;
        final adminUserData = args?['userData'] as UserData?;
        if (adminUserData == null || !UserRole.isAdmin(adminUserData.type)) {
          return _unauthorizedRoute();
        }
        return CupertinoPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => AuthCubit(),
            child: const NewUserAdminSide(),
          ),
        );

      case AppRoutes.newDeviceMaintenance:
        final args = settings.arguments as Map<String, dynamic>?;
        final device = args?['device'] as MaintenanceDeviceModel?;
        final newDeviceUserData = args?['userData'] as UserData?;
        if (newDeviceUserData == null ||
            !UserRole.isStaff(newDeviceUserData.type)) {
          return _unauthorizedRoute();
        }

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
        final maintenanceUserData = args['userData'] as UserData?;
        if (maintenanceUserData == null ||
            !UserRole.isStaff(maintenanceUserData.type)) {
          return _unauthorizedRoute();
        }

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
