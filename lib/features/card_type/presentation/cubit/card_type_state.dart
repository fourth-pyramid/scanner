import 'package:equatable/equatable.dart';

import 'package:qrscanner/features/card_type/domain/entities/category_entity.dart';

/// States for CardTypeCubit
abstract class CardTypeState extends Equatable {
  const CardTypeState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CardTypeInitial extends CardTypeState {}

/// Loading state
class CardTypeLoading extends CardTypeState {}

/// Success state with categories
class CardTypeSuccess extends CardTypeState {
  const CardTypeSuccess({required this.categories});
  final List<CategoryEntity> categories;

  @override
  List<Object?> get props => [categories];
}

/// Error state
class CardTypeError extends CardTypeState {
  const CardTypeError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Data cleared state
class CardTypeCleared extends CardTypeState {}
