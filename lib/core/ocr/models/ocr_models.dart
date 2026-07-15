import 'dart:ui';

/// A single digit observation from one OCR pass.
class DigitObservation {
  const DigitObservation({
    required this.digit,
    required this.confidence,
    required this.position,
    this.bounds,
  });

  final String digit;
  final double confidence;
  final int position;
  final Rect? bounds;
}

/// A full numeric sequence recognized in one OCR pass.
class OcrDigitSequence {
  const OcrDigitSequence({
    required this.value,
    required this.averageConfidence,
    required this.digits,
    required this.sourceLabel,
  });

  final String value;
  final double averageConfidence;
  final List<DigitObservation> digits;
  final String sourceLabel;

  bool get isHighConfidence => averageConfidence >= 0.88 && value.isNotEmpty;
}

/// Axis-aligned crop region for a card code field.
class CardRegion {
  const CardRegion({
    required this.box,
    required this.kind,
    required this.detectedAutomatically,
  });

  final Rect box;
  final CardRegionKind kind;
  final bool detectedAutomatically;
}

enum CardRegionKind { pin, serial }

/// Prepared image assets for one code region.
class PreparedRegionAssets {
  const PreparedRegionAssets({
    required this.basePath,
    required this.variantPaths,
  });

  factory PreparedRegionAssets.fromMap(Map<String, dynamic> map) =>
      PreparedRegionAssets(
        basePath: map['basePath'] as String,
        variantPaths: List<String>.from(map['variantPaths'] as List),
      );

  final String basePath;
  final List<String> variantPaths;

  Map<String, dynamic> toMap() => {
    'basePath': basePath,
    'variantPaths': variantPaths,
  };
}

/// Full prepared scan assets for PIN and serial regions.
class PreparedScanAssets {
  const PreparedScanAssets({
    required this.pin,
    required this.serial,
    required this.pinDetectedAutomatically,
    required this.serialDetectedAutomatically,
  });

  final PreparedRegionAssets pin;
  final PreparedRegionAssets serial;
  final bool pinDetectedAutomatically;
  final bool serialDetectedAutomatically;
}

/// Integer crop box used across isolate boundaries.
class ScanCropBox {
  const ScanCropBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  factory ScanCropBox.fromMap(Map<String, int> map) => ScanCropBox(
    left: map['left'] ?? 0,
    top: map['top'] ?? 0,
    width: map['width'] ?? 1,
    height: map['height'] ?? 1,
  );

  factory ScanCropBox.fromRect(Rect rect) => ScanCropBox(
    left: rect.left.toInt(),
    top: rect.top.toInt(),
    width: rect.width.toInt(),
    height: rect.height.toInt(),
  );

  final int left;
  final int top;
  final int width;
  final int height;

  Rect toRect() => Rect.fromLTWH(
    left.toDouble(),
    top.toDouble(),
    width.toDouble(),
    height.toDouble(),
  );

  Map<String, int> toMap() => {
    'left': left,
    'top': top,
    'width': width,
    'height': height,
  };
}

/// Result of scanning a single code region.
class RegionScanResult {
  const RegionScanResult({
    required this.value,
    required this.confidence,
    required this.detected,
  });

  final String? value;
  final double confidence;
  final bool detected;
}
