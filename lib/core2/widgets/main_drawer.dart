import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/favorite_items/view/favorite_Items.dart';
import 'package:techno_store/features/maintenance_list/view/inner_maintenance_list.dart';
import 'package:techno_store/core/manage_categories/view/manage_category_view.dart';
import 'package:techno_store/core/new_product/view/new_product.dart';
import 'package:techno_store/features/new_user_admin_side/view/new_user_admin_side.dart';
import 'package:techno_store/features/store_page/widgets/inner_store_page.dart';
import 'package:techno_store/core/track_phone_page/view/track_phone_page.dart';
import 'package:techno_store/core2/widgets/message.dart';
import 'package:techno_store/core/utils/utilities.dart';
import 'package:techno_store/core/utils/widget_utilities.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/core2/widgets/custom_dialogs.dart';
import 'package:techno_store/features/home_page/cubit/home_cubit.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  Widget card(BuildContext context, String title, Icon icon, double height,
      double width, Function() tap) {
    return Column(
      children: [
        InkWell(
          onTap: tap,
          child: Padding(
            padding: Utilities.isEnglish(context)
                ? const EdgeInsets.only(left: 20)
                : const EdgeInsets.only(right: 20),
            child: SizedBox(
              height: height * 0.05,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  icon,
                  SizedBox(
                    width: width * 0.01,
                  ),
                  Expanded(
                    child: WidgetUtilities.autoSizeText(
                      maxLine: 2,
                      title,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        const Divider(
          color: AppColors.secondary2,
          thickness: 1,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
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
            bottom: width > 1024 ? false : true,
            child: Drawer(
              width: width < 500 ? 0.5 * width : 0.3 * width,
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircleAvatar(
                      backgroundImage:
                          (profileImage == null || profileImage == '')
                              ? const AssetImage("assets/images/defaultImg.png")
                              : CachedNetworkImageProvider(profileImage)
                                  as ImageProvider,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  WidgetUtilities.autoSizeText(
                    state.userData.name ?? 'No Name',
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  Flexible(
                      child: ListView(
                    children: [
                      state.userData.type != 3 &&
                              state.userData.type != 9 // 9 for guest
                          ? card(
                              context,
                              "Favorite",
                              const Icon(Icons.star, color: Colors.yellow),
                              height,
                              width, () {
                              Utilities.navigatorWithBack(
                                  context, const FavoriteItems());
                            })
                          : const SizedBox(),
                      state.userData.type != 3
                          ? card(
                              context,
                              "Store",
                              const Icon(
                                Icons.shopping_cart,
                                color: Colors.white60,
                              ),
                              height,
                              width, () {
                              Utilities.navigatorWithBack(
                                  context, const InnerStorePage());
                            })
                          : const SizedBox(),
                      state.userData.type == 1
                          ? card(
                              context,
                              "Maintenance (My Devices)",
                              const Icon(
                                Icons.phone_android,
                                color: Colors.white60,
                              ),
                              height,
                              width, () {
                              Utilities.navigatorWithBack(
                                  context, const TrackPhonePage());
                            })
                          : const SizedBox(),
                      state.userData.type != 1
                          ? card(
                              context,
                              "Maintenance",
                              const Icon(Icons.add_to_home_screen,
                                  color: Colors.white60),
                              height,
                              width, () {
                              Utilities.navigatorWithBack(
                                  context, const InnerMaintenanceList());
                            })
                          : const SizedBox(),
                      state.userData.type == 0
                          ? card(
                              context,
                              "Add new Employee",
                              const Icon(
                                Icons.person_add,
                                color: Colors.white60,
                              ),
                              height,
                              width, () {
                              Utilities.navigatorWithBack(
                                  context, const NewUserAdminSide());
                            })
                          : const SizedBox(),
                      state.userData.type == 0 || state.userData.type == 2
                          ? card(
                              context,
                              "Add new Product",
                              const Icon(
                                Icons.note_add,
                                color: Colors.white60,
                              ),
                              height,
                              width, () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const NewProduct(
                                          editable: false,
                                        )),
                              );
                            })
                          : const SizedBox(),
                      state.userData.type == 0 || state.userData.type == 2
                          ? card(
                              context,
                              "Manage Categories",
                              const Icon(
                                Icons.category,
                                color: Colors.white60,
                              ),
                              height,
                              width, () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const manageCategory()),
                              );
                            })
                          : const SizedBox(),
                    ],
                  )),
                  InkWell(
                    onTap: () async {
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
                    child: DecoratedBox(
                      decoration:
                          const BoxDecoration(color: AppColors.secondary2),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout,
                              color: AppColors.secondary2,
                            ),
                            if (!Utilities.isEnglish(context))
                              const SizedBox(width: 8),
                            WidgetUtilities.autoSizeText(
                              textStyle: const TextStyle(
                                color: AppColors.red2,
                                fontWeight: FontWeight.bold,
                              ),
                              "Logout",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // state.userData.type != 9
                  //     ? InkWell(
                  //         onTap: () async {
                  //           showDialog(
                  //               context: context,
                  //               builder: (BuildContext ctx) {
                  //                 return AlertDialog(
                  //                   title: Text("Please Confirm".tr()),
                  //                   content: Text(
                  //                       'Are you sure you want to remove the account?'
                  //                           .tr()),
                  //                   actions: [
                  //                     // The "Yes" button
                  //                     TextButton(
                  //                         onPressed: () async {
                  //                           try {
                  //                             // await welcomePageState
                  //                             //     .removeAccount();
                  //                           } catch (e) {
                  //                             //print(e.toString());
                  //                           }

                  //                           // Close the dialog
                  //                           Navigator.of(context).pop();
                  //                         },
                  //                         child: Text('Yes'.tr())),
                  //                     TextButton(
                  //                         onPressed: () {
                  //                           // Close the dialog
                  //                           Navigator.of(context).pop();
                  //                         },
                  //                         child: Text('No'.tr()))
                  //                   ],
                  //                 );
                  //               });
                  //         },
                  //         child: Container(
                  //             padding: const EdgeInsets.all(10),
                  //             width: width,
                  //             color: Colors.white60,
                  //             height: 40,
                  //             child: Row(
                  //               mainAxisAlignment: MainAxisAlignment.center,
                  //               children: [
                  //                 const Icon(
                  //                   Icons.delete,
                  //                   color: Colors.red,
                  //                 ),
                  //                 WidgetUtilities.autoSizeText("Delete account",
                  //                     textStyle:
                  //                         const TextStyle(color: Colors.red)),
                  //               ],
                  //             )),
                  //       )
                  //     : const SizedBox(),
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
