import 'package:equatable/equatable.dart';

abstract class CardTypeStates extends Equatable {
  @override
  List<Object?> get props => [];
}

class CardTypeInitial extends CardTypeStates {}

class CardTypeSuccess extends CardTypeStates {}

class CardTypeError extends CardTypeStates {}

class CardTypeLoading extends CardTypeStates {}
