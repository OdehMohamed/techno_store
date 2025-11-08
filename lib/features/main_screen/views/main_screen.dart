import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/features/home_page/cubit/home_cubit.dart';
import 'package:techno_store/features/main_screen/cubit/auth_cubit.dart';
import 'package:techno_store/features/main_screen/views/widgets/sign_in.dart';
import 'package:techno_store/features/home_page/view/home_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final authCubit = BlocProvider.of<AuthCubit>(context);
    final homeCubit = BlocProvider.of<HomeCubit>(context);
    return BlocBuilder<AuthCubit, AuthState>(
      bloc: authCubit,
      builder: (context, state) {
        if (state is AuthSuccess) {
          homeCubit.loadUserData();
          return const HomePage();
        } else {
          return const SignIn();
        }
      },
    );
  }
}
