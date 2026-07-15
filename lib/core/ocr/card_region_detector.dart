import 'dart:math' as math;
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:qrscanner/core/ocr/models/ocr_models.dart';

/// Detects PIN and serial regions using ML Kit layout hints with STC template fallbacks.
class CardRegionDetector {
  /// STC PIN sits below the card header — not in the top branding strip.
  static const _pinTemplate = _RegionTemplate(
    left: 0.06,
    top: 0.24,
    width: 0.88,
    height: 0.14,
    minRelativeY: 0.18,
    maxRelativeY: 0.48,
    expectedMinLength: 12,
    preferredLength: 14,
    minDigitRatio: 0.85,
  );

  /// Alternate PIN zones tried when the primary crop misses the code.
  static const _pinFallbackTemplates = <_RegionTemplate>[
    _RegionTemplate(
      left: 0.06,
      top: 0.32,
      width: 0.88,
      height: 0.14,
      minRelativeY: 0.28,
      maxRelativeY: 0.55,
      expectedMinLength: 12,
      preferredLength: 14,
      minDigitRatio: 0.85,
    ),
    _RegionTemplate(
      left: 0.06,
      top: 0.18,
      width: 0.88,
      height: 0.12,
      minRelativeY: 0.14,
      maxRelativeY: 0.35,
      expectedMinLength: 12,
      preferredLength: 14,
      minDigitRatio: 0.85,
    ),
  ];

  static const _serialTemplate = _RegionTemplate(
    left: 0.08,
    top: 0.78,
    width: 0.84,
    height: 0.18,
    minRelativeY: 0.70,
    maxRelativeY: 1.0,
    expectedMinLength: 10,
    preferredLength: 12,
    minDigitRatio: 0.70,
  );

  List<Rect> pinFallbackRects(double imageWidth, double imageHeight) =>
      _pinFallbackTemplates
          .map((template) => template.toRect(imageWidth, imageHeight))
          .toList();

  CardRegion detectPinRegion({
    required RecognizedText recognizedText,
    required double imageWidth,
    required double imageHeight,
  }) {
    final templateRect = _pinTemplate.toRect(imageWidth, imageHeight);
    final detection = _detectFromText(
      recognizedText: recognizedText,
      imageHeight: imageHeight,
      template: _pinTemplate,
    );

    final useAutoBox = detection != null && detection.isDigitHeavy;
    final box = useAutoBox ? detection.box : templateRect;

    return CardRegion(
      box: _addPadding(box, imageWidth, imageHeight, 0.15),
      kind: CardRegionKind.pin,
      detectedAutomatically: useAutoBox,
    );
  }

  CardRegion detectSerialRegion({
    required RecognizedText recognizedText,
    required double imageWidth,
    required double imageHeight,
  }) {
    final templateRect = _serialTemplate.toRect(imageWidth, imageHeight);
    final detection = _detectFromText(
      recognizedText: recognizedText,
      imageHeight: imageHeight,
      template: _serialTemplate,
    );

    final useAutoBox = detection != null && detection.isDigitHeavy;
    final box = useAutoBox ? detection.box : templateRect;

    return CardRegion(
      box: _addPadding(box, imageWidth, imageHeight, 0.15),
      kind: CardRegionKind.serial,
      detectedAutomatically: useAutoBox,
    );
  }

  _TextLineDetection? _detectFromText({
    required RecognizedText recognizedText,
    required double imageHeight,
    required _RegionTemplate template,
  }) {
    _TextLineDetection? selected;
    var bestScore = -1.0;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final raw = line.text;
        final digits = raw.replaceAll(RegExp(r'\D'), '');
        final normalized = raw.replaceAll(RegExp('[^0-9A-Za-z]'), '');
        if (digits.length < template.expectedMinLength) continue;
        if (normalized.isEmpty) continue;

        final digitRatio = digits.length / normalized.length;
        if (digitRatio < template.minDigitRatio) continue;

        final box = line.boundingBox;
        final centerY = box.top + box.height / 2;
        final relativeY = centerY / imageHeight;
        if (relativeY < template.minRelativeY ||
            relativeY > template.maxRelativeY) {
          continue;
        }

        var score = digits.length.toDouble();
        if (digits.length == template.preferredLength) {
          score += 200;
        }

        score += digitRatio * 80;

        final aspect = box.width / math.max(box.height, 1);
        if (aspect > 4) score += 25;

        if (line.confidence != null) {
          score += line.confidence! * 30;
        }

        if (score > bestScore) {
          bestScore = score;
          selected = _TextLineDetection(
            box: box,
            digitRatio: digitRatio,
            digitCount: digits.length,
          );
        }
      }
    }

    return selected;
  }

  Rect _addPadding(
    Rect box,
    double imgWidth,
    double imgHeight,
    double paddingPercent,
  ) {
    final padX = box.width * paddingPercent;
    final padY = box.height * paddingPercent;
    final left = (box.left - padX).clamp(0.0, imgWidth);
    final top = (box.top - padY).clamp(0.0, imgHeight);
    return Rect.fromLTWH(
      left,
      top,
      (box.width + padX * 2).clamp(0.0, imgWidth - left),
      (box.height + padY * 2).clamp(0.0, imgHeight - top),
    );
  }

}

class _RegionTemplate {
  const _RegionTemplate({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.minRelativeY,
    required this.maxRelativeY,
    required this.expectedMinLength,
    required this.preferredLength,
    required this.minDigitRatio,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double minRelativeY;
  final double maxRelativeY;
  final int expectedMinLength;
  final int preferredLength;
  final double minDigitRatio;

  Rect toRect(double imageWidth, double imageHeight) => Rect.fromLTWH(
    imageWidth * left,
    imageHeight * top,
    imageWidth * width,
    imageHeight * height,
  );
}

class _TextLineDetection {
  const _TextLineDetection({
    required this.box,
    required this.digitRatio,
    required this.digitCount,
  });

  final Rect box;
  final double digitRatio;
  final int digitCount;

  bool get isDigitHeavy => digitRatio >= 0.80 && digitCount >= 10;
}
