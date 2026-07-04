import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';
import 'package:techno_store/core/route/app_routes.dart';
import 'package:techno_store/core/utils/app_colors.dart';
import 'package:techno_store/core/utils/app_constants.dart';
import 'package:techno_store/core/utils/user_role.dart';
import 'package:techno_store/core/widgets/custom_dialogs.dart';
import 'package:techno_store/features/home_page/cubit/home_cubit.dart';
import 'package:techno_store/features/maintenance_list/cubit/maintenance_list_cubit.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        if (homeState is HomeLoading) {
          return const Center(child: CircularProgressIndicator.adaptive());
        } else if (homeState is HomeLoaded) {
          final isEmployee = UserRole.isStaff(homeState.userData.type);

          return Scaffold(
            backgroundColor: Colors.grey[50],
            floatingActionButton: isEmployee
                ? Transform.translate(
                    offset: Offset(
                      0,
                      width < 450 ? 25 : 5,
                    ), // Shift up on small screens
                    child: _buildFAB(context),
                  )
                : null,
            body: Column(
              children: [
                // Modern Tab Bar
                _buildTabBar(context),
                // Content
                Expanded(
                  child:
                      BlocBuilder<MaintenanceListCubit, MaintenanceListState>(
                    builder: (context, state) {
                      if (state is MaintenanceListLoading) {
                        return const LoadingStateWidget();
                      } else if (state is MaintenanceListLoaded) {
                        return TabBarView(
                          controller: _tabController,
                          children: [
                            _buildDevicesList(
                              state.groupedDevices.inMaintenance,
                              'In Maintenance',
                              isEmployee,
                              width,
                            ),
                            _buildDevicesList(
                              state.groupedDevices.fixed,
                              'Fixed',
                              isEmployee,
                              width,
                            ),
                            _buildDevicesList(
                              state.groupedDevices.delivered,
                              'Delivered',
                              isEmployee,
                              width,
                            ),
                          ],
                        );
                      } else if (state is MaintenanceListError) {
                        return ErrorStateWidget(message: state.error);
                      }
                      return EmptyStateWidget(getEmptyIcon: _getEmptyIcon);
                    },
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
    double width,
  ) {
    if (devices.isEmpty) {
      return EmptyStateWidget(getEmptyIcon: (_) => _getEmptyIcon(status));
    }

    final isWideScreen = width >= 900;
    final crossAxisCount = isWideScreen ? 2 : 1;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: GridView.builder(
        key: ValueKey('${status}_${devices.length}_$crossAxisCount'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: isWideScreen ? 215 : 200,
        ),
        itemCount: devices.length,
        itemBuilder: (context, index) {
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
                arguments: {'device': device},
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
              _showDeleteConfirmation(context, device);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete'.tr(),
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
                arguments: {'device': device},
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
              _showDeleteConfirmation(context, device);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete'.tr(),
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
                arguments: {'device': device},
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
              _showDeleteConfirmation(context, device);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete'.tr(),
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

  void _showDeleteConfirmation(
    BuildContext context,
    MaintenanceDeviceModel device,
  ) {
    CustomDialogs.showDialogConfirm(
      context: context,
      title: 'Delete Device',
      content:
          'Are you sure you want to delete ${device.model}? This action cannot be undone.',
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.red,
      confirmText: 'Delete',
      cancelText: 'Cancel',
      onPressed: () async {
        Navigator.of(context).pop();
        final maintenanceListCubit = context.read<MaintenanceListCubit>();
        await maintenanceListCubit.deleteDevice(device.id!);
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
