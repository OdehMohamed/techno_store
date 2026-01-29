import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/core2/widgets/custom_dialogs.dart';
import 'package:techno_store/core2/widgets/main_app_bar.dart';
import 'package:techno_store/core2/widgets/message.dart';
import 'package:techno_store/features/new_device_maintenance/cubit/new_device_cubit.dart';
import 'package:techno_store/features/new_device_maintenance/model/new_device_maintenance_model.dart';
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
  const NewDeviceMaintenance({Key? key}) : super(key: key);

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
  final _advancedDrawerController = AdvancedDrawerController();

  // State variables
  Color selectedColor = const Color(0xff000000);
  String? selectedBrand;
  String? selectedTime;

  List<bool> problems = List.filled(19, false);
  List<bool> accessories = List.filled(9, false);
  List<bool> preCheckList = List.filled(5, false);

  // Pattern lock variables
  List<int> patternValue = [];

  // Images
  List<String> imagesBeforeReceiving = [];

  final List<Color> predefinedColors = [
    const Color(0xff000000),
    const Color(0xffffd700),
    const Color(0xffc0c0c0),
    const Color(0xff9c27b0),
    const Color(0xffffffff),
    const Color(0xff2196f3),
    const Color(0xff000080),
    const Color(0xfff44336),
    const Color(0xff4caf50),
  ];
  final problemList = [
    "Not Working",
    "Screen",
    "Battery",
    "Charging Base",
    "Service",
    "Check",
    "Selfie Camera",
    "Main Camera",
    "Internal Headset",
    "External Headset",
    "Microphone",
    "Touch Screen",
    "Fingerprint",
    "Device Back",
    "Software",
    "Open Gmail",
    "Open iCloud",
    "Volume Button",
    "Power Button",
  ];
  final accessoryList = [
    "Charger",
    "Headphones",
    "Case",
    "Screen Protector",
    "SIM 1",
    "SIM 2",
    "Memory Card",
    "Cable",
    "Other",
  ];
  final checkList = [
    "Scratches",
    "Cracks",
    "Liquid Damage",
    "Missing Parts",
    "Others",
  ];

  final employeeList = [
    "أحمد",
    "خالد",
    "عمر",
    "سامي",
    "فادي",
  ];
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
    super.dispose();
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
          Navigator.pop(context);
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
          items: employeeList,
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
          items: const ['Apple', 'Samsung', 'Huawei', 'Xiaomi', 'Others'],
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
          predefinedColors: predefinedColors,
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
                    items: const [
                      '30 min',
                      '1 Hour',
                      '2 Hours',
                      '3 Hours',
                      '4 Hours',
                      '5 Hours',
                      'Not determined'
                    ],
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
                      items: const [
                        '30 min',
                        '1 Hour',
                        '2 Hours',
                        '3 Hours',
                        '4 Hours',
                        '5 Hours',
                        'Not determined'
                      ],
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

  Widget actionButtons(NewDeviceCubit newDeviceMaintenanceCubit) {
    return ActionButtonsWidget(
      onSave: () async {
        if (_formKey.currentState!.validate()) {
          CustomDialogs.showDialogConfirm(
            context: context,
            title: "Confirm Save".tr(),
            content: "Are you sure you want to save this device?".tr(),
            onPressed: () async {
              Navigator.pop(context);
              final device = await onSaveLogic();
              if (device != null) {
                await newDeviceMaintenanceCubit.addNewDevice(device);
              }
            },
          );
        }
      },
      onCancel: () => Navigator.pop(context),
    );
  }

  Future<NewDeviceMaintenanceModel?> onSaveLogic() async {
    // Validate received by employee (always required)
    if (receivedByEmployeeController.text.trim().isEmpty) {
      Message.showErrorToastMessage("Please select received by employee".tr());

      return null;
    }

    NewDeviceMaintenanceModel device = NewDeviceMaintenanceModel(
      name: nameController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      model: modelController.text.trim(),
      brand: selectedBrand,
      colorHex: selectedColor.value.toRadixString(16),
      problems: [
        for (int i = 0; i < problems.length; i++)
          if (problems[i]) problemList[i]
      ],
      accessories: [
        for (int i = 0; i < accessories.length; i++)
          if (accessories[i]) accessoryList[i]
      ],
      deviceStatusReceived: [
        for (int i = 0; i < preCheckList.length; i++)
          if (preCheckList[i]) checkList[i]
      ],
      receivedAt: DateTime.now(),
      pin: pinController.text.trim(),
      imeiNumber: imeiController.text.trim(),
      notesHidden: notesController.text.trim(),
      price: priceController.text.isNotEmpty
          ? double.tryParse(priceController.text.trim())
          : null,
      estimatedTime: selectedTime,
      additionalNotes: notes2Controller.text.trim(),
      patternLock: patternValue,
      imagesBeforeReceiving: imagesBeforeReceiving,
      receivedByEmployee: receivedByEmployeeController.text.trim(),
      status: 'In Maintenance',
    );
    return device;
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
                    "Failed to add image: ${e.toString()}".tr(),
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
