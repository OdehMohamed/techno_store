import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:techno_store/core/model/device_tab_page.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';
import 'package:techno_store/core/model/user_data.dart';
import 'package:techno_store/core/route/app_routes.dart';
import 'package:techno_store/core/utils/app_colors.dart';
import 'package:techno_store/core/utils/app_constants.dart';
import 'package:techno_store/core/utils/user_role.dart';
import 'package:techno_store/core/widgets/custom_dialogs.dart';
import 'package:techno_store/core/widgets/message.dart';
import 'package:techno_store/features/home_page/cubit/home_cubit.dart';
import 'package:techno_store/features/maintenance_list/cubit/maintenance_list_cubit.dart';
import 'package:techno_store/features/maintenance_list/services/maintenance_list_services.dart';
import 'package:techno_store/features/maintenance_list/view/widgets/device_card.dart';
import 'package:techno_store/features/maintenance_list/view/widgets/device_details_sheet.dart';
import 'package:techno_store/features/new_device_maintenance/widgets/image_section_widget.dart';
import 'package:techno_store/features/maintenance_list/view/widgets/maintenance_states.dart';

class InnerMaintenanceList extends StatefulWidget {
  final String? heroTagPrefix; // لتمييز Hero tags

  const InnerMaintenanceList({Key? key, this.heroTagPrefix}) : super(key: key);

  @override
  State<InnerMaintenanceList> createState() => _InnerMaintenanceListState();
}

