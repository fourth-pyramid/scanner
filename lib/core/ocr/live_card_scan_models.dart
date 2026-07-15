import 'dart:io';

/// Result returned when PIN and serial are read from the same camera frame.
class LiveCardScanResult {
  const LiveCardScanResult({
    required this.pin,
    required this.serial,
    required this.pinRaw,
    required this.serialRaw,
    required this.cardImage,
    required this.pinCropImage,
    required this.serialCropImage,
  });

  final String pin;
  final String serial;
  final String pinRaw;
  final String serialRaw;
  final File cardImage;
  final File pinCropImage;
  final File serialCropImage;
}

/// Normalized ROI layout — matches the centered card overlay on camera preview.
class CardRoiLayout {
  CardRoiLayout._();

  /// Centered square card frame as fraction of the image (matches UI overlay).
  static const cardSizeFraction = 0.70;

  /// PIN zone inside the card crop (STC template).
  static const pinLeft = 0.06;
  static const pinTop = 0.24;
  static const pinWidth = 0.88;
  static const pinHeight = 0.14;

  /// Serial zone inside the card crop.
  static const serialLeft = 0.08;
  static const serialTop = 0.78;
  static const serialWidth = 0.84;
  static const serialHeight = 0.18;

  static const upscaleFactor = 2.0;
}
