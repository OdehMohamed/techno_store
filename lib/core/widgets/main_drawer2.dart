import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/route/app_routes.dart';
import 'package:techno_store/core/widgets/message.dart';
import 'package:techno_store/core/utils/utilities.dart';
import 'package:techno_store/core/utils/widget_utilities.dart';
import 'package:techno_store/core/utils/app_colors.dart';
import 'package:techno_store/core/utils/user_role.dart';
import 'package:techno_store/core/widgets/custom_dialogs.dart';
import 'package:techno_store/features/home_page/cubit/home_cubit.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';
import 'package:techno_store/features/maintenance_list/cubit/maintenance_list_cubit.dart';
import 'package:techno_store/features/store_page/view/store_page.dart';

class MainDrawer2 extends StatefulWidget {
  const MainDrawer2({super.key});

  @override
  State<MainDrawer2> createState() => _MainDrawer2State();
}

class _MainDrawer2State extends State<MainDrawer2> {
  @override
  Widget build(BuildContext context) {
    final authCubit = BlocProvider.of<AuthCubit>(context);
    final homeCubit = BlocProvider.of<HomeCubit>(context);
    return BlocBuilder<HomeCubit, HomeState>(
      bloc: homeCubit,
      buildWhen: (previous, current) =>
          current is HomeLoaded ||
          current is HomeError ||
          current is HomeLoading,
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (state is HomeError) {
          Message.showBottomMessage(context, state.message, isError: true);
        }
        if (state is HomeLoaded) {
          final profileImage = state.userData.photoURL;
          final type = state.userData.type;
          return SafeArea(
            child: ListTileTheme(
              textColor: Colors.white,
              iconColor: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 128.0,
                        height: 128.0,
                        margin: const EdgeInsets.only(
                          top: 24.0,
                          bottom: 20.0,
                        ),
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: (profileImage == null || profileImage == '')
                            ? Image.asset("assets/images/defaultImg.png")
                            : CachedNetworkImage(imageUrl: profileImage),
                      ),
                      WidgetUtilities.autoSizeText(
                        state.userData.name ?? 'No Name',
                      ),
                      const SizedBox(height: 32.0),
                    ],
                  ),
                  // Store: Admin, Customer, Reception. Was previously a
                  // deny-list (`!= 3`) that also (unintentionally) let Guest
                  // see this item — converting to an explicit allow-list
                  // means Guest no longer does, consistent with treating
                  // Guest as having no granted capabilities by default
                  // (see docs/ai-workflow/ADR-003-guest-account-behavior.md).
                  (UserRole.isAdmin(type) ||
                          UserRole.isCustomer(type) ||
                          UserRole.isReception(type))
                      ? ListTile(
                          onTap: () {
                            Utilities.navigatorWithBack(
                                context, const StorePage());
                          },
                          leading: const Icon(
                            Icons.shopping_cart,
                          ),
                          title: WidgetUtilities.autoSizeText('Store'),
                        )
                      : const SizedBox(),
                  // Staff-wide maintenance list navigation. This was
                  // previously a deny-list (`!= 1`, "not customer"), which is
                  // exactly how Guest ended up able to navigate to the
                  // unrestricted, system-wide device list. Now an explicit
                  // staff allow-list.
                  UserRole.isStaff(type)
                      ? ListTile(
                          onTap: () {
                            final maintenanceListCubit =
                                context.read<MaintenanceListCubit>();
                            Navigator.of(context).pushNamed(
                              AppRoutes.maintenancePage,
                              arguments: {
                                'homeCubit': homeCubit,
                                'authCubit': authCubit,
                                'userData': state.userData,
                                'maintenanceListCubit': maintenanceListCubit,
                              },
                            );
                          },
                          leading: const Icon(
                            Icons.phone_android,
                          ),
                          title: WidgetUtilities.autoSizeText('Maintenance'),
                        )
                      : const SizedBox(),
                  UserRole.isAdmin(type)
                      ? ListTile(
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.createAccountAdminSide,
                              arguments: {'userData': state.userData},
                            );
                          },
                          leading: const Icon(
                            Icons.person_add,
                          ),
                          title:
                              WidgetUtilities.autoSizeText('Add new Employee'),
                        )
                      : const SizedBox(),
                  // Restore/Permanent Delete are always Admin-only,
                  // enforced at the data layer regardless of how this
                  // screen is reached — this gate is defense-in-depth, not
                  // the real one. See ADR-005.
                  UserRole.isAdmin(type)
                      ? ListTile(
                          onTap: () {
                            final maintenanceListCubit =
                                context.read<MaintenanceListCubit>();
                            Navigator.of(context).pushNamed(
                              AppRoutes.archivedDevices,
                              arguments: {
                                'userData': state.userData,
                                'maintenanceListCubit': maintenanceListCubit,
                              },
                            );
                          },
                          leading: const Icon(
                            Icons.archive_outlined,
                          ),
                          title: WidgetUtilities.autoSizeText(
                              'Archived Devices'),
                        )
                      : const SizedBox(),
                  ListTile(
                    onTap: () {
                      CustomDialogs.showDialogConfirm(
                        context: context,
                        title: "Please Confirm",
                        content: "Are you sure you want to logout?",
                        onPressed: () async {
                          try {
                            Navigator.of(context).pop();
                            await authCubit.signOut();
                          } catch (e) {
                            debugPrint(e.toString());
                          }
                        },
                      );
                    },
                    leading: const Icon(
                      Icons.logout,
                      color: AppColors.red2,
                    ),
                    title: WidgetUtilities.autoSizeText(
                        textStyle: const TextStyle(
                          color: AppColors.red2,
                          fontWeight: FontWeight.bold,
                        ),
                        'Logout'),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
