import 'package:equatable/equatable.dart';

abstract class SavedDataStates extends Equatable {
  @override
  List<Object?> get props => [];
}

class SavedDataInit extends SavedDataStates {}

class SavedDataSuccess extends SavedDataStates {}

class SavedDataLoading extends SavedDataStates {}

class SavedDataError extends SavedDataStates {}
