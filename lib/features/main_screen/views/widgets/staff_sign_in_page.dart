import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/utils/app_colors.dart';
import 'package:techno_store/core/widgets/main_app_bar.dart';
import 'package:techno_store/core/widgets/main_button.dart';
import 'package:techno_store/core/widgets/message.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';
import 'package:techno_store/features/reset_password/view/reset_password.dart';

/// Staff-only email/password sign-in — a dedicated screen, deliberately
/// separate from the customer phone-OTP flow rather than a toggle inside
/// it. See docs/product/PRD.md (Auth & Account Lifecycle) and ADR-004's
/// Staff Status Architecture Pass.
class StaffSignInPage extends StatefulWidget {
  const StaffSignInPage({super.key});

  @override
  State<StaffSignInPage> createState() => _StaffSignInPageState();
}

class _StaffSignInPageState extends State<StaffSignInPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _advancedDrawerController = AdvancedDrawerController();
  bool isSecret = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = BlocProvider.of<AuthCubit>(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(width <= 500 ? height * 0.05 : height * 0.08),
        child: MainAppBar(
          advancedDrawerController: _advancedDrawerController,
          title: 'Staff Sign In'.tr(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width <= 1025 ? width * 0.05 : width * 0.2,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: emailController,
                    style: const TextStyle(color: AppColors.primary),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_outlined, size: 28),
                      label: Text('Email'.tr()),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Please Enter".tr() + " " + "Email".tr();
                      }
                      if (!RegExp(
                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                          .hasMatch(value.trim())) {
                        return "Please Enter".tr() + " " + "valid Email".tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  BlocBuilder<AuthCubit, AuthState>(
                    bloc: authCubit,
                    buildWhen: (previous, current) =>
                        current is PasswordSecretChanged,
                    builder: (context, state) {
                      if (state is PasswordSecretChanged) {
                        isSecret = state.isSecret;
                      }
                      return TextFormField(
                        controller: passwordController,
                        style: const TextStyle(color: AppColors.primary),
                        obscureText: isSecret,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline, size: 28),
                          label: Text('Password'.tr()),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isSecret
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () =>
                                authCubit.passwordSecretChanged(!isSecret),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please Enter".tr() + " " + "Password".tr();
                          }
                          return null;
                        },
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: authCubit,
                              child: const ResetPassword(),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot password?'.tr(),
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  BlocConsumer<AuthCubit, AuthState>(
                    bloc: authCubit,
                    listenWhen: (previous, current) =>
                        current is AuthFailure || current is AuthSuccess,
                    listener: (context, state) {
                      if (state is AuthFailure) {
                        Message.showBottomMessage(
                          context,
                          state.error,
                          isError: true,
                        );
                      }
                      if (state is AuthSuccess) {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    },
                    buildWhen: (previous, current) =>
                        current is AuthLoading ||
                        current is AuthFailure ||
                        current is AuthSuccess,
                    builder: (context, state) {
                      if (state is AuthLoading) {
                        return const MainButton(isLoading: true);
                      }
                      return MainButton(
                        label: 'Sign In'.tr(),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            authCubit.signIn(
                              emailController.text.trim(),
                              passwordController.text,
                            );
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
