part of 'extract_image_bloc.dart';

// ponytail: states for ExtractImageBloc
abstract class ExtractImageState extends Equatable {
  const ExtractImageState();

  @override
  List<Object?> get props => [];
}

class ExtractImageInitial extends ExtractImageState {}

class ImagePickedSuccess extends ExtractImageState {
  const ImagePickedSuccess({this.image});
  final File? image;

  @override
  List<Object?> get props => [image];
}

class ImagePickedError extends ExtractImageState {}

class Scanning extends ExtractImageState {}

class ScanSuccess extends ExtractImageState {}

class HistoryCountLoaded extends ExtractImageState {
  const HistoryCountLoaded({required this.count});
  final int count;

  @override
  List<Object?> get props => [count];
}

class ScanResultLoaded extends ExtractImageState {
  const ScanResultLoaded({
    this.pin,
    this.serial,
    this.pinDetected = false,
    this.serialDetected = false,
  });
  final String? pin;
  final String? serial;
  final bool pinDetected;
  final bool serialDetected;

  @override
  List<Object?> get props => [pin, serial, pinDetected, serialDetected];
}

class ScanError extends ExtractImageState {
  const ScanError({this.message});
  final String? message;

  @override
  List<Object?> get props => [message];
}

class SubmitLoading extends ExtractImageState {}

class ExtractImageLoading extends ExtractImageState {}

class ExtractImageSuccess extends ExtractImageState {}

class ExtractImageEmpty extends ExtractImageState {}

class ExtractImageRefreshing extends ExtractImageState {}
