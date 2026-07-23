import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/utils/app_colors.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';
import 'package:techno_store/features/main_screen/views/widgets/sign_in_buttons_phone_method.dart';
import 'package:techno_store/features/main_screen/views/widgets/sign_in_form_phone_input.dart';
import 'package:techno_store/features/main_screen/views/widgets/staff_sign_in_page.dart';

class SignInFormPhoneMethod extends StatefulWidget {
  const SignInFormPhoneMethod({super.key});

  @override
  State<SignInFormPhoneMethod> createState() => _SignInFormPhoneMethodState();
}

class _SignInFormPhoneMethodState extends State<SignInFormPhoneMethod> {
  final phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String phoneCode = '+970';

  @override
  Widget build(BuildContext context) {
    final authCubit = BlocProvider.of<AuthCubit>(context);
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width <= 1025 ? width * 0.05 : width * 0.1,
          ),
          child: SafeArea(
            child: SizedBox(
              height: height * 0.8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (width <= 1200)
                    Image.asset(
                      kIsWeb
                          ? '../../../../../assets/images/Login.gif'
                          : 'assets/images/Login.gif',
                      width: width < 500 ? 300 : 400,
                      filterQuality: FilterQuality.high,
                    ),
                  if (width <= 1200)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.phone_android_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Login with Phone'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your phone number to continue'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SignInFormPhoneInput(
                          phoneController: phoneController,
                          onCodeChanged: (code) => setState(() {
                            phoneCode = code;
                          }),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        SignInButtonsPhoneMethod(
                          formKey: _formKey,
                          phoneControl: phoneController,
                          phoneCode: phoneCode,
                        ),
                      ],
                    ),
                  if (width > 1200)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          kIsWeb
                              ? '../../../../../assets/images/Login.gif'
                              : 'assets/images/Login.gif',
                          width: width < 500 ? 300 : 500,
                          filterQuality: FilterQuality.high,
                        ),
                        const SizedBox(
                          width: 60,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Login with Phone'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: width * 0.3,
                              child: SignInFormPhoneInput(
                                phoneController: phoneController,
                                onCodeChanged: (code) => setState(() {
                                  phoneCode = code;
                                }),
                              ),
                            ),
                            const SizedBox(
                              height: 50,
                            ),
                            SizedBox(
                              width: width * 0.3,
                              child: SignInButtonsPhoneMethod(
                                formKey: _formKey,
                                phoneControl: phoneController,
                                phoneCode: phoneCode,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  // Staff sign-in entry point — small and low-emphasis, but
                  // deliberately visible rather than hidden behind a
                  // gesture, per the agreed Staff Auth workflow design.
                  // Leads to its own screen; never a toggle inside this
                  // customer form, keeping the two authentication paths
                  // visually and structurally separate.
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: authCubit,
                            child: const StaffSignInPage(),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Staff sign in'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
