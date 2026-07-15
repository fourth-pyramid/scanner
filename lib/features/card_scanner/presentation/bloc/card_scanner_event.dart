part of 'card_scanner_bloc.dart';

// ponytail: standard bloc events for card scanner
abstract class CardScannerEvent extends Equatable {
  const CardScannerEvent();

  @override
  List<Object?> get props => [];
}

class ClearAllDataEvent extends CardScannerEvent {
  const ClearAllDataEvent();
}
