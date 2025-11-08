import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';
import 'package:techno_store/features/reset_password/view/reset_password.dart';
import 'package:techno_store/features/main_screen/views/widgets/sign_in_buttons.dart';
import 'package:techno_store/features/main_screen/views/widgets/sign_in_form_text_fields.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({Key? key}) : super(key: key);

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final loginEmail = TextEditingController();
  final loginPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isSecret = true;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    final authCubit = BlocProvider.of<AuthCubit>(context);

    return Form(
      key: _formKey,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.05),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: height * 0.8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Image.asset(
                    kIsWeb
                        ? '../../../../../assets/images/technoLogo.png'
                        : 'assets/images/technoLogo.png',
                    width: width < 500 ? 200 : 300,
                  ),
                  // Text("Login".tr(),
                  //     style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  //           color: AppColors.primary,
                  //         )),
                  if (width <= 1000)
                    SignInFormTextFields(
                      loginEmail: loginEmail,
                      loginPassword: loginPassword,
                      authCubit: authCubit,
                    ),
                  if (width <= 1000)
                    SignInButtons(
                      formKey: _formKey,
                      loginEmail: loginEmail,
                      loginPassword: loginPassword,
                      authCubit: authCubit,
                    ),
                  if (width > 1000)
                    SizedBox(
                      height: height * 0.215,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: width * 0.4,
                            child: SignInFormTextFields(
                              loginEmail: loginEmail,
                              loginPassword: loginPassword,
                              authCubit: authCubit,
                            ),
                          ),
                          SizedBox(
                            height: height * 0.17,
                            child: const VerticalDivider(
                              color: AppColors.primary,
                              thickness: 1,
                              width: 20,
                            ),
                          ),
                          SizedBox(
                            width: width * 0.4,
                            child: SignInButtons(
                              formKey: _formKey,
                              loginEmail: loginEmail,
                              loginPassword: loginPassword,
                              authCubit: authCubit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  InkWell(
                    child: Text("Forget password".tr() + "?".tr(),
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.normal,
                            )),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BlocProvider.value(
                                  value: authCubit,
                                  child: const ResetPassword(),
                                )),
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
