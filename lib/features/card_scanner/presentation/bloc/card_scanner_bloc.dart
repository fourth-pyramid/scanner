import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/card_scanner/domain/usecases/clear_data_usecase.dart';

part 'card_scanner_event.dart';
part 'card_scanner_state.dart';

// ponytail: bloc for card scanner feature
class CardScannerBloc extends Bloc<CardScannerEvent, CardScannerState> {
  CardScannerBloc({required this.clearDataUseCase}) : super(CardScannerInitial()) {
    on<ClearAllDataEvent>(_onClearAllData);
  }

  final ClearDataUseCase clearDataUseCase;

  Future<void> _onClearAllData(
    ClearAllDataEvent event,
    Emitter<CardScannerState> emit,
  ) async {
    emit(CardScannerLoading());
    final result = await clearDataUseCase(NoParams());
    result.fold(
      (failure) => emit(CardScannerError(message: failure.message)),
      (_) => emit(const CardScannerSuccess()),
    );
  }
}
