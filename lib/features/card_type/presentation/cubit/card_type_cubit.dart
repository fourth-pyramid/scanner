import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/card_type/domain/entities/category_entity.dart';
import 'package:qrscanner/features/card_type/domain/usecases/clear_data_usecase.dart';
import 'package:qrscanner/features/card_type/domain/usecases/get_categories_usecase.dart';
import 'package:qrscanner/features/card_type/presentation/cubit/card_type_state.dart';

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
      (_) async {
        emit(CardTypeCleared());
        // Reload categories after clearing
        await getCategories();
        return true;
      },
    );
  }

  /// Static method to get cubit from context
  static CardTypeCubit of(BuildContext context) =>
      BlocProvider.of<CardTypeCubit>(context);
}
