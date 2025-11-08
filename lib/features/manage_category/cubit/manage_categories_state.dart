part of 'manage_categories_cubit.dart';

sealed class ManageCategoriesState {}

final class ManageCategoriesInitial extends ManageCategoriesState {}

final class ManageCategoriesLoading extends ManageCategoriesState {}

final class ManageCategoriesLoaded extends ManageCategoriesState {}

final class ManageCategoriesError extends ManageCategoriesState {
  final String message;
  ManageCategoriesError(this.message);
}