import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/utils/user_role.dart';
import 'package:techno_store/core/utils/utilities.dart';
import 'package:techno_store/core/widgets/main_drawer2.dart';
import 'package:techno_store/features/maintenance_list/view/inner_maintenance_list.dart';
import 'package:techno_store/core/widgets/message.dart';
import 'package:techno_store/core/utils/app_colors.dart';
import 'package:techno_store/core/widgets/main_app_bar.dart';
import 'package:techno_store/core/widgets/main_footer.dart';
import 'package:techno_store/features/home_page/cubit/home_cubit.dart';
import '../../../core/utils/widget_utilities.dart';
import '../../store_page/widgets/inner_store_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _advancedDrawerController = AdvancedDrawerController();
  int _current = 0;
  final List<String> imgList = [
    'https://nabma.com/version2020/wp-content/uploads/2020/11/mobile-Phone-Repair-Service-London.jpg',
    'https://cnlsrepair.co.uk/wp-content/uploads/2024/01/smartphone-repairman-removing-screws-1.webp',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSdRTLc-9IvDGuBSSIlusNPRu8cuA0YLk2Rsw&s',
    'https://images.indianexpress.com/2023/05/iphone-14-offer-amazon.jpg',
  ];
  @override
  Widget build(BuildContext context) {
    final homeCubit = BlocProvider.of<HomeCubit>(context);
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    final _controller = CarouselSliderController();
    final List<Widget> imageSliders = imgList
        .map(
          (item) => Container(
            margin: const EdgeInsets.all(0.0),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              child: CachedNetworkImage(
                imageUrl: item,
                fit: BoxFit.cover,
                // width: 500,
              ),
            ),
          ),
        )
        .toList();
    return AdvancedDrawer(
      openRatio: width <= 500 ? 0.75 : 0.35,
      backdrop: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary,
            ],
          ),
        ),
      ),
      controller: _advancedDrawerController,
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      animateChildDecoration: true,
      rtlOpening: Utilities.isEnglish(context) ? false : true,
      // openScale: 1,
      disabledGestures: false,
      childDecoration: const BoxDecoration(
        // NOTICE: Uncomment if you want to add shadow behind the page.
        // Keep in mind that it may cause animation jerks.
        // boxShadow: <BoxShadow>[
        //   BoxShadow(
        //     color: Colors.black12,
        //     blurRadius: 50,
        //   ),
        // ],
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      // ignore: prefer_const_constructors
      drawer: MainDrawer2(),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize:
              Size.fromHeight(width <= 500 ? height * 0.05 : height * 0.08),
          child: MainAppBar(
            advancedDrawerController: _advancedDrawerController,
            title: 'Home'.tr(),
            onLanguageChanged: () => setState(() {}),
          ),
        ),
        resizeToAvoidBottomInset: false,
        // drawer: (width <= 1024) ? const MainDrawer() : null,
        body: BlocBuilder<HomeCubit, HomeState>(
          bloc: homeCubit,
          buildWhen: (previous, current) =>
              current is HomeLoaded ||
              current is HomeError ||
              current is HomeLoading,
          builder: (context, state) {
            if (state is HomeError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Message.showBottomMessage(context, state.message,
                    isError: true);
              });
              return const Center(
                child: Text("Error when fetch data"),
              );
            } else if (state is HomeLoaded) {
              final isStaff = UserRole.isStaff(state.userData.type);
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width <= 1025 ? width * 0.05 : width * 0.1,
                ),
                child: Column(
                  children: [
                    // Banner + Contact Us are customer-facing marketing
                    // surfaces; staff only need the Maintenance tab below.
                    // Guest keeps the customer experience too, since
                    // UserRole.isStaff is an allow-list (see
                    // ADR-003-guest-account-behavior.md).
                    if (!isStaff) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      CarouselSlider(
                        items: imageSliders,
                        carouselController: _controller,
                        options: CarouselOptions(
                            scrollDirection:
                                width < 1025 ? Axis.vertical : Axis.horizontal,
                            height: width < 500
                                ? height * 0.2
                                : width < 1025
                                    ? height * 0.20
                                    : height * 0.20,
                            autoPlay: true,
                            pageSnapping: false,
                            disableCenter: true,
                            viewportFraction: width < 1025 ? 0.8 : 0.2,
                            enlargeCenterPage: true,
                            // aspectRatio: 2,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _current = index;
                              });
                            }),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: imgList.asMap().entries.map((entry) {
                          return GestureDetector(
                            onTap: () => _controller.animateToPage(entry.key),
                            child: Container(
                              width: 8.0,
                              height: 8.0,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 4.0),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black)
                                      .withOpacity(
                                          _current == entry.key ? 0.9 : 0.4)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    Expanded(
                      child: DefaultTabController(
                        // length: state.userData.type == 3 ? 1 : 2,
                        length: 1,
                        child: Row(
                          children: [
                            // if (width > 1024)
                            //   SizedBox(
                            //     width: width * 0.20,
                            //     child: const MainDrawer(),
                            //   ),
                            Expanded(
                              child: Column(
                                children: [
                                  TabBar(
                                    dividerHeight: 3,
                                    dividerColor: AppColors.white,
                                    indicatorColor: AppColors.primary,
                                    tabs: [
                                      Tab(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.add_to_home_screen,
                                              color: AppColors.primary,
                                            ),
                                            WidgetUtilities.autoSizeText(
                                              "Maintenance",
                                              textStyle: const TextStyle(
                                                color: AppColors.primary,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      // if (state.userData.type != 3)
                                      //   Tab(
                                      //     child: Row(
                                      //       mainAxisAlignment:
                                      //           MainAxisAlignment.center,
                                      //       children: [
                                      //         const Icon(
                                      //           Icons.shopping_cart,
                                      //           color: AppColors.primary,
                                      //         ),
                                      //         WidgetUtilities.autoSizeText(
                                      //           "Store",
                                      //           textStyle: const TextStyle(
                                      //             color: AppColors.primary,
                                      //           ),
                                      //         )
                                      //       ],
                                      //     ),
                                      //   ),
                                    ],
                                  ),
                                  const Expanded(
                                    child: TabBarView(
                                      children: [
                                        InnerMaintenanceList(
                                          heroTagPrefix: 'home',
                                        ),
                                        // if (state.userData.type != 3)
                                        //   const InnerStorePage(),
                                      ],
                                    ),
                                  ),
                                  if (!isStaff) const MainFooter(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return const Column(
              children: [
                Spacer(),
                Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
                Spacer(),
                MainFooter(),
              ],
            );
          },
        ),
      ),
    );
  }
}
