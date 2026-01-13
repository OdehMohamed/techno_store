import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core2/model/user_data.dart';
import 'package:techno_store/features/home_page/services/home_services.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());
  final HomeServices _homeServices = HomeServices();

  Future<void> loadUserData() async {
    emit(HomeLoading());
    try {
      final UserData? userData = await _homeServices.getUserData();
      debugPrint(
          'User data loaded: ${userData!.toMap().toString()} ${userData.metaToMap().toString()}');
      emit(HomeLoaded(userData));
    } catch (e) {
      debugPrint('Error loading user data: $e');
      emit(HomeError(e.toString()));
    }
  }
}
