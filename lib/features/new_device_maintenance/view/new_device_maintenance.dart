import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:techno_store/core/utils/app_colors.dart';
import 'package:techno_store/core/utils/app_constants.dart';
import 'package:techno_store/core/widgets/custom_dialogs.dart';
import 'package:techno_store/core/widgets/main_app_bar.dart';
import 'package:techno_store/core/widgets/message.dart';
import 'package:techno_store/features/new_device_maintenance/cubit/new_device_cubit.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';
import 'package:techno_store/core/model/maintenance_device_sensitive_data.dart';
import 'package:techno_store/core/services/maintenance_device_sensitive_data_service.dart';
import 'package:techno_store/features/new_device_maintenance/widgets/accessories_section_widget.dart';
import 'package:techno_store/features/new_device_maintenance/widgets/action_buttons_widget.dart';
import 'package:techno_store/features/new_device_maintenance/widgets/build_dropdown.dart';
import 'package:techno_store/features/new_device_maintenance/widgets/build_selection_card.dart';
import 'package:techno_store/features/new_device_maintenance/widgets/build_text_field.dart';
import 'package:techno_store/features/new_device_maintenance/widgets/color_picker_widget.dart';
import 'package:techno_store/features/new_device_maintenance/widgets/image_section_widget.dart';
import 'package:techno_store/features/new_device_maintenance/widgets/pattern_button_widget.dart';
import 'package:techno_store/features/new_device_maintenance/widgets/pattern_dialog_widget.dart';
import 'package:techno_store/features/new_device_maintenance/widgets/pre_check_section_widget.dart';
import 'package:techno_store/features/new_device_maintenance/widgets/problems_section_widget.dart';

class NewDeviceMaintenance extends StatefulWidget {
  final MaintenanceDeviceModel? device;

  const NewDeviceMaintenance({Key? key, this.device}) : super(key: key);

  @override
  State<NewDeviceMaintenance> createState() => _NewDeviceMaintenanceState();
}

