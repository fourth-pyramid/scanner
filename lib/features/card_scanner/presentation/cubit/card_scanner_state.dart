import 'package:equatable/equatable.dart';

// ponytail: standard 6 states for card scanner
abstract class CardScannerState extends Equatable {
  const CardScannerState();

  @override
  List<Object?> get props => [];
}

class CardScannerInitial extends CardScannerState {}

class CardScannerLoading extends CardScannerState {}

class CardScannerSuccess extends CardScannerState {
  const CardScannerSuccess();
}

class CardScannerError extends CardScannerState {
  const CardScannerError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class CardScannerEmpty extends CardScannerState {}

class CardScannerRefreshing extends CardScannerState {}
