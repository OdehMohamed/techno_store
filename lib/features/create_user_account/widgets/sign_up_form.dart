import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/services/location_service.dart';
import 'package:techno_store/core2/widgets/message.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/core2/widgets/main_button.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';

class SignUpForm extends StatefulWidget {
  final String phoneNumber;
  const SignUpForm({super.key, required this.phoneNumber});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  String photoPath = "";
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService.instance;

  final fullnameController = TextEditingController();
  final nicknameController = TextEditingController();
  String? selectedCountry;
  String? selectedState;
  String? selectedCity;

  bool _isLoadingLocations = true;
  List<String> _countries = [];
  List<String> _states = [];
  List<String> _cities = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      await _locationService.loadLocations();
      setState(() {
        _countries = _locationService.getCountries();
        _isLoadingLocations = false;
      });
    } catch (e) {
      debugPrint('Error loading locations: $e');
      if (mounted) {
        setState(() => _isLoadingLocations = false);
        Message.showBottomMessage(
          context,
          'Failed to load locations'.tr(),
          isError: true,
        );
      }
    }
  }

  void _onCountryChanged(String? country) {
    setState(() {
      selectedCountry = country;
      selectedState = null;
      selectedCity = null;
      _states = country != null ? _locationService.getStates(country) : [];
      _cities = [];
    });
  }

  void _onStateChanged(String? state) {
    setState(() {
      selectedState = state;
      selectedCity = null;
      _cities = (state != null && selectedCountry != null)
          ? _locationService.getCities(selectedCountry!, state)
          : [];
    });
  }

  @override
  void dispose() {
    fullnameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = BlocProvider.of<AuthCubit>(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // const SizedBox(),
          Text(
            'Welcome! Please complete your profile to continue'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Phone: ${widget.phoneNumber}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Stack(
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.black,
                          blurRadius: 20,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: AppColors.white,
                      backgroundImage: photoPath.isNotEmpty
                          ? FileImage(File(photoPath))
                          : const AssetImage("assets/images/defaultImg.png")
                              as ImageProvider,
                    )),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      child: const SizedBox(
                        width: 25,
                        height: 25,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child:
                                Icon(Icons.add, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                      onTap: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                        );

                        if (result != null) {
                          final file = result.files.first;

                          setState(() {
                            photoPath = file.path!;
                            debugPrint("Selected file path: $photoPath");
                          });
                        }
                      },
                    )
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      child: const SizedBox(
                        width: 25,
                        height: 25,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 146, 40, 32),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      onTap: () async {
                        setState(() {
                          photoPath = "";
                          debugPrint("Photo path cleared");
                        });
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
          TextFormField(
            controller: fullnameController,
            style: const TextStyle(color: AppColors.primary),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.perm_identity_outlined,
                size: 28,
              ),
              label: Text('Full name'.tr()),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please Enter".tr() + " " + "Full name".tr();
              }
              return null;
            },
          ),
          TextFormField(
            controller: nicknameController,
            style: const TextStyle(color: AppColors.primary),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.person_rounded,
                size: 28,
              ),
              label: Text('Nickname'.tr()),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please Enter".tr() + " " + "Nickname".tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 30),
          // Country Dropdown
          _isLoadingLocations
              ? const Center(child: CircularProgressIndicator())
              : DropdownButtonFormField<String>(
                  initialValue: selectedCountry,
                  decoration: InputDecoration(
                    labelText: 'Country'.tr(),
                    prefixIcon: const Icon(Icons.public, size: 24),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.white,
                  ),
                  icon: const Icon(Icons.arrow_drop_down,
                      color: AppColors.primary),
                  style:
                      const TextStyle(color: AppColors.primary, fontSize: 14),
                  dropdownColor: AppColors.white,
                  items: _countries.map((String country) {
                    return DropdownMenuItem<String>(
                      value: country,
                      child: Text(country),
                    );
                  }).toList(),
                  onChanged: _onCountryChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please select".tr() + " " + "Country".tr();
                    }
                    return null;
                  },
                ),
          // const SizedBox(height: 5),
          // State Dropdown
          DropdownButtonFormField<String>(
            initialValue: selectedState,
            decoration: InputDecoration(
              labelText: 'State/Province'.tr(),
              prefixIcon: const Icon(Icons.location_city, size: 24),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: selectedCountry == null
                      ? Colors.grey.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.5),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: selectedCountry == null
                  ? Colors.grey.shade200
                  : AppColors.white,
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: selectedCountry == null ? Colors.grey : AppColors.primary,
            ),
            style: const TextStyle(color: AppColors.primary, fontSize: 14),
            dropdownColor: AppColors.white,
            items: _states.map((String state) {
              return DropdownMenuItem<String>(
                value: state,
                child: Text(state),
              );
            }).toList(),
            onChanged: selectedCountry == null ? null : _onStateChanged,
          ),
          // const SizedBox(height: 10),
          // City Dropdown
          DropdownButtonFormField<String>(
            initialValue: selectedCity,
            decoration: InputDecoration(
              labelText: 'City'.tr(),
              prefixIcon: const Icon(Icons.apartment, size: 24),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: selectedState == null
                      ? Colors.grey.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.5),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: selectedState == null
                  ? Colors.grey.shade200
                  : AppColors.white,
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: selectedState == null ? Colors.grey : AppColors.primary,
            ),
            style: const TextStyle(color: AppColors.primary, fontSize: 14),
            dropdownColor: AppColors.white,
            items: _cities.map((String city) {
              return DropdownMenuItem<String>(
                value: city,
                child: Text(city),
              );
            }).toList(),
            onChanged: selectedState == null
                ? null
                : (String? newValue) {
                    setState(() {
                      selectedCity = newValue;
                    });
                  },
          ),
          const SizedBox(height: 30),
          BlocConsumer<AuthCubit, AuthState>(
            bloc: authCubit,
            listenWhen: (previous, current) =>
                current is AuthFailure || current is AuthSuccess,
            listener: (context, state) {
              if (state is AuthFailure) {
                debugPrint("Auth Failure: ${state.error}");
                Message.showBottomMessage(context, state.error, isError: true);
              }
              if (state is AuthSuccess) {
                Message.showBottomMessage(
                    context, "Account created successfully".tr());
                Future.delayed(const Duration(seconds: 4), () {
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                });
              }
            },
            buildWhen: (previous, current) =>
                current is AuthLoading ||
                current is AuthSuccess ||
                current is AuthFailure,
            builder: (context, state) {
              if (state is AuthLoading) {
                return const Center(
                  child: MainButton(isLoading: true),
                );
              }
              return MainButton(
                label: 'Complete Profile'.tr(),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // بناء النص النهائي من البيانات المختارة
                    String location = selectedCountry ?? '';
                    if (selectedState != null && selectedState!.isNotEmpty) {
                      location += ', $selectedState';
                    }
                    if (selectedCity != null && selectedCity!.isNotEmpty) {
                      location += ', $selectedCity';
                    }

                    await authCubit.completeUserProfile(
                      phoneNumber: widget.phoneNumber,
                      name: fullnameController.text,
                      nickname: nicknameController.text,
                      photo: photoPath,
                      location: location,
                    );
                  }
                },
              );
            },
          ),
          Text(
            'This information is required to access the application'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
