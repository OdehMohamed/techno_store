import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/utils/message.dart';
import 'package:techno_store/core/utils/widget_utilities.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/core2/widgets/main_button.dart';
import 'package:techno_store/features/create_user_account/view/create_user_account_view.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';
import 'package:techno_store/features/main_screen/views/widgets/pin_verification_page.dart';

class SignInButtonsPhoneMethod extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneControl;
  final String phoneCode;
  const SignInButtonsPhoneMethod({
    super.key,
    required this.formKey,
    required this.phoneControl,
    required this.phoneCode,
  });

  @override
  State<SignInButtonsPhoneMethod> createState() =>
      _SignInButtonsPhoneMethodState();
}

class _SignInButtonsPhoneMethodState extends State<SignInButtonsPhoneMethod> {
  @override
  Widget build(BuildContext context) {
    final authCubit = BlocProvider.of<AuthCubit>(context);
    return Column(
      children: [
        BlocConsumer<AuthCubit, AuthState>(
          bloc: authCubit,
          listenWhen: (previous, current) =>
              current is AuthSendCodeFailure ||
              current is AuthInitial ||
              (current is AuthSendCodeSuccess &&
                  (kIsWeb || (!kIsWeb && Platform.isAndroid))),
          listener: (context, state) {
            if (state is AuthSendCodeFailure) {
              debugPrint("❌ Send Code Failure: ${state.error}");
              Message.showBottomMessage(context, state.error, isError: true);
            }

            if (state is AuthSendCodeSuccess) {
              if (kIsWeb || (!kIsWeb && Platform.isAndroid)) {
                debugPrint("✅ Code sent successfully: ${state.verifyId}");
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: authCubit,
                          child: PinVerificationPage(
                            verificationId: state.verifyId,
                          ),
                        ),
                      ),
                    );
                  }
                });
              }
            }
          },
          buildWhen: (previous, current) {
            if (current is AuthSendCodeSuccess) {
              return kIsWeb || (!kIsWeb && Platform.isAndroid);
            }
            return true;
          },
          builder: (context, state) {
            debugPrint("🔵 SignInButton State: ${state.runtimeType}");

            // if (state is AuthSendCodeLoading) {
            //   return const MainButton(isLoading: true);
            // }

            return MainButton(
              label: "Login".tr(),
              onPressed: () async {
                final fullPhone = widget.phoneCode + widget.phoneControl.text;
                if (widget.formKey.currentState!.validate()) {
                  debugPrint("📱 Phone Sign In: $fullPhone");
                  await authCubit.signInWithPhone(fullPhone);
                }
              },
            );
          },
        ),
        // const SizedBox(
        //   height: 15,
        // ),
        // WidgetUtilities.autoSizeText(
        //   "or",
        //   textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
        //         color: AppColors.primary,
        //         fontWeight: FontWeight.normal,
        //       ),
        // ),
        // const SizedBox(
        //   height: 15,
        // ),
        // MainButton(
        //   label: "Create new Account".tr(),
        //   bgColor: AppColors.white,
        //   textColor: AppColors.primary,
        //   onPressed: () async {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (context) => BlocProvider.value(
        //           value: authCubit,
        //           child: const CreateUserAccount(),
        //         ),
        //       ),
        //     );
        //   },
        // ),
      ],
    );
  }
}
