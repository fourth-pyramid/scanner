import 'dart:io';

import 'package:equatable/equatable.dart';

/// States for ExtractImageCubit
abstract class ExtractImageState extends Equatable {
  const ExtractImageState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ExtractImageInitial extends ExtractImageState {}

/// Image picked successfully
class ImagePickedSuccess extends ExtractImageState {
  const ImagePickedSuccess({this.image});
  final File? image;

  @override
  List<Object?> get props => [image];
}

/// Image picking error
class ImagePickedError extends ExtractImageState {}

/// Scanning in progress
class Scanning extends ExtractImageState {}

/// Scan completed successfully
class ScanSuccess extends ExtractImageState {}

/// History count loaded
class HistoryCountLoaded extends ExtractImageState {
  const HistoryCountLoaded({required this.count});
  final int count;

  @override
  List<Object?> get props => [count];
}

/// Scan result with extracted data
class ScanResultLoaded extends ExtractImageState {
  const ScanResultLoaded({
    this.pin,
    this.serial,
    this.pinCroppedImage,
    this.serialCroppedImage,
    this.pinDetected = false,
    this.serialDetected = false,
  });
  final String? pin;
  final String? serial;
  final File? pinCroppedImage;
  final File? serialCroppedImage;
  final bool pinDetected;
  final bool serialDetected;

  @override
  List<Object?> get props => [
    pin,
    serial,
    pinCroppedImage,
    serialCroppedImage,
    pinDetected,
    serialDetected,
  ];
}

/// Scan error
class ScanError extends ExtractImageState {
  const ScanError({this.message});
  final String? message;

  @override
  List<Object?> get props => [message];
}

/// Submit loading state
class SubmitLoading extends ExtractImageState {}
