import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';

class SignInFormTextFields extends StatelessWidget {
  final TextEditingController loginEmail;
  final TextEditingController loginPassword;
  final AuthCubit authCubit;
  const SignInFormTextFields(
      {super.key,
      required this.loginEmail,
      required this.loginPassword,
      required this.authCubit});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    bool isSecret = true;
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Column(
          children: [
            TextFormField(
              controller: loginEmail,
              style: const TextStyle(color: AppColors.black),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  size: 28,
                ),
                label: Text("Email".tr()),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please Enter".tr() + " " + "Email".tr();
                }
                if (!RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                    .hasMatch(value)) {
                  return "Please Enter".tr() + " " + "valid Email".tr();
                }
                return null;
              },
            ),
            SizedBox(
              height: height * 0.04,
            ),
            BlocBuilder<AuthCubit, AuthState>(
              bloc: authCubit,
              buildWhen: (previous, current) =>
                  current is PasswordSecretChanged,
              builder: (context, state) {
                if (state is PasswordSecretChanged) {
                  isSecret = state.isSecret;
                }
                return TextFormField(
                  controller: loginPassword,
                  obscureText: isSecret,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.lock_outlined,
                      size: 28,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(isSecret
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () {
                        authCubit.passwordSecretChanged(!isSecret);
                      },
                    ),
                    label: Text("Password".tr()),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please Enter".tr() + " " + "Password".tr();
                    }
                    if (value.contains(" ")) {
                      return "Password".tr() + " " + "can't have spaces".tr();
                    }
                    return null;
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
