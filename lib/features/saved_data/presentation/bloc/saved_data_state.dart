part of 'saved_data_bloc.dart';

// ponytail: standard 6 states for saved data
abstract class SavedDataState extends Equatable {
  const SavedDataState();

  @override
  List<Object?> get props => [];
}

class SavedDataInitial extends SavedDataState {}

class SavedDataLoading extends SavedDataState {}

class SavedDataSuccess extends SavedDataState {
  const SavedDataSuccess({required this.scans});
  final List<SavedScanEntity> scans;

  @override
  List<Object?> get props => [scans];
}

class SavedDataError extends SavedDataState {
  const SavedDataError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class SavedDataEmpty extends SavedDataState {}

class SavedDataRefreshing extends SavedDataState {
  const SavedDataRefreshing({required this.scans});
  final List<SavedScanEntity> scans;

  @override
  List<Object?> get props => [scans];
}