class _NewDeviceMaintenanceState extends State<NewDeviceMaintenance> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final phoneController = TextEditingController();
  final nameController = TextEditingController();
  final modelController = TextEditingController();
  final imeiController = TextEditingController();
  final pinController = TextEditingController();
  final notesController = TextEditingController();
  final priceController = TextEditingController();
  final notes2Controller = TextEditingController();
  final receivedByEmployeeController = TextEditingController();
  final maintenanceEmployeeController = TextEditingController();
  final partCodeController = TextEditingController();
  final _advancedDrawerController = AdvancedDrawerController();

  // State variables
  Color selectedColor = const Color(0xff000000);
  String? selectedBrand;
  String? selectedTime;

  List<bool> problems =
      List.filled(AppConstants.maintenanceProblemList.length, false);
  List<bool> accessories =
      List.filled(AppConstants.maintenanceAccessoryList.length, false);
  List<bool> preCheckList =
      List.filled(AppConstants.maintenancePreCheckList.length, false);

  // Pattern lock variables
  List<int> patternValue = [];

  // Images
  List<String> imagesBeforeReceiving = [];
  List<String> installedPartCodes = [];

  // pin/patternLock/notesHidden are no longer part of MaintenanceDeviceModel
  // (see docs/ai-workflow/ADR-001-sensitive-data-separation.md) — for an
  // existing device they're fetched asynchronously in initState. Saving is
  // blocked until this completes, so we never submit a still-empty
  // pin/pattern that would silently overwrite a device's real values with
  // nothing (production data safety — see
  // docs/ai-workflow/PHASE1_IMPLEMENTATION_PLAN.md).
  bool _sensitiveDataLoaded = true;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    modelController.dispose();
    imeiController.dispose();
    pinController.dispose();
    notesController.dispose();
    priceController.dispose();
    notes2Controller.dispose();
    receivedByEmployeeController.dispose();
    maintenanceEmployeeController.dispose();
    partCodeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.device != null) {
      final device = widget.device!;
      nameController.text = device.name;
      phoneController.text = _toEditablePhone(device.phoneNumber);
      receivedByEmployeeController.text = device.receivedByEmployee;
      selectedBrand = device.brand;
      modelController.text = device.model;
      selectedColor = Color(int.parse(device.colorHex, radix: 16));
      imeiController.text = device.imeiNumber ?? '';
      imagesBeforeReceiving = device.imagesBeforeReceiving ?? [];
      for (int i = 0; i < AppConstants.maintenanceProblemList.length; i++) {
        problems[i] =
            device.problems.contains(AppConstants.maintenanceProblemList[i]);
      }
      for (int i = 0; i < AppConstants.maintenanceAccessoryList.length; i++) {
        accessories[i] = device.accessories
            .contains(AppConstants.maintenanceAccessoryList[i]);
      }
      for (int i = 0; i < AppConstants.maintenancePreCheckList.length; i++) {
        preCheckList[i] = device.deviceStatusReceived
            .contains(AppConstants.maintenancePreCheckList[i]);
      }
      priceController.text =
          device.price != null ? device.price.toString() : '';
      maintenanceEmployeeController.text = device.maintenanceEmployee ?? '';
      installedPartCodes = List<String>.from(device.installedPartCodes ?? []);
      selectedTime = device.estimatedTime;
      notes2Controller.text = device.additionalNotes ?? '';

      _sensitiveDataLoaded = false;
      _loadSensitiveData(device.id!);
    }
  }

  Future<void> _loadSensitiveData(String deviceId) async {
    try {
      final sensitiveData = await MaintenanceDeviceSensitiveDataService
          .instance
          .fetch(deviceId);
      if (!mounted) return;
      setState(() {
        pinController.text = sensitiveData?.pin ?? '';
        patternValue = sensitiveData?.patternLock ?? [];
        notesController.text = sensitiveData?.notesHidden ?? '';
        _sensitiveDataLoaded = true;
      });
    } catch (e) {
      debugPrint('❌ Error loading sensitive data: $e');
      if (!mounted) return;
      // _sensitiveDataLoaded stays false — Save remains blocked (correct,
      // we still don't know the device's real PIN/pattern), but the user
      // now sees why instead of an unexplained permanent "please wait".
      Message.showErrorToastMessage(
          "Failed to load device security data. Reopen this screen to retry."
              .tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final newDeviceMaintenanceCubit = BlocProvider.of<NewDeviceCubit>(context);

    return BlocConsumer<NewDeviceCubit, NewDeviceState>(
      listenWhen: (previous, current) =>
          current is NewDeviceSuccess || current is NewDeviceError,
      listener: (context, state) {
        if (state is NewDeviceSuccess) {
          Message.showSuccessToastMessage("Device added successfully".tr());
          Navigator.pop(context, true); // Return true to indicate success
        } else if (state is NewDeviceError) {
          Message.showBottomMessage(context, state.error, isError: true);
        }
      },
      buildWhen: (previous, current) =>
          current is! NewDeviceSuccess && current is! NewDeviceError,
      builder: (context, state) {
        if (state is NewDeviceLoading) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: PreferredSize(
              preferredSize:
                  Size.fromHeight(width <= 500 ? height * 0.05 : height * 0.08),
              child: MainAppBar(
                haveLeading: false,
                advancedDrawerController: _advancedDrawerController,
                title: 'Device Maintenance'.tr(),
                onLanguageChanged: () => setState(() {}),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
          );
        }
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: PreferredSize(
            preferredSize:
                Size.fromHeight(width <= 500 ? height * 0.05 : height * 0.08),
            child: MainAppBar(
              haveLeading: false,
              advancedDrawerController: _advancedDrawerController,
              title: 'Device Maintenance'.tr(),
              onLanguageChanged: () => setState(() {}),
            ),
          ),
          body: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width > 1200 ? width * 0.1 : width * 0.05,
                  vertical: 20,
                ),
                child: Form(
                  key: _formKey,
                  child: (width >= 1024)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Row 1: Customer & Device Information
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Customer Information Section
                                Expanded(
                                  child: customerInformation(),
                                ),
                                const SizedBox(width: 24),

                                // Device Information Section
                                Expanded(
                                  child: deviceInformation(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Device Images Before Receiving
                            deviceImagesBeforeReceiving(),

                            const SizedBox(height: 24),

                            // Row 2: Maintenance Information (Full Width)
                            maintenanceInformation(),

                            const SizedBox(height: 24),

                            // Row 3: Pricing & Timeline
                            pricingAndTimeline(),

                            if (widget.device != null &&
                                widget.device!.status == 'Fixed') ...[
                              const SizedBox(height: 24),
                              fixedDetailsSection(),
                            ],

                            const SizedBox(height: 32),

                            // Action Buttons
                            Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 600),
                                child: actionButtons(newDeviceMaintenanceCubit),
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Customer Information Section
                            customerInformation(),
                            const SizedBox(height: 24),
                            // Device Information Section
                            deviceInformation(),
                            const SizedBox(height: 24),

                            // Device Images Before Receiving
                            deviceImagesBeforeReceiving(),
                            const SizedBox(height: 24),

                            // Maintenance Information Section
                            maintenanceInformation(),
                            const SizedBox(height: 24),

                            // Price and Time Section
                            pricingAndTimeline(),

                            if (widget.device != null &&
                                widget.device!.status == 'Fixed') ...[
                              const SizedBox(height: 24),
                              fixedDetailsSection(),
                            ],

                            const SizedBox(height: 32),

                            // Action Buttons
                            actionButtons(newDeviceMaintenanceCubit),
                            const SizedBox(height: 24),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget customerInformation() {
    return BuildSelectionCard(
      title: "Customer Information".tr(),
      icon: Icons.person_outline_rounded,
      children: [
        // SignInFormPhoneInput(
        //   phoneController: phoneController,
        //   phoneCode: phoneCode,
        // ),
        BuildTextField(
          controller: phoneController,
          label: "Phone Number".tr(),
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          required: true,
        ),
        const SizedBox(height: 16),
        BuildTextField(
          controller: nameController,
          label: "Name".tr(),
          icon: Icons.person,
          required: true,
        ),
        const SizedBox(height: 16),
        BuildDropdown(
          value: receivedByEmployeeController.text.isEmpty
              ? null
              : receivedByEmployeeController.text,
          label: "Received By Employee".tr(),
          icon: Icons.person_outline,
          items: AppConstants.newDeviceEmployeeList,
          onChanged: (value) => setState(() {
            receivedByEmployeeController.text = value ?? '';
          }),
        ),
      ],
    );
  }

  Widget deviceInformation() {
    return BuildSelectionCard(
      title: "Device Information".tr(),
      icon: Icons.smartphone_rounded,
      children: [
        BuildDropdown(
          value: selectedBrand,
          label: "Device Brand".tr(),
          icon: Icons.business,
          items: AppConstants.deviceBrandList,
          onChanged: (value) => setState(() => selectedBrand = value),
        ),
        const SizedBox(height: 16),
        BuildTextField(
          controller: modelController,
          label: "Device Model".tr(),
          icon: Icons.phone_iphone,
          required: true,
        ),
        const SizedBox(height: 16),
        ColorPickerWidget(
          selectedColor: selectedColor,
          onColorChanged: (color) => setState(() => selectedColor = color),
          predefinedColors: AppConstants.maintenancePredefinedColors,
        ),
        const SizedBox(height: 16),
        BuildTextField(
          controller: imeiController,
          label: "IMEI Number".tr(),
          icon: Icons.fingerprint,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: BuildTextField(
                controller: pinController,
                label: "PIN".tr(),
                icon: Icons.lock_outline,
                obscureText: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PatternButtonWidget(
                onTap: () => _showPatternDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget deviceImagesBeforeReceiving() {
    return BuildSelectionCard(
      title: "Device Images Before Receiving".tr(),
      icon: Icons.camera_alt_rounded,
      children: [
        ImageSectionWidget(
          images: imagesBeforeReceiving,
          onAdd: () => _pickImage(isBeforeReceiving: true),
          onRemove: (index) {
            setState(() => imagesBeforeReceiving.removeAt(index));
          },
        ),
      ],
    );
  }

  Widget maintenanceInformation() {
    final width = MediaQuery.of(context).size.width;
    return BuildSelectionCard(
      title: "Maintenance Information".tr(),
      icon: Icons.build_rounded,
      children: [
        ProblemsSectionWidget(
          problems: problems,
          onProblemToggled: (index) {
            setState(() => problems[index] = !problems[index]);
          },
        ),
        const SizedBox(height: 16),
        (width < 1024)
            ? Column(
                children: [
                  AccessoriesSectionWidget(
                    accessories: accessories,
                    onAccessoryToggled: (index) {
                      setState(() => accessories[index] = !accessories[index]);
                    },
                  ),
                  const SizedBox(height: 16),
                  PreCheckSectionWidget(
                    preCheckList: preCheckList,
                    onCheckToggled: (index) {
                      setState(
                          () => preCheckList[index] = !preCheckList[index]);
                    },
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AccessoriesSectionWidget(
                      accessories: accessories,
                      onAccessoryToggled: (index) {
                        setState(
                            () => accessories[index] = !accessories[index]);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PreCheckSectionWidget(
                      preCheckList: preCheckList,
                      onCheckToggled: (index) {
                        setState(
                            () => preCheckList[index] = !preCheckList[index]);
                      },
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 16),
        BuildTextField(
          controller: notesController,
          label: "Notes (Hidden)".tr(),
          icon: Icons.notes,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget pricingAndTimeline() {
    final width = MediaQuery.of(context).size.width;
    return BuildSelectionCard(
      title: "Pricing & Timeline".tr(),
      icon: Icons.attach_money_rounded,
      children: [
        (width < 1024)
            ? Column(
                children: [
                  BuildTextField(
                    controller: priceController,
                    label: "Price".tr(),
                    icon: Icons.payments,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  BuildDropdown(
                    value: selectedTime,
                    label: "Estimated Time".tr(),
                    icon: Icons.access_time,
                    items: AppConstants.estimatedTimeList,
                    onChanged: (value) => setState(() => selectedTime = value),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: BuildTextField(
                      controller: priceController,
                      label: "Price".tr(),
                      icon: Icons.payments,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BuildDropdown(
                      value: selectedTime,
                      label: "Estimated Time".tr(),
                      icon: Icons.access_time,
                      items: AppConstants.estimatedTimeList,
                      onChanged: (value) =>
                          setState(() => selectedTime = value),
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 16),
        BuildTextField(
          controller: notes2Controller,
          label: "Additional Notes".tr(),
          icon: Icons.note_alt_outlined,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget fixedDetailsSection() {
    return BuildSelectionCard(
      title: 'Fixed Details'.tr(),
      icon: Icons.build_circle,
      children: [
        BuildDropdown(
          value: maintenanceEmployeeController.text.isEmpty
              ? null
              : maintenanceEmployeeController.text,
          label: 'Maintenance Employee'.tr(),
          icon: Icons.engineering,
          items: AppConstants.maintenanceDialogEmployeeList,
          onChanged: (value) {
            setState(() {
              maintenanceEmployeeController.text = value ?? '';
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: BuildTextField(
                controller: partCodeController,
                label: 'Part Code'.tr(),
                icon: Icons.qr_code,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _addPartCode,
                child: Text('Add'.tr()),
              ),
            ),
          ],
        ),
        if (installedPartCodes.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: installedPartCodes
                .map(
                  (code) => Chip(
                    label: Text(code),
                    onDeleted: () {
                      setState(() {
                        installedPartCodes.remove(code);
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  void _addPartCode() {
    final code = partCodeController.text.trim();
    if (code.isEmpty) return;
    if (installedPartCodes.contains(code)) {
      partCodeController.clear();
      return;
    }
    setState(() {
      installedPartCodes.add(code);
      partCodeController.clear();
    });
  }

  Widget actionButtons(NewDeviceCubit newDeviceMaintenanceCubit) {
    return ActionButtonsWidget(
      onConfirm: () async {
        if (!_sensitiveDataLoaded) {
          // Guard against submitting a still-empty pin/pattern before the
          // fetch in _loadSensitiveData completes, which would otherwise
          // silently wipe the device's existing PIN/pattern lock.
          Message.showErrorToastMessage(
              "Please wait, loading device data...".tr());
          return;
        }
        if (_formKey.currentState!.validate()) {
          CustomDialogs.showDialogConfirm(
            context: context,
            title: "Confirm Save".tr(),
            content: "Are you sure you want to save this device?".tr(),
            onPressed: () async {
              Navigator.pop(context);
              final result = await onSaveLogic();
              if (result == null) return;
              final (device, sensitiveData) = result;
              if (widget.device == null) {
                await newDeviceMaintenanceCubit.addNewDevice(
                  device,
                  sensitiveData: sensitiveData,
                );
              } else {
                await newDeviceMaintenanceCubit.updateDevice(
                  widget.device!.id!,
                  device,
                  sensitiveData: sensitiveData,
                );
              }
            },
          );
        }
      },
      onCancel: () => Navigator.pop(context),
    );
  }

  Future<(MaintenanceDeviceModel, MaintenanceDeviceSensitiveData)?>
      onSaveLogic() async {
    final normalizedPhoneNumber = _normalizePhoneNumber(phoneController.text);
    if (normalizedPhoneNumber == null) {
      Message.showErrorToastMessage("Please enter valid phone number".tr());
      return null;
    }

    // Validate received by employee (always required)
    if (receivedByEmployeeController.text.trim().isEmpty) {
      Message.showErrorToastMessage("Please select received by employee".tr());

      return null;
    }

    MaintenanceDeviceModel device = MaintenanceDeviceModel(
      name: nameController.text.trim(),
      phoneNumber: normalizedPhoneNumber,
      model: modelController.text.trim(),
      brand: selectedBrand,
      colorHex: selectedColor.value.toRadixString(16),
      problems: [
        for (int i = 0; i < problems.length; i++)
          if (problems[i]) AppConstants.maintenanceProblemList[i]
      ],
      accessories: [
        for (int i = 0; i < accessories.length; i++)
          if (accessories[i]) AppConstants.maintenanceAccessoryList[i]
      ],
      deviceStatusReceived: [
        for (int i = 0; i < preCheckList.length; i++)
          if (preCheckList[i]) AppConstants.maintenancePreCheckList[i]
      ],
      receivedAt:
          widget.device == null ? DateTime.now() : widget.device!.receivedAt,
      updatedAt: DateTime.now(),
      imeiNumber: imeiController.text.trim(),
      price: priceController.text.isNotEmpty
          ? double.tryParse(priceController.text.trim())
          : null,
      estimatedTime: selectedTime,
      additionalNotes: notes2Controller.text.trim(),
      imagesBeforeReceiving: imagesBeforeReceiving,
      receivedByEmployee: receivedByEmployeeController.text.trim(),
      maintenanceEmployee: maintenanceEmployeeController.text.trim().isEmpty
          ? widget.device?.maintenanceEmployee
          : maintenanceEmployeeController.text.trim(),
      installedPartCodes: List<String>.from(installedPartCodes),
      deliveredByEmployee: widget.device?.deliveredByEmployee,
      deliveredAt: widget.device?.deliveredAt,
      fixedAt: widget.device?.fixedAt,
      timeToFix: widget.device?.timeToFix,
      status: widget.device?.status ?? 'In Maintenance',
      // Explicit rather than relying on the model's default — this screen
      // is never reachable for an archived device (archived records are
      // excluded from every tab), so widget.device is always active/absent
      // in practice, but this makes that assumption visible rather than
      // implicit. See ADR-005.
      recordState: widget.device?.recordState ?? 'active',
    );

    final sensitiveData = MaintenanceDeviceSensitiveData(
      pin: pinController.text.trim(),
      patternLock: patternValue,
      notesHidden: notesController.text.trim(),
    );

    return (device, sensitiveData);
  }

  String? _normalizePhoneNumber(String phone) {
    final input = phone.trim();
    if (input.isEmpty) return null;

    final compact = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (compact.startsWith('+')) {
      final remaining = compact.substring(1);
      if (remaining.isEmpty || !RegExp(r'^\d+$').hasMatch(remaining)) {
        return null;
      }
      return '+$remaining';
    }

    if (!RegExp(r'^\d+$').hasMatch(compact)) {
      return null;
    }

    if (compact.startsWith('970')) {
      return '+$compact';
    }

    if (compact.startsWith('0')) {
      return '+970${compact.substring(1)}';
    }

    return '+970$compact';
  }

  String _toEditablePhone(String phoneNumber) {
    final compact = phoneNumber.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (compact.startsWith('+970')) {
      final localPart = compact.substring(4);
      if (localPart.isEmpty) return '';
      return localPart.startsWith('0') ? localPart : '0$localPart';
    }

    if (compact.startsWith('970')) {
      final localPart = compact.substring(3);
      if (localPart.isEmpty) return '';
      return localPart.startsWith('0') ? localPart : '0$localPart';
    }

    return compact;
  }

  void _showPatternDialog() {
    showDialog(
      context: context,
      builder: (context) => PatternDialogWidget(
        initialPattern: patternValue,
        onPatternSaved: (pattern) {
          setState(() {
            patternValue = pattern;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Pattern saved successfully".tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickImage({required bool isBeforeReceiving}) async {
    try {
      final ImagePicker picker = ImagePicker();

      // Show options: Camera or Gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Select Image Source".tr()),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: Text("Camera".tr()),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.photo_library, color: AppColors.primary),
                  title: Text("Gallery".tr()),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      // Add a small delay to ensure dialog is closed
      await Future.delayed(const Duration(milliseconds: 100));

      final XFile? image = await picker
          .pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
        preferredCameraDevice: CameraDevice.rear,
      )
          .catchError((error) {
        debugPrint('Error picking image: $error');
        return null;
      });

      if (image != null) {
        setState(() {
          imagesBeforeReceiving.add(image.path);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Image added successfully".tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in _pickImage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${"Failed to add image".tr()}: ${e.toString()}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
