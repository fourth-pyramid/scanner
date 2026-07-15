part of 'card_type_bloc.dart';

// ponytail: standard 6 states for card type
abstract class CardTypeState extends Equatable {
  const CardTypeState();

  @override
  List<Object?> get props => [];
}

class CardTypeInitial extends CardTypeState {}

class CardTypeLoading extends CardTypeState {}

class CardTypeSuccess extends CardTypeState {
  const CardTypeSuccess({required this.categories});
  final List<CategoryEntity> categories;

  @override
  List<Object?> get props => [categories];
}

class CardTypeError extends CardTypeState {
  const CardTypeError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class CardTypeEmpty extends CardTypeState {}

class CardTypeRefreshing extends CardTypeState {
  const CardTypeRefreshing({required this.categories});
  final List<CategoryEntity> categories;

  @override
  List<Object?> get props => [categories];
}
