import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:qrscanner/core/ocr/async_lock.dart';
import 'package:qrscanner/core/ocr/digit_confusion_corrector.dart';
import 'package:qrscanner/core/ocr/digit_sequence_parser.dart';
import 'package:qrscanner/core/ocr/models/ocr_models.dart';

/// Contract for on-device digit OCR engines.
abstract class DigitOcrEngine {
  Future<OcrDigitSequence?> recognizeDigits(
    File image, {
    required String label,
    required CardRegionKind regionKind,
  });

  Future<void> dispose();
}

/// ML Kit implementation with symbol-level confidence and numeric filtering.
class MlKitDigitOcrEngine implements DigitOcrEngine {
  MlKitDigitOcrEngine({TextRecognizer? recognizer})
    : _recognizer = recognizer ?? TextRecognizer(),
      _ownsRecognizer = recognizer == null;

  final TextRecognizer _recognizer;
  final bool _ownsRecognizer;
  final DigitSequenceParser _parser = const DigitSequenceParser();
  final AsyncLock _recognizerLock = AsyncLock();

  @override
  Future<OcrDigitSequence?> recognizeDigits(
    File image, {
    required String label,
    required CardRegionKind regionKind,
  }) async {
    return _recognizerLock.synchronized(() async {
      if (!_isReadableImage(image)) return null;

      try {
        final recognized = await _recognizer.processImage(
          InputImage.fromFilePath(image.absolute.path),
        );

        final symbolSequence = _extractSymbolSequence(
          recognized,
          regionKind: regionKind,
        );
        if (symbolSequence != null && symbolSequence.digits.isNotEmpty) {
          return symbolSequence.copyWithSource(label);
        }

        return _extractFromRawText(
          recognized.text,
          label: label,
          regionKind: regionKind,
        );
      } on PlatformException {
        return null;
      }
    });
  }

  bool _isReadableImage(File image) {
    try {
      return image.existsSync() && image.lengthSync() > 0;
    } on Object {
      return false;
    }
  }

  OcrDigitSequence? _extractSymbolSequence(
    RecognizedText recognized, {
    required CardRegionKind regionKind,
  }) {
    OcrDigitSequence? bestSequence;
    var bestScore = -1;

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final observations = <DigitObservation>[];
        final rawLine = line.text;

        for (final element in line.elements) {
          if (element.symbols.isNotEmpty) {
            for (final symbol in element.symbols) {
              _addSymbol(
                observations,
                symbol.text,
                symbol.confidence,
                symbol.boundingBox,
              );
            }
            continue;
          }

          final confidence = element.confidence ?? line.confidence ?? 0.65;
          for (final char in element.text.split('')) {
            _addSymbol(observations, char, confidence);
          }
        }

        if (observations.isEmpty) continue;

        final value = observations.map((d) => d.digit).join();
        final avgConfidence = observations
                .map((d) => d.confidence)
                .reduce((a, b) => a + b) /
            observations.length;

        final score = _scoreLine(
          value: value,
          rawLine: rawLine,
          avgConfidence: avgConfidence,
          regionKind: regionKind,
        );

        if (score > bestScore) {
          bestScore = score;
          bestSequence = OcrDigitSequence(
            value: value,
            averageConfidence: avgConfidence,
            digits: observations,
            sourceLabel: 'symbols',
          );
        }
      }
    }

    return bestSequence;
  }

  int _scoreLine({
    required String value,
    required String rawLine,
    required double avgConfidence,
    required CardRegionKind regionKind,
  }) {
    final normalized = rawLine.replaceAll(RegExp('[^0-9A-Za-z]'), '');
    final digitRatio = normalized.isEmpty
        ? 0.0
        : value.length / normalized.length;

    var score = (avgConfidence * 100).round();

    if (regionKind == CardRegionKind.pin) {
      if (value.length == 14) {
        score += 800;
      } else if (value.length >= 12) {
        score += 120;
      } else {
        score -= 300;
      }

      if (digitRatio < 0.85) score -= 250;
      if (_matchesPinGrouping(rawLine)) score += 180;
    } else {
      if (value.length == 12) {
        score += 500;
      } else if (value.length == 11) {
        score += 350;
      } else if (value.length == 10) {
        score += 200;
      }

      if (digitRatio < 0.70) score -= 150;
    }

    return score + value.length * 8;
  }

  bool _matchesPinGrouping(String rawLine) => RegExp(
    r'\d{4}[ \t-]*\d{3}[ \t-]*\d{4}[ \t-]*\d{3}',
  ).hasMatch(rawLine.replaceAll(RegExp('[^0-9 \t-]'), ''));

  void _addSymbol(
    List<DigitObservation> observations,
    String raw,
    double? confidence, [
    Rect? bounds,
  ]) {
    final digit = DigitConfusionCorrector.normalizeChar(raw);
    if (digit == null) return;

    observations.add(
      DigitObservation(
        digit: digit,
        confidence: confidence ?? 0.6,
        position: observations.length,
        bounds: bounds,
      ),
    );
  }

  OcrDigitSequence? _extractFromRawText(
    String text, {
    required String label,
    required CardRegionKind regionKind,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    final parsed = _parser.parse(trimmed);

    if (regionKind == CardRegionKind.pin) {
      final pin = parsed['pin'];
      if (pin != null && pin.length == 14) {
        return _sequenceFromValue(pin, label: label, confidence: 0.62);
      }
      return null;
    }

    final serial = parsed['serial'];
    if (serial != null && serial.length >= 10) {
      return _sequenceFromValue(serial, label: label, confidence: 0.62);
    }

    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10 && digits.length <= 12) {
      return _sequenceFromValue(digits, label: label, confidence: 0.55);
    }

    return null;
  }

  OcrDigitSequence _sequenceFromValue(
    String value, {
    required String label,
    required double confidence,
  }) => OcrDigitSequence(
    value: value,
    averageConfidence: confidence,
    digits: [
      for (var i = 0; i < value.length; i++)
        DigitObservation(digit: value[i], confidence: confidence, position: i),
    ],
    sourceLabel: label,
  );

  @override
  Future<void> dispose() async {
    if (_ownsRecognizer) {
      await _recognizer.close();
    }
  }
}

extension _OcrDigitSequenceCopy on OcrDigitSequence {
  OcrDigitSequence copyWithSource(String label) => OcrDigitSequence(
    value: value,
    averageConfidence: averageConfidence,
    digits: digits,
    sourceLabel: label,
  );
}
