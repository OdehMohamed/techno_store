part of 'home_cubit.dart';

sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeLoading extends HomeState {}

final class HomeLoaded extends HomeState {
  final UserData userData;

  HomeLoaded(this.userData);
}

final class HomeError extends HomeState {
  final String message;

  HomeError(this.message);
}
