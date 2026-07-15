import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/card_type/domain/entities/category_entity.dart';
import 'package:qrscanner/features/card_type/domain/usecases/get_categories_usecase.dart';
import 'package:qrscanner/features/card_type/presentation/cubit/card_type_state.dart';

/// Cubit for CardType feature
/// Only handles UI state and calls UseCases - no business logic
class CardTypeCubit extends Cubit<CardTypeState> {
  CardTypeCubit({
    required this.getCategoriesUseCase,
  }) : super(CardTypeInitial());
  final GetCategoriesUseCase getCategoriesUseCase;

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

  // ponytail: removed unused clearData functionality

  /// Static method to get cubit from context
  static CardTypeCubit of(BuildContext context) =>
      BlocProvider.of<CardTypeCubit>(context);
}
