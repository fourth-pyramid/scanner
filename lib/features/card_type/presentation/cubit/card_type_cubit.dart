import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/clear_data_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import 'card_type_state.dart';

/// Cubit for CardType feature
/// Only handles UI state and calls UseCases - no business logic
class CardTypeCubit extends Cubit<CardTypeState> {
  CardTypeCubit({
    required this.getCategoriesUseCase,
    required this.clearDataUseCase,
  }) : super(CardTypeInitial());
  final GetCategoriesUseCase getCategoriesUseCase;
  final ClearDataUseCase clearDataUseCase;

  List<CategoryEntity> _categories = [];

  List<CategoryEntity> get categories => _categories;

  /// Load all categories
  Future<void> getCategories() async {
    emit(CardTypeLoading());

    final result = await getCategoriesUseCase(NoParams());

    result.fold((failure) => emit(CardTypeError(message: failure.message)), (
      categories,
    ) {
      _categories = categories;
      emit(CardTypeSuccess(categories: categories));
    });
  }

  /// Clear all data
  Future<bool> clearData() async {
    emit(CardTypeLoading());

    final result = await clearDataUseCase(NoParams());

    return result.fold(
      (failure) {
        emit(CardTypeError(message: failure.message));
        return false;
      },
      (_) {
        emit(CardTypeCleared());
        // Reload categories after clearing
        getCategories();
        return true;
      },
    );
  }

  /// Static method to get cubit from context
  static CardTypeCubit of(BuildContext context) =>
      BlocProvider.of<CardTypeCubit>(context);
}
