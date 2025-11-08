import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/utils/message.dart';
import 'package:techno_store/core/utils/widget_utilities.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/core2/widgets/main_button.dart';
import 'package:techno_store/features/create_user_account/view/create_user_account_view.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';

class SignInButtons extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController loginEmail;
  final TextEditingController loginPassword;
  final AuthCubit authCubit;
  const SignInButtons({
    super.key,
    required this.formKey,
    required this.loginEmail,
    required this.loginPassword,
    required this.authCubit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              Message.showBottomMessage(context, "Login Success.".tr());
            }
          },
          builder: (context, state) {
            if (state is AuthLoading) {
              return const MainButton(
                isLoading: true,
              );
            }
            return MainButton(
              label: "Login".tr(),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await authCubit.signIn(
                        loginEmail.text.trim(), loginPassword.text);
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                } else {
                  return;
                }
              },
            );
          },
        ),
        const SizedBox(
          height: 15,
        ),
        WidgetUtilities.autoSizeText(
          "or",
          textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.normal,
              ),
        ),
        const SizedBox(
          height: 15,
        ),
        MainButton(
          label: "Create new Account".tr(),
          bgColor: AppColors.white,
          textColor: AppColors.primary,
          onPressed: () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                        value: authCubit,
                        child: const CreateUserAccount(),
                      )),
            );
          },
        ),
      ],
    );
  }
}
