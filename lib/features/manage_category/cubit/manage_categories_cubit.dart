import 'package:flutter_bloc/flutter_bloc.dart';

part 'manage_categories_state.dart';

class ManageCategoriesCubit extends Cubit<ManageCategoriesState> {
  ManageCategoriesCubit() : super(ManageCategoriesInitial());

  Future<void> loadCategories() async {
    emit(ManageCategoriesLoading());
    try {
      emit(ManageCategoriesLoaded());
    } catch (e) {
      emit(ManageCategoriesError(e.toString()));
    }
  }
}
