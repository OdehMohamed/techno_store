import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core2/widgets/message.dart';
import 'package:techno_store/core2/utils/app_colors.dart';
import 'package:techno_store/core2/widgets/main_app_bar.dart';
import 'package:techno_store/core2/widgets/main_button.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';

class PinVerificationPage extends StatefulWidget {
  final String verificationId;

  const PinVerificationPage({
    super.key,
    required this.verificationId,
  });

  @override
  State<PinVerificationPage> createState() => _PinVerificationPageState();
}

class _PinVerificationPageState extends State<PinVerificationPage> {
  final otpController = TextEditingController();
  final _advancedDrawerController = AdvancedDrawerController();
  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = BlocProvider.of<AuthCubit>(context);
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(width <= 500 ? height * 0.05 : height * 0.08),
        child: MainAppBar(
          haveLeading: false,
          advancedDrawerController: _advancedDrawerController,
          title: 'Code Verification'.tr(),
          onLanguageChanged: () => setState(() {}),
        ),
      ),
      body: SingleChildScrollView(
        child: BlocConsumer<AuthCubit, AuthState>(
          bloc: authCubit,
          listenWhen: (previous, current) =>
              current is VerifyAuthSuccess ||
              current is VerifyAuthFailure ||
              current is AuthSuccess,
          listener: (context, state) {
            if (state is VerifyAuthFailure) {
              Message.showBottomMessage(context, state.error, isError: true);
            }

            if (state is VerifyAuthSuccess) {
              Message.showBottomMessage(context, 'Login successful!'.tr());
            }

            if (state is AuthSuccess && (kIsWeb || Platform.isAndroid)) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
          builder: (context, state) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width <= 1025 ? width * 0.05 : width * 0.2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    kIsWeb
                        ? '../../../../../assets/images/EnterOTP.gif'
                        : 'assets/images/EnterOTP.gif',
                    width: width < 500 ? 300 : 500,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Enter the verification code sent to your phone'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Verification ID: '.tr() +
                        '${widget.verificationId.substring(0, 10)}...',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 10,
                        color: AppColors.primary),
                    decoration: const InputDecoration(
                      hintText: '------',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    onChanged: (value) {
                      if (value.length == 6) {
                        authCubit.verifySMSCode(widget.verificationId, value);
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                  if (state is VerifyAuthLoading)
                    const MainButton(isLoading: true)
                  else
                    MainButton(
                      label: "Verify Code".tr(),
                      onPressed: () {
                        if (otpController.text.length == 6) {
                          authCubit.verifySMSCode(
                            widget.verificationId,
                            otpController.text,
                          );
                        } else {
                          Message.showBottomMessage(
                            context,
                            'Please enter a 6-digit code',
                            isError: true,
                          );
                        }
                      },
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
