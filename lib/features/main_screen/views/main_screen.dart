import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/utils/user_role.dart';
import 'package:techno_store/features/app_update/cubit/app_update_cubit.dart';
import 'package:techno_store/features/app_update/view/forced_update_page.dart';
import 'package:techno_store/features/create_user_account/view/create_user_account_view.dart';
import 'package:techno_store/features/home_page/cubit/home_cubit.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';
import 'package:techno_store/features/main_screen/views/widgets/sign_in.dart';
import 'package:techno_store/features/home_page/view/home_page.dart';
import 'package:techno_store/features/main_screen/views/widgets/pin_verification_page.dart';
import 'package:techno_store/features/maintenance_list/cubit/maintenance_list_cubit.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // @override
  // void initState() {
  //   super.initState();
  //   final authCubit = BlocProvider.of<AuthCubit>(context);
  //   authCubit.signOut();
  // }

  @override
  Widget build(BuildContext context) {
    final authCubit = BlocProvider.of<AuthCubit>(context);
    final homeCubit = BlocProvider.of<HomeCubit>(context);
    final maintenanceListCubit = BlocProvider.of<MaintenanceListCubit>(context);
    final appUpdateCubit = BlocProvider.of<AppUpdateCubit>(context);
    return BlocBuilder<AuthCubit, AuthState>(
      bloc: authCubit,
      buildWhen: (previous, current) =>
          current is AuthSuccess ||
          current is AuthInitial ||
          current is AuthLoading ||
          current is AuthRestoredPendingVerification ||
          current is AuthNeedsProfileCompletion,
      builder: (context, state) {
        debugPrint('🔄 MainScreen State: ${state.runtimeType}');
        if (state is AuthRestoredPendingVerification) {
          debugPrint(
              "🔄 MainScreen: Navigating to PIN page for ${state.phoneNumber}");
          return PinVerificationPage(
            verificationId: state.verifyId,
          );
        }
        if (state is AuthNeedsProfileCompletion) {
          debugPrint("📝 User needs to complete profile: ${state.uid}");
          return CreateUserAccount(phoneNumber: state.phoneNumber);
          // return ProfileCompletionPage(
          //   uid: state.uid,
          //   phoneNumber: state.phoneNumber,
          // );
        }

        // Forced-update gate: applied only once auth has reached a stable
        // outcome (AuthSuccess, or the fallback below that renders SignIn) —
        // AuthRestoredPendingVerification/AuthNeedsProfileCompletion above
        // are unaffected. AppUpdateCubit's fetch already started
        // concurrently with checkAuth() when this route was created, so
        // there's normally no added latency here. See
        // docs/ai-workflow/FORCED_UPDATE_IMPLEMENTATION_PLAN.md §7.
        return BlocBuilder<AppUpdateCubit, AppUpdateState>(
          bloc: appUpdateCubit,
          builder: (context, updateState) {
            if (updateState is AppUpdateForceRequired) {
              return ForcedUpdatePage(platformInfo: updateState.platformInfo);
            }
            if (updateState is AppUpdateInitial ||
                updateState is AppUpdateLoading) {
              // Auth already resolved but the (concurrently-started) config
              // fetch hasn't — brief spinner instead of flashing
              // SignIn/HomePage and immediately replacing it.
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (state is AuthSuccess) {
              homeCubit.loadUserData();

              final userType = state.userData!.type;
              if (UserRole.isCustomer(userType)) {
                maintenanceListCubit
                    .listenToMaintenanceDevices(state.userData!.uid);
              } else if (UserRole.isStaff(userType)) {
                maintenanceListCubit.listenToMaintenanceDevices(null);
              }
              // Any other role (e.g. GuestAccount) intentionally starts no
              // listener at all — MaintenanceListCubit stays in its initial
              // state, which the UI renders as an empty state, not an
              // error. See docs/ai-workflow/ADR-003-guest-account-behavior.md.

              return const HomePage();
            }
            if (state is AuthInitial) {
              // Reached on sign-out (and on the very first build, before
              // any listener has started — cancelling a null subscription
              // is a no-op). Stops the maintenance devices stream so it
              // doesn't keep running with an auth context that no longer
              // applies, and so a different user signing in next doesn't
              // briefly see this user's device list. See
              // MaintenanceListCubit.stopListening.
              maintenanceListCubit.stopListening();
            }
            return const SignIn();
          },
        );
      },
    );
  }
}