class _InnerMaintenanceListState extends State<InnerMaintenanceList>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Search/filter state — see
  // docs/ai-workflow/SEARCH_FILTER_IMPLEMENTATION_PLAN.md. At most one of
  // _selectedBrand/_selectedEmployee/_selectedDateRange is set at a time;
  // selecting one clears the others (status + at most one more filter).
  String? _selectedBrand;
  String? _selectedEmployee;
  DateTimeRange? _selectedDateRange;

  // Populated from HomeState once available (see build()).
  String? _uid;
  UserData? _userData;

  static const List<String> _tabStatuses = [
    DeviceStatus.inMaintenance,
    DeviceStatus.fixed,
    DeviceStatus.delivered,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Rebuilds just to keep the search field's clear button in sync and to
    // propagate the search text down to each _MaintenanceTabPage — no
    // Firestore read is triggered by this, filtering happens client-side on
    // whatever page is already loaded (see _MaintenanceTabPage).
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onBrandSelected(String? brand) {
    setState(() {
      _selectedBrand = brand;
      _selectedEmployee = null;
      _selectedDateRange = null;
    });
  }

  void _onEmployeeSelected(String? employee) {
    setState(() {
      _selectedEmployee = employee;
      _selectedBrand = null;
      _selectedDateRange = null;
    });
  }

  Future<void> _onPickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _selectedDateRange,
    );
    if (picked == null) return;
    setState(() {
      _selectedDateRange = picked;
      _selectedBrand = null;
      _selectedEmployee = null;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedBrand = null;
      _selectedEmployee = null;
      _selectedDateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        if (homeState is HomeLoading) {
          return const Center(child: CircularProgressIndicator.adaptive());
        } else if (homeState is HomeLoaded) {
          final isEmployee = UserRole.isStaff(homeState.userData.type);
          _uid = homeState.userData.uid;
          _userData = homeState.userData;
          final services =
              context.read<MaintenanceListCubit>().maintenanceListServices;

          return Scaffold(
            backgroundColor: Colors.grey[50],
            floatingActionButton: isEmployee
                ? Padding(
                    // Respects the platform safe area (gesture bar / home
                    // indicator inset) instead of a fixed offset, so the FAB
                    // never sits flush against the bottom edge on devices
                    // with a larger inset — plus a comfortable margin on
                    // top, scaled for smaller screens.
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom +
                          (width < 450 ? 16 : 24),
                    ),
                    child: _buildFAB(context),
                  )
                : null,
            body: Column(
              children: [
                // Modern Tab Bar
                _buildTabBar(context),
                if (isEmployee) _buildSearchAndFilterBar(context),
                // Content — TabBarView keeps swipe navigation; each tab owns
                // its own bounded Firestore query and defers starting it
                // until it first becomes the active tab (see
                // _MaintenanceTabPage), so switching status never preloads
                // the other two tabs eagerly.
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      for (var i = 0; i < _tabStatuses.length; i++)
                        _MaintenanceTabPage(
                          key: ValueKey(_tabStatuses[i]),
                          status: _tabStatuses[i],
                          tabIndex: i,
                          tabController: _tabController,
                          uid: isEmployee ? null : _uid,
                          isEmployee: isEmployee,
                          brand: _selectedBrand,
                          maintenanceEmployee: _selectedEmployee,
                          receivedFrom: _selectedDateRange?.start,
                          receivedTo: _selectedDateRange?.end,
                          searchText: _searchController.text,
                          width: width,
                          services: services,
                          buildDeviceGrid: _buildDevicesList,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Center(child: Text('error_occurred'.tr()));
        }
      },
    );
  }

  /// Search box (client-side substring match on the currently loaded tab)
  /// plus mutually-exclusive structured filter controls (brand, employee,
  /// date range — status/tab is already the base filter). Staff only; see
  /// docs/ai-workflow/SEARCH_FILTER_IMPLEMENTATION_PLAN.md.
  Widget _buildSearchAndFilterBar(BuildContext context) {
    final hasActiveFilter = _selectedBrand != null ||
        _selectedEmployee != null ||
        _selectedDateRange != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, phone, model, or IMEI'.tr(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _searchController.clear,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: _selectedBrand ?? 'Brand'.tr(),
                  selected: _selectedBrand != null,
                  onTap: _showBrandPicker,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: _selectedEmployee ?? 'Employee'.tr(),
                  selected: _selectedEmployee != null,
                  onTap: _showEmployeePicker,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: _selectedDateRange == null
                      ? 'Date Range'.tr()
                      : '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}',
                  selected: _selectedDateRange != null,
                  onTap: _onPickDateRange,
                ),
                if (hasActiveFilter) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    label: Text('Clear'.tr()),
                    avatar: const Icon(Icons.close, size: 16),
                    onPressed: _clearFilters,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withAlpha(40),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _showBrandPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: AppConstants.deviceBrandList
            .map((brand) => ListTile(
                  title: Text(brand),
                  onTap: () {
                    Navigator.pop(context);
                    _onBrandSelected(brand);
                  },
                ))
            .toList(),
      ),
    );
  }

  void _showEmployeePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: AppConstants.maintenanceDialogEmployeeList
            .map((employee) => ListTile(
                  title: Text(employee),
                  onTap: () {
                    Navigator.pop(context);
                    _onEmployeeSelected(employee);
                  },
                ))
            .toList(),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final useScrollable =
        width < 450; // Use scrollable tabs for smaller screens
    final localeKey = context.locale.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        key: ValueKey('maintenance_tabbar_$localeKey'),
        controller: _tabController,
        isScrollable: useScrollable,
        tabAlignment: useScrollable ? TabAlignment.start : TabAlignment.fill,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[700],
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(6),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        tabs: [
          Tab(text: 'In Maintenance'.tr(context: context)),
          Tab(text: 'Fixed'.tr(context: context)),
          Tab(text: 'Delivered'.tr(context: context)),
        ],
      ),
    );
  }

  Widget _buildDevicesList(
    List<MaintenanceDeviceModel> devices,
    String status,
    bool isEmployee,
    double width, {
    required bool hasMore,
    required bool isLoadingMore,
    required VoidCallback onLoadMore,
    required int generation,
  }) {
    if (devices.isEmpty) {
      return EmptyStateWidget(getEmptyIcon: (_) => _getEmptyIcon(status));
    }

    final isWideScreen = width >= 900;
    final crossAxisCount = isWideScreen ? 2 : 1;

    // A single CustomScrollView (grid + a trailing Load More sliver) rather
    // than a GridView with the button pinned outside it — so Load More
    // scrolls as the natural last item of the list instead of staying fixed
    // at the bottom of the viewport. Keyed on `generation` (bumped only on
    // a genuine new query — tab/filter change — not on Load More's append)
    // rather than devices.length, so appending more devices updates this
    // same scrollable in place instead of remounting it and resetting
    // scroll position back to the top.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: CustomScrollView(
        key: ValueKey('${status}_${generation}_$crossAxisCount'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: isWideScreen ? 200 : 192,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 250 + (index * 40)),
                    tween: Tween(begin: 0, end: 1),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: DeviceCard(
                      device: devices[index],
                      status: status,
                      isEmployee: isEmployee,
                      onTap: () => _showDeviceDetails(devices[index], isEmployee),
                      getStatusColor: _getStatusColor,
                      getStatusIcon: _getStatusIcon,
                      buildSlidableActions: _buildSlidableActions,
                      heroTagPrefix: widget.heroTagPrefix,
                    ),
                  );
                },
                childCount: devices.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: hasMore
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Center(
                      child: isLoadingMore
                          ? const CircularProgressIndicator()
                          : OutlinedButton(
                              onPressed: onLoadMore,
                              child: Text('Load more'.tr()),
                            ),
                    ),
                  )
                : const SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  List<SlidableAction> _buildSlidableActions(
    MaintenanceDeviceModel device,
    String status,
  ) {
    switch (status.toLowerCase()) {
      case 'in maintenance':
        return [
          SlidableAction(
            onPressed: (_) {
              Navigator.pushNamed(
                context,
                AppRoutes.newDeviceMaintenance,
                arguments: {'device': device, 'userData': _userData},
              );
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit'.tr(),
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          SlidableAction(
            onPressed: (_) {
              _showMarkAsFixedDialog(device);
            },
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            icon: Icons.check_circle,
            label: 'Fixed'.tr(),
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          SlidableAction(
            onPressed: (_) {
              _showArchiveConfirmation(context, device);
            },
            backgroundColor: Colors.grey[700]!,
            foregroundColor: Colors.white,
            icon: Icons.archive_outlined,
            label: 'Archive'.tr(),
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        ];

      case 'fixed':
        return [
          SlidableAction(
            onPressed: (_) {
              Navigator.pushNamed(
                context,
                AppRoutes.newDeviceMaintenance,
                arguments: {'device': device, 'userData': _userData},
              );
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit'.tr(),
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          SlidableAction(
            onPressed: (_) {
              _showDeliverDeviceDialog(device);
            },
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            icon: Icons.delivery_dining,
            label: 'Deliver'.tr(),
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          SlidableAction(
            onPressed: (_) {
              _showArchiveConfirmation(context, device);
            },
            backgroundColor: Colors.grey[700]!,
            foregroundColor: Colors.white,
            icon: Icons.archive_outlined,
            label: 'Archive'.tr(),
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        ];

      case 'delivered':
        return [
          SlidableAction(
            onPressed: (_) {
              Navigator.pushNamed(
                context,
                AppRoutes.newDeviceMaintenance,
                arguments: {'device': device, 'userData': _userData},
              );
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit'.tr(),
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          SlidableAction(
            onPressed: (_) {
              // TODO: Show device details or invoice
              // _showDeviceInvoice(device);
            },
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            icon: Icons.receipt_long,
            label: 'Invoice'.tr(),
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          // SlidableAction(
          //   onPressed: (_) {
          //     // TODO: Reopen device (move back to In Maintenance)
          //     // maintenanceListCubit.updateDeviceStatus(device.id, 'In Maintenance');
          //   },
          //   backgroundColor: Colors.orange,
          //   foregroundColor: Colors.white,
          //   icon: Icons.replay,
          //   label: 'Reopen'.tr(),
          //   borderRadius: BorderRadius.circular(12),
          //   padding: const EdgeInsets.symmetric(horizontal: 4),
          // ),
          SlidableAction(
            onPressed: (_) {
              _showArchiveConfirmation(context, device);
            },
            backgroundColor: Colors.grey[700]!,
            foregroundColor: Colors.white,
            icon: Icons.archive_outlined,
            label: 'Archive'.tr(),
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
        ];

      default:
        return [];
    }
  }

  void _showMarkAsFixedDialog(MaintenanceDeviceModel device) {
    showDialog(
      context: context,
      builder: (_) => _MarkAsFixedDialog(
        title: 'Move to Fixed'.tr(),
        initialEmployee: device.maintenanceEmployee,
        initialPrice: device.price,
        initialInstalledPartCodes: device.installedPartCodes ?? const [],
        employeeOptions: AppConstants.maintenanceDialogEmployeeList,
        onSave: (employee, price, installedPartCodes) async {
          final maintenanceListCubit = context.read<MaintenanceListCubit>();
          await maintenanceListCubit.updateDeviceAsFixed(
            deviceId: device.id!,
            maintenanceEmployee: employee,
            price: price,
            installedPartCodes: installedPartCodes,
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Device moved to Fixed successfully'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showDeliverDeviceDialog(MaintenanceDeviceModel device) {
    showDialog(
      context: context,
      builder: (_) => _DeliverDeviceDialog(
        initialDeliveredBy: device.deliveredByEmployee,
        initialPrice: device.price,
        initialImagesAfterDelivery: device.imagesAfterDelivery ?? const [],
        employeeOptions: AppConstants.newDeviceEmployeeList,
        onDeliver: (deliveredBy, price, imagesAfterDelivery) async {
          final maintenanceListCubit = context.read<MaintenanceListCubit>();
          await maintenanceListCubit.deliverDevice(
            deviceId: device.id!,
            deliveredByEmployee: deliveredBy,
            price: price,
            imagesAfterDelivery: imagesAfterDelivery,
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Device delivered successfully'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showArchiveConfirmation(
    BuildContext context,
    MaintenanceDeviceModel device,
  ) {
    // Shows customer name/phone alongside the model so staff can visually
    // confirm they're archiving the intended record. Unlike the old hard
    // delete this replaces, archiving is fully reversible (an Admin can
    // restore it) and never touches images or sensitive data — see
    // docs/ai-workflow/ADR-005-device-lifecycle-archive-deletion.md.
    CustomDialogs.showDialogConfirm(
      context: context,
      title: 'Archive Device',
      content: 'This will remove the device from the normal lists. It can be '
          'restored later by an Admin.\n\n'
          'Customer: ${device.name} (${device.phoneNumber})\n'
          'Device: ${device.model}',
      icon: Icons.archive_outlined,
      iconColor: Colors.grey[700],
      confirmText: 'Archive',
      cancelText: 'Cancel',
      onPressed: () async {
        Navigator.of(context).pop();
        final maintenanceListCubit = context.read<MaintenanceListCubit>();
        final actingUid = _userData?.uid;
        if (actingUid == null) return;
        try {
          await maintenanceListCubit.archiveDevice(device.id!, actingUid);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Device archived successfully'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        } catch (_) {
          if (!mounted) return;
          Message.showBottomMessage(
            context,
            'Could not archive this device. Please try again.'.tr(),
            isError: true,
          );
        }
      },
    );
  }

  Widget _buildFAB(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).pushNamed(
            AppRoutes.newDeviceMaintenance,
            arguments: {'userData': _userData},
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Device'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showDeviceDetails(MaintenanceDeviceModel device, bool isEmployee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeviceDetailsSheet(
        device: device,
        isEmployee: isEmployee,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in maintenance':
        return Colors.orange;
      case 'fixed':
        return Colors.green;
      case 'delivered':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'in maintenance':
        return '🔧';
      case 'fixed':
        return '✅';
      case 'delivered':
        return '📦';
      default:
        return '📱';
    }
  }

  IconData _getEmptyIcon(String? status) {
    if (status == null) return Icons.devices_other;
    switch (status.toLowerCase()) {
      case 'in maintenance':
        return Icons.build_circle_outlined;
      case 'fixed':
        return Icons.check_circle_outline;
      case 'delivered':
        return Icons.delivery_dining;
      default:
        return Icons.devices_other;
    }
  }
}

/// One status tab's content. Owns its own bounded, live Firestore query
/// (status + at most one structured filter, top-N + Load More — see
/// docs/ai-workflow/SEARCH_FILTER_IMPLEMENTATION_PLAN.md) instead of relying
/// on a cubit-held per-tab cache. `AutomaticKeepAliveClientMixin` keeps this
/// widget (and its already-loaded devices) alive across swipes so revisiting
/// a tab is instant, while `_startListening` defers the first Firestore read
/// until this tab's index actually becomes the active one — so building all
/// three tabs up front (required by TabBarView) never means eagerly
/// subscribing to all three queries.
class _MaintenanceTabPage extends StatefulWidget {
  final String status;
  final int tabIndex;
  final TabController tabController;
  final String? uid;
  final bool isEmployee;
  final String? brand;
  final String? maintenanceEmployee;
  final DateTime? receivedFrom;
  final DateTime? receivedTo;
  final String searchText;
  final double width;
  final MaintenanceListServices services;
  final Widget Function(
    List<MaintenanceDeviceModel> devices,
    String status,
    bool isEmployee,
    double width, {
    required bool hasMore,
    required bool isLoadingMore,
    required VoidCallback onLoadMore,
    required int generation,
  }) buildDeviceGrid;

  const _MaintenanceTabPage({
    required super.key,
    required this.status,
    required this.tabIndex,
    required this.tabController,
    required this.uid,
    required this.isEmployee,
    required this.brand,
    required this.maintenanceEmployee,
    required this.receivedFrom,
    required this.receivedTo,
    required this.searchText,
    required this.width,
    required this.services,
    required this.buildDeviceGrid,
  });

  @override
  State<_MaintenanceTabPage> createState() => _MaintenanceTabPageState();
}

class _MaintenanceTabPageState extends State<_MaintenanceTabPage>
    with AutomaticKeepAliveClientMixin {
  static const int _pageSize = 50;

  StreamSubscription<DeviceTabPage>? _subscription;
  List<MaintenanceDeviceModel> _devices = [];
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  bool _hasStarted = false;
  bool _isLoading = true;
  String? _error;

  // Bumped only when a genuinely new query starts (_subscribe) — never on
  // _loadMore's append — so buildDeviceGrid's list key changes (and resets
  // scroll position) on a real filter/tab change, but Load More just
  // appends to the existing scrollable in place instead of remounting it
  // and jumping the user back to the top of the list.
  int _generation = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.tabController.index == widget.tabIndex) {
      _startListening();
    } else {
      widget.tabController.addListener(_onTabControllerChanged);
    }
  }

  void _onTabControllerChanged() {
    if (!_hasStarted && widget.tabController.index == widget.tabIndex) {
      _startListening();
    }
  }

  void _startListening() {
    if (_hasStarted) return;
    _hasStarted = true;
    widget.tabController.removeListener(_onTabControllerChanged);
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    setState(() {
      _isLoading = true;
      _error = null;
      _generation++;
    });
    _subscription = widget.services
        .streamDevicesForTab(
          status: widget.status,
          uid: widget.uid,
          brand: widget.brand,
          maintenanceEmployee: widget.maintenanceEmployee,
          receivedFrom: widget.receivedFrom,
          receivedTo: widget.receivedTo,
          limit: _pageSize,
        )
        .listen(
      (page) {
        if (!mounted) return;
        setState(() {
          _devices = page.devices;
          _lastDocument = page.lastDocument;
          _hasMore = page.devices.length >= _pageSize;
          _isLoading = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      },
    );
  }

  @override
  void didUpdateWidget(covariant _MaintenanceTabPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasStarted) return;
    final filtersChanged = widget.uid != oldWidget.uid ||
        widget.brand != oldWidget.brand ||
        widget.maintenanceEmployee != oldWidget.maintenanceEmployee ||
        widget.receivedFrom != oldWidget.receivedFrom ||
        widget.receivedTo != oldWidget.receivedTo;
    if (filtersChanged) {
      _subscribe();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final page = await widget.services.fetchMoreDevicesForTab(
        status: widget.status,
        startAfter: _lastDocument!,
        uid: widget.uid,
        brand: widget.brand,
        maintenanceEmployee: widget.maintenanceEmployee,
        receivedFrom: widget.receivedFrom,
        receivedTo: widget.receivedTo,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _devices = [..._devices, ...page.devices];
        _lastDocument = page.lastDocument ?? _lastDocument;
        _hasMore = page.devices.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  List<MaintenanceDeviceModel> get _visibleDevices {
    final query = widget.searchText.trim().toLowerCase();
    if (query.isEmpty) return _devices;
    return _devices.where((device) {
      return device.name.toLowerCase().contains(query) ||
          device.phoneNumber.toLowerCase().contains(query) ||
          device.model.toLowerCase().contains(query) ||
          (device.imeiNumber?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabControllerChanged);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    if (_isLoading && _devices.isEmpty) {
      return const LoadingStateWidget();
    }
    if (_error != null) {
      return ErrorStateWidget(message: _error!);
    }
    final visibleDevices = _visibleDevices;
    // Load More is rendered inside buildDeviceGrid itself now, as the last
    // scrollable item — no separate fixed-position button sibling needed.
    return widget.buildDeviceGrid(
      visibleDevices,
      widget.status,
      widget.isEmployee,
      widget.width,
      hasMore: _hasMore,
      isLoadingMore: _isLoadingMore,
      onLoadMore: _loadMore,
      generation: _generation,
    );
  }
}

class _MarkAsFixedDialog extends StatefulWidget {
  final String title;
  final String? initialEmployee;
  final double? initialPrice;
  final List<String> initialInstalledPartCodes;
  final List<String> employeeOptions;
  final Future<void> Function(
    String employee,
    double? price,
    List<String> installedPartCodes,
  ) onSave;

  const _MarkAsFixedDialog({
    required this.title,
    required this.initialEmployee,
    required this.initialPrice,
    required this.initialInstalledPartCodes,
    required this.employeeOptions,
    required this.onSave,
  });

  @override
  State<_MarkAsFixedDialog> createState() => _MarkAsFixedDialogState();
}

class _MarkAsFixedDialogState extends State<_MarkAsFixedDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late final TextEditingController _partCodeController;
  late final List<String> _employeeOptions;
  late final List<String> _installedPartCodes;
  String? _selectedEmployee;
  bool _isSaving = false;
  bool _showPartCodesError = false;

  @override
  void initState() {
    super.initState();
    _employeeOptions = List<String>.from(widget.employeeOptions);
    final initialEmployee = widget.initialEmployee?.trim();
    if (initialEmployee != null &&
        initialEmployee.isNotEmpty &&
        !_employeeOptions.contains(initialEmployee)) {
      _employeeOptions.add(initialEmployee);
    }
    _selectedEmployee = (initialEmployee != null && initialEmployee.isNotEmpty)
        ? initialEmployee
        : null;
    _priceController =
        TextEditingController(text: widget.initialPrice?.toString() ?? '');
    _partCodeController = TextEditingController();
    _installedPartCodes = List<String>.from(widget.initialInstalledPartCodes);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _partCodeController.dispose();
    super.dispose();
  }

  void _addPartCode() {
    final code = _partCodeController.text.trim();
    if (code.isEmpty) return;
    if (_installedPartCodes.contains(code)) {
      _partCodeController.clear();
      return;
    }
    setState(() {
      _installedPartCodes.add(code);
      _partCodeController.clear();
      _showPartCodesError = false;
    });
  }

  void _removePartCode(String code) {
    setState(() {
      _installedPartCodes.remove(code);
      if (_installedPartCodes.isNotEmpty) {
        _showPartCodesError = false;
      }
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    // If user typed a code but didn't press Add, add it automatically.
    if (_partCodeController.text.trim().isNotEmpty) {
      _addPartCode();
    }

    if (_installedPartCodes.isEmpty) {
      setState(() => _showPartCodesError = true);
      return;
    }

    final parsedPrice = _priceController.text.trim().isEmpty
        ? null
        : double.tryParse(_priceController.text.trim().replaceAll(',', '.'));

    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        _selectedEmployee!.trim(),
        parsedPrice,
        List<String>.from(_installedPartCodes),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: mediaQuery.size.height * 0.5,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedEmployee,
                  decoration: InputDecoration(
                    labelText: 'Maintenance Employee'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  items: _employeeOptions
                      .map(
                        (employee) => DropdownMenuItem<String>(
                          value: employee,
                          child: Text(employee),
                        ),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          setState(() => _selectedEmployee = value);
                        },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please select maintenance employee'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Price'.tr(),
                    hintText: 'Optional'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    final parsed = double.tryParse(text.replaceAll(',', '.'));
                    if (parsed == null) {
                      return 'Please enter a valid number'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _partCodeController,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _addPartCode(),
                        decoration: InputDecoration(
                          labelText: 'Part Code'.tr(),
                          hintText: 'Enter part code'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _addPartCode,
                        child: Text('Add'.tr()),
                      ),
                    ),
                  ],
                ),
                if (_showPartCodesError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Please add at least one part code'.tr(),
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                if (_installedPartCodes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Installed Part Codes'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _installedPartCodes
                        .map(
                          (code) => Chip(
                            label: Text(code),
                            onDeleted:
                                _isSaving ? null : () => _removePartCode(code),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Save'.tr()),
        ),
      ],
    );
  }
}

class _DeliverDeviceDialog extends StatefulWidget {
  final String? initialDeliveredBy;
  final double? initialPrice;
  final List<String> initialImagesAfterDelivery;
  final List<String> employeeOptions;
  final Future<void> Function(
    String deliveredBy,
    double price,
    List<String> imagesAfterDelivery,
  ) onDeliver;

  const _DeliverDeviceDialog({
    required this.initialDeliveredBy,
    required this.initialPrice,
    required this.initialImagesAfterDelivery,
    required this.employeeOptions,
    required this.onDeliver,
  });

  @override
  State<_DeliverDeviceDialog> createState() => _DeliverDeviceDialogState();
}

class _DeliverDeviceDialogState extends State<_DeliverDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late final List<String> _employeeOptions;
  late final List<String> _imagesAfterDelivery;
  String? _selectedDeliveredBy;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _employeeOptions = List<String>.from(widget.employeeOptions);
    final initialDeliveredBy = widget.initialDeliveredBy?.trim();
    if (initialDeliveredBy != null &&
        initialDeliveredBy.isNotEmpty &&
        !_employeeOptions.contains(initialDeliveredBy)) {
      _employeeOptions.add(initialDeliveredBy);
    }
    _selectedDeliveredBy =
        (initialDeliveredBy != null && initialDeliveredBy.isNotEmpty)
            ? initialDeliveredBy
            : null;
    _priceController =
        TextEditingController(text: widget.initialPrice?.toString() ?? '');
    _imagesAfterDelivery = List<String>.from(widget.initialImagesAfterDelivery);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('Select Image Source'.tr()),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: Text('Camera'.tr()),
                  onTap: () => Navigator.pop(dialogContext, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primary,
                  ),
                  title: Text('Gallery'.tr()),
                  onTap: () =>
                      Navigator.pop(dialogContext, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      await Future.delayed(const Duration(milliseconds: 100));

      final image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image == null || !mounted) return;

      setState(() {
        _imagesAfterDelivery.add(image.path);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image added successfully'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${'Failed to add image'.tr()}: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final parsedPrice =
        double.parse(_priceController.text.trim().replaceAll(',', '.'));

    setState(() => _isSaving = true);
    try {
      await widget.onDeliver(
        _selectedDeliveredBy!.trim(),
        parsedPrice,
        List<String>.from(_imagesAfterDelivery),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final dialogWidth =
        mediaQuery.size.width > 480 ? 420.0 : mediaQuery.size.width - 32;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        width: dialogWidth,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Deliver Device'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDeliveredBy,
                          decoration: InputDecoration(
                            labelText: 'Delivered By'.tr(),
                            border: const OutlineInputBorder(),
                          ),
                          items: _employeeOptions
                              .map(
                                (employee) => DropdownMenuItem<String>(
                                  value: employee,
                                  child: Text(employee),
                                ),
                              )
                              .toList(),
                          onChanged: _isSaving
                              ? null
                              : (value) {
                                  setState(() => _selectedDeliveredBy = value);
                                },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please select delivered by employee'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Price'.tr(),
                            hintText: 'Required'.tr(),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Price is required'.tr();
                            }
                            final parsed =
                                double.tryParse(text.replaceAll(',', '.'));
                            if (parsed == null) {
                              return 'Please enter a valid number'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Images After Delivery'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        IgnorePointer(
                          ignoring: _isSaving,
                          child: Opacity(
                            opacity: _isSaving ? 0.7 : 1,
                            child: ImageSectionWidget(
                              images: _imagesAfterDelivery,
                              onAdd: _pickImage,
                              onRemove: (index) {
                                setState(() {
                                  _imagesAfterDelivery.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isSaving ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancel'.tr()),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Deliver'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
