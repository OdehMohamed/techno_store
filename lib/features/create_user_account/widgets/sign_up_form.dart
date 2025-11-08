import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/utils/message.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/core2/widgets/main_button.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  String photoPath = "";
  final _formKey = GlobalKey<FormState>();

  final fullnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final rePasswordController = TextEditingController();
  @override
  void dispose() {
    fullnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    rePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = BlocProvider.of<AuthCubit>(context);
    bool isSecret = true;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(),
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
            controller: emailController,
            style: const TextStyle(color: AppColors.primary),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.email_outlined,
                size: 28,
              ),
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
          BlocBuilder<AuthCubit, AuthState>(
            bloc: authCubit,
            buildWhen: (previous, current) => current is PasswordSecretChanged,
            builder: (context, state) {
              if (state is PasswordSecretChanged) {
                isSecret = state.isSecret;
              }
              return TextFormField(
                obscureText: isSecret,
                controller: passwordController,
                style: const TextStyle(color: AppColors.primary),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    size: 28,
                  ),
                  label: Text('Password'.tr()),
                  suffixIcon: IconButton(
                      icon: Icon(isSecret
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () {
                        authCubit.passwordSecretChanged(!isSecret);
                      }),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please Enter".tr() + " " + "Password".tr();
                  }
                  if (value.length < 8) {
                    return "Password".tr() + " " + "too short".tr();
                  }
                  if (value.contains(" ")) {
                    return "Password".tr() + " " + "can't have spaces".tr();
                  }
                  if (value != rePasswordController.value.text) {
                    return "Passwords does not match".tr();
                  }
                  return null;
                },
              );
            },
          ),
          BlocBuilder<AuthCubit, AuthState>(
            bloc: authCubit,
            buildWhen: (previous, current) => current is PasswordSecretChanged,
            builder: (context, state) {
              return TextFormField(
                  obscureText: isSecret,
                  controller: rePasswordController,
                  style: const TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      size: 28,
                    ),
                    label: Text('re-password'.tr()),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please Enter".tr() + " " + "re-password".tr();
                    }
                    if (value != passwordController.value.text) {
                      return "Passwords does not match".tr();
                    }
                    return null;
                  });
            },
          ),
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
                label: "Create Account".tr(),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await authCubit.signUp(
                      emailController.text.trim(),
                      passwordController.text,
                      photoPath,
                      fullnameController.text,
                      1,
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
