import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/saved_data/domain/entities/saved_scan_entity.dart';
import 'package:qrscanner/features/saved_data/domain/usecases/get_saved_scans_usecase.dart';
import 'package:qrscanner/features/saved_data/presentation/cubit/saved_data_state.dart';

/// Cubit for SavedData feature
/// Only handles UI state and calls UseCases - no business logic
class SavedDataCubit extends Cubit<SavedDataState> {
  SavedDataCubit({required this.getSavedScansUseCase})
    : super(SavedDataInitial());
  final GetSavedScansUseCase getSavedScansUseCase;

  List<SavedScanEntity> _scans = [];

  List<SavedScanEntity> get scans => _scans;

  /// Load all saved scans
  Future<void> loadScans() async {
    emit(SavedDataLoading());

    final result = await getSavedScansUseCase(NoParams());

    result.fold((failure) => emit(SavedDataError(message: failure.message)), (
      scans,
    ) {
      _scans = scans;
      emit(SavedDataSuccess(scans: scans));
    });
  }

  /// Static method to get cubit from context
  static SavedDataCubit of(BuildContext context) =>
      BlocProvider.of<SavedDataCubit>(context);
}
