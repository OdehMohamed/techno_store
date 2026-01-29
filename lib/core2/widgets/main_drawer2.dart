import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/favorite_items/view/favorite_Items.dart';
import 'package:techno_store/core/manage_categories/view/manage_category_view.dart';
import 'package:techno_store/core/new_product/view/new_product.dart';
import 'package:techno_store/core2/route/app_routes.dart';
import 'package:techno_store/core/track_phone_page/view/track_phone_page.dart';
import 'package:techno_store/core2/widgets/message.dart';
import 'package:techno_store/core/utils/utilities.dart';
import 'package:techno_store/core/utils/widget_utilities.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/core2/widgets/custom_dialogs.dart';
import 'package:techno_store/features/home_page/cubit/home_cubit.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';
import 'package:techno_store/features/maintenance_list/view/maintenance_page.dart';
import 'package:techno_store/features/manage_category/view/manage_categories_page.dart';
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
                  state.userData.type != 3 &&
                          state.userData.type != 9 // 9 for guest
                      ? ListTile(
                          onTap: () {
                            Utilities.navigatorWithBack(
                              context,
                              const FavoriteItems(),
                            );
                          },
                          leading: const Icon(Icons.favorite),
                          title: WidgetUtilities.autoSizeText('Favorite'),
                        )
                      : const SizedBox(),
                  state.userData.type != 3
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
                  state.userData.type == 1
                      ? ListTile(
                          onTap: () {
                            Utilities.navigatorWithBack(
                                context, const TrackPhonePage());
                          },
                          leading: const Icon(
                            Icons.phone_android,
                          ),
                          title: WidgetUtilities.autoSizeText(
                            'Maintenance (My Devices)',
                            maxLine: 2,
                          ),
                        )
                      : const SizedBox(),
                  state.userData.type != 1
                      ? ListTile(
                          onTap: () {
                            Utilities.navigatorWithBack(
                              context,
                              const MaintenancePage(),
                            );
                          },
                          leading: const Icon(
                            Icons.phone_android,
                          ),
                          title: WidgetUtilities.autoSizeText('Maintenance'),
                        )
                      : const SizedBox(),
                  state.userData.type == 0
                      ? ListTile(
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed(AppRoutes.createAccountAdminSide);
                          },
                          leading: const Icon(
                            Icons.person_add,
                          ),
                          title:
                              WidgetUtilities.autoSizeText('Add new Employee'),
                        )
                      : const SizedBox(),
                  state.userData.type == 0 || state.userData.type == 2
                      ? ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const NewProduct(
                                        editable: false,
                                      )),
                            );
                          },
                          leading: const Icon(
                            Icons.note_add,
                          ),
                          title:
                              WidgetUtilities.autoSizeText('Add new Product'),
                        )
                      : const SizedBox(),
                  state.userData.type == 0 || state.userData.type == 2
                      ? ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ManageCategoriesPage(),
                              ),
                            );
                          },
                          leading: const Icon(
                            Icons.category,
                          ),
                          title:
                              WidgetUtilities.autoSizeText('Manage Categories'),
                        )
                      : const SizedBox(),
                  ListTile(
                    onTap: () {},
                    leading: const Icon(
                      Icons.settings,
                    ),
                    title: WidgetUtilities.autoSizeText('Settings'),
                  ),
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
