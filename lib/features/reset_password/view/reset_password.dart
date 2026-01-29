import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core2/widgets/message.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/core2/widgets/main_app_bar.dart';
import 'package:techno_store/core2/widgets/main_button.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';
import '../../../core/utils/widget_utilities.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  resetMessage(value) {
    if (value) {}
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    final authCubit = BlocProvider.of<AuthCubit>(context);
    final _advancedDrawerController = AdvancedDrawerController();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(height * 0.08),
        child: MainAppBar(
          haveLeading: false,
          advancedDrawerController: _advancedDrawerController,
          title: "Reset Password".tr(),
          onLanguageChanged: () {
            setState(() {});
          },
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
            child: SizedBox(
              height: height * 0.8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      WidgetUtilities.autoSizeText(
                          "We will send an Email to reset your password",
                          textAlign: TextAlign.center,
                          textStyle:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    color: AppColors.black,
                                  )),
                      SizedBox(
                        height: height * 0.01,
                      ),
                      WidgetUtilities.autoSizeText(
                        "check spam",
                        textAlign: TextAlign.center,
                        textStyle:
                            Theme.of(context).textTheme.labelLarge!.copyWith(
                                  color: AppColors.red,
                                ),
                      ),
                      SizedBox(
                        height: height * 0.05,
                      ),
                    ],
                  ),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        label: Text('Please Enter your Email'.tr()),
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
                  ),
                  SizedBox(
                    height: height * 0.1,
                  ),
                  BlocConsumer<AuthCubit, AuthState>(
                    bloc: authCubit,
                    listenWhen: (previous, current) =>
                        current is PasswordResetSuccess ||
                        current is PasswordResetFailure,
                    listener: (context, state) {
                      if (state is PasswordResetSuccess) {
                        Message.showBottomMessage(
                          context,
                          'Please check your email or spam'.tr(),
                        );
                        Future.delayed(const Duration(seconds: 4), () {
                          if (mounted && Navigator.canPop(context)) {
                            Navigator.of(context).pop();
                          }
                        });
                      } else if (state is PasswordResetFailure) {
                        Message.showBottomMessage(
                          context,
                          state.error,
                          isError: true,
                        );
                      }
                    },
                    buildWhen: (previous, current) =>
                        current is PasswordResetLoading ||
                        current is PasswordResetSuccess ||
                        current is PasswordResetFailure,
                    builder: (context, state) {
                      if (state is PasswordResetLoading) {
                        return const MainButton(
                          isLoading: true,
                        );
                      }

                      return MainButton(
                        label: 'Send Email'.tr(),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            authCubit.resetPassword(emailController.text);
                          }
                        },
                      );
                    },
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
