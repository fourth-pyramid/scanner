import 'dart:io';

import 'package:equatable/equatable.dart';

/// Entity representing extracted card data from image
/// Pure Dart - no external dependencies
class CardData extends Equatable {
  const CardData({
    this.pin,
    this.serial,
    this.originalImage,
    this.pinCroppedImage,
    this.serialCroppedImage,
    this.pinDetected = false,
    this.serialDetected = false,
  });
  final String? pin;
  final String? serial;
  final File? originalImage;
  final File? pinCroppedImage;
  final File? serialCroppedImage;
  final bool pinDetected;
  final bool serialDetected;

  @override
  List<Object?> get props => [
    pin,
    serial,
    originalImage,
    pinCroppedImage,
    serialCroppedImage,
    pinDetected,
    serialDetected,
  ];

  CardData copyWith({
    String? pin,
    String? serial,
    File? originalImage,
    File? pinCroppedImage,
    File? serialCroppedImage,
    bool? pinDetected,
    bool? serialDetected,
  }) => CardData(
    pin: pin ?? this.pin,
    serial: serial ?? this.serial,
    originalImage: originalImage ?? this.originalImage,
    pinCroppedImage: pinCroppedImage ?? this.pinCroppedImage,
    serialCroppedImage: serialCroppedImage ?? this.serialCroppedImage,
    pinDetected: pinDetected ?? this.pinDetected,
    serialDetected: serialDetected ?? this.serialDetected,
  );
}
