import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/card_scanner/domain/usecases/clear_data_usecase.dart';
import 'package:qrscanner/features/card_scanner/presentation/cubit/card_scanner_state.dart';

// ponytail: cubit for card scanner feature
class CardScannerCubit extends Cubit<CardScannerState> {
  CardScannerCubit({required this.clearDataUseCase}) : super(CardScannerInitial());

  final ClearDataUseCase clearDataUseCase;

  Future<void> clearAllData() async {
    emit(CardScannerLoading());
    final result = await clearDataUseCase(NoParams());
    result.fold(
      (failure) => emit(CardScannerError(message: failure.message)),
      (_) => emit(const CardScannerSuccess()),
    );
  }

  static CardScannerCubit of(BuildContext context) => BlocProvider.of<CardScannerCubit>(context);
}
