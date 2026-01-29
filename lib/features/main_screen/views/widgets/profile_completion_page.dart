import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core2/widgets/message.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/core2/widgets/main_button.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';

class ProfileCompletionPage extends StatefulWidget {
  final String uid;
  final String phoneNumber;

  const ProfileCompletionPage({
    super.key,
    required this.uid,
    required this.phoneNumber,
  });

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final nicknameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = BlocProvider.of<AuthCubit>(context);
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Your Profile'.tr()),
        automaticallyImplyLeading: false,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        bloc: authCubit,
        listener: (context, state) {
          if (state is AuthFailure) {
            Message.showBottomMessage(context, state.error, isError: true);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // صورة توضيحية
                  Icon(
                    Icons.person_add_alt_1,
                    size: width < 500 ? 100 : 150,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Welcome! Please complete your profile to continue'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Phone: ${widget.phoneNumber}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // حقل الاسم
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name'.tr(),
                      hintText: 'Enter your full name'.tr(),
                      prefixIcon: const Icon(Icons.person),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name'.tr();
                      }
                      if (value.trim().length < 3) {
                        return 'Name must be at least 3 characters'.tr();
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: nicknameController,
                    decoration: InputDecoration(
                      labelText: 'Nickname'.tr(),
                      hintText: 'Enter your nickname'.tr(),
                      prefixIcon: const Icon(Icons.person),
                      border: const OutlineInputBorder(),
                    ),
                    // validator: (value) {
                    //   if (value == null || value.trim().isEmpty) {
                    //     return 'Please enter your nickname'.tr();
                    //   }
                    //   if (value.trim().length < 3) {
                    //     return 'Nickname must be at least 3 characters'.tr();
                    //   }
                    //   return null;
                    // },
                  ),

                  const SizedBox(height: 20),

                  // حقل البريد الإلكتروني
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email'.tr(),
                      hintText: 'Enter your email'.tr(),
                      prefixIcon: const Icon(Icons.email),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email'.tr();
                      }
                      // تحقق بسيط من صيغة البريد
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email'.tr();
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 40),

                  // زر الحفظ
                  if (state is AuthLoading)
                    const MainButton(isLoading: true)
                  else
                    MainButton(
                      label: "Complete Profile".tr(),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // authCubit.completeUserProfile(
                          //   name: nameController.text.trim(),
                          //   photo: widget.uid,
                          //   email: emailController.text.trim(),
                          // );
                        }
                      },
                    ),

                  const SizedBox(height: 20),

                  // نص توضيحي
                  Text(
                    'This information is required to access the application'
                        .tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
