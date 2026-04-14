import 'package:equatable/equatable.dart';

import '../../domain/entities/saved_scan_entity.dart';

/// States for SavedDataCubit
abstract class SavedDataState extends Equatable {
  const SavedDataState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SavedDataInitial extends SavedDataState {}

/// Loading state
class SavedDataLoading extends SavedDataState {}

/// Success state with saved scans
class SavedDataSuccess extends SavedDataState {
  const SavedDataSuccess({required this.scans});
  final List<SavedScanEntity> scans;

  @override
  List<Object?> get props => [scans];
}

/// Error state
class SavedDataError extends SavedDataState {
  const SavedDataError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}
