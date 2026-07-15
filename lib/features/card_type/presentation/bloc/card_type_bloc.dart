import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/card_type/domain/entities/category_entity.dart';
import 'package:qrscanner/features/card_type/domain/usecases/get_categories_usecase.dart';

part 'card_type_event.dart';
part 'card_type_state.dart';

// ponytail: bloc for card type feature
class CardTypeBloc extends Bloc<CardTypeEvent, CardTypeState> {
  CardTypeBloc({required this.getCategoriesUseCase}) : super(CardTypeInitial()) {
    on<GetCategoriesEvent>(_onGetCategories);
  }

  final GetCategoriesUseCase getCategoriesUseCase;

  List<CategoryEntity> _categories = [];
  List<CategoryEntity> get categories => _categories;

  Future<void> _onGetCategories(
    GetCategoriesEvent event,
    Emitter<CardTypeState> emit,
  ) async {
    emit(CardTypeLoading());

    final result = await getCategoriesUseCase(NoParams());

    result.fold(
      (failure) => emit(CardTypeError(message: failure.message)),
      (categories) {
        _categories = categories;
        if (categories.isEmpty) {
          emit(CardTypeEmpty());
        } else {
          emit(CardTypeSuccess(categories: categories));
        }
      },
    );
  }
}
