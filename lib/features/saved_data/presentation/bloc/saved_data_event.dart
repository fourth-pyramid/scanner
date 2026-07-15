part of 'saved_data_bloc.dart';

// ponytail: standard bloc events for saved data
abstract class SavedDataEvent extends Equatable {
  const SavedDataEvent();

  @override
  List<Object?> get props => [];
}

class LoadScansEvent extends SavedDataEvent {
  const LoadScansEvent();
}

class SearchScansEvent extends SavedDataEvent {
  const SearchScansEvent(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}
