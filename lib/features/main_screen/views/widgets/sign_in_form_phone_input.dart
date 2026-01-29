import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:flutter/widgets.dart' as widgets;

// ignore: must_be_immutable
class SignInFormPhoneInput extends StatelessWidget {
  final TextEditingController phoneController;
  String phoneCode;
  SignInFormPhoneInput({
    super.key,
    required this.phoneController,
    required this.phoneCode,
  });
  @override
  Widget build(BuildContext context) {
    PhoneNumber number = PhoneNumber(isoCode: 'PS');
    return InternationalPhoneNumberInput(
      textStyle: const TextStyle(
        color: AppColors.primary,
      ),
      errorMessage: "Invalid phone number".tr(),
      hintText: "Phone number".tr(),
      onInputChanged: (PhoneNumber number) {
        phoneCode = number.dialCode!;
      },
      onInputValidated: (bool value) {
        // phoneValid = value;
      },
      selectorConfig: const SelectorConfig(
        selectorType: PhoneInputSelectorType.DIALOG,
      ),
      autoValidateMode: AutovalidateMode.always,
      selectorTextStyle: const TextStyle(
        color: AppColors.primary,
      ),
      initialValue: number,
      textFieldController: phoneController,
      formatInput: false,
    );
  }
}
