import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/saved_data/domain/entities/saved_scan_entity.dart';
import 'package:qrscanner/features/saved_data/domain/usecases/get_saved_scans_usecase.dart';

part 'saved_data_event.dart';
part 'saved_data_state.dart';

// ponytail: bloc for saved data feature
class SavedDataBloc extends Bloc<SavedDataEvent, SavedDataState> {
  SavedDataBloc({required this.getSavedScansUseCase}) : super(SavedDataInitial()) {
    on<LoadScansEvent>(_onLoadScans);
    on<SearchScansEvent>(_onSearchScans);
  }

  final GetSavedScansUseCase getSavedScansUseCase;

  List<SavedScanEntity> _allScans = [];
  String _searchQuery = '';

  List<SavedScanEntity> get scans {
    if (_searchQuery.isEmpty) return _allScans;
    final query = _searchQuery.toLowerCase();
    return _allScans
        .where(
          (scan) =>
              (scan.pin?.toLowerCase().contains(query) ?? false) ||
              (scan.serial?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  Future<void> _onLoadScans(
    LoadScansEvent event,
    Emitter<SavedDataState> emit,
  ) async {
    emit(SavedDataLoading());

    final result = await getSavedScansUseCase(NoParams());

    result.fold(
      (failure) => emit(SavedDataError(message: failure.message)),
      (scans) {
        _allScans = scans;
        if (scans.isEmpty) {
          emit(SavedDataEmpty());
        } else {
          emit(SavedDataSuccess(scans: this.scans));
        }
      },
    );
  }

  void _onSearchScans(
    SearchScansEvent event,
    Emitter<SavedDataState> emit,
  ) {
    _searchQuery = event.query;
    if (_allScans.isEmpty && _searchQuery.isEmpty) {
      emit(SavedDataEmpty());
    } else {
      emit(SavedDataSuccess(scans: scans));
    }
  }
}
