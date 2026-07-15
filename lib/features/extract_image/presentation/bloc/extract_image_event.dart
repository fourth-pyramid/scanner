part of 'extract_image_bloc.dart';

// ponytail: standard bloc events for extract image
abstract class ExtractImageEvent extends Equatable {
  const ExtractImageEvent();

  @override
  List<Object?> get props => [];
}

class SetImageEvent extends ExtractImageEvent {
  const SetImageEvent(this.image);
  final File image;

  @override
  List<Object?> get props => [image];
}

class ProcessImageEvent extends ExtractImageEvent {
  const ProcessImageEvent();
}

class SubmitScanEvent extends ExtractImageEvent {
  const SubmitScanEvent({required this.phoneType, required this.categoryId});
  final String phoneType;
  final int categoryId;

  @override
  List<Object?> get props => [phoneType, categoryId];
}

class LoadHistoryCountEvent extends ExtractImageEvent {
  const LoadHistoryCountEvent();
}

class ResetEvent extends ExtractImageEvent {
  const ResetEvent();
}

class UpdatePinEvent extends ExtractImageEvent {
  const UpdatePinEvent(this.pin);
  final String pin;

  @override
  List<Object?> get props => [pin];
}

class UpdateSerialEvent extends ExtractImageEvent {
  const UpdateSerialEvent(this.serial);
  final String serial;

  @override
  List<Object?> get props => [serial];
}
