import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/features/home_page/cubit/home_cubit.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';
import 'package:techno_store/features/main_screen/views/main_screen.dart';
import 'package:techno_store/core2/route/app_routes.dart';
import 'package:techno_store/core2/widgets/main_progress_indicator.dart';
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

      default:
        return CupertinoPageRoute(
          builder: (_) => const MainProgressIndicator(),
        );
    }
  }
}
