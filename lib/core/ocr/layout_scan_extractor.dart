import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:qrscanner/core/ocr/digit_sequence_parser.dart';
import 'package:qrscanner/core/ocr/models/ocr_models.dart';

/// Extracts PIN/serial candidates from the full-card layout scan at zero extra cost.
class LayoutScanExtractor {
  const LayoutScanExtractor({DigitSequenceParser? parser})
    : _parser = parser ?? const DigitSequenceParser();

  final DigitSequenceParser _parser;

  OcrDigitSequence? extractPin(RecognizedText recognizedText) =>
      _extractForRegion(
        recognizedText,
        minRelativeY: 0.14,
        maxRelativeY: 0.55,
        expectedLengths: const [14],
        label: 'layout_pin',
      );

  OcrDigitSequence? extractSerial(RecognizedText recognizedText) =>
      _extractForRegion(
        recognizedText,
        minRelativeY: 0.65,
        maxRelativeY: 1.0,
        expectedLengths: const [10, 11, 12],
        label: 'layout_serial',
      );

  OcrDigitSequence? _extractForRegion(
    RecognizedText recognizedText, {
    required double minRelativeY,
    required double maxRelativeY,
    required List<int> expectedLengths,
    required String label,
  }) {
    final imageHeight = _estimateImageHeight(recognizedText);
    if (imageHeight <= 0) return null;

    OcrDigitSequence? best;
    var bestScore = -1;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final box = line.boundingBox;
        final centerY = box.top + box.height / 2;
        final relativeY = centerY / imageHeight;
        if (relativeY < minRelativeY || relativeY > maxRelativeY) continue;

        final parsed = _parser.parse(line.text);
        final pin = parsed['pin'];
        final serial = parsed['serial'];
        final value = expectedLengths.contains(pin?.length ?? -1)
            ? pin
            : expectedLengths.contains(serial?.length ?? -1)
            ? serial
            : null;

        if (value == null) continue;

        final digits = value.replaceAll(RegExp(r'\D'), '');
        if (!expectedLengths.contains(digits.length)) continue;

        final confidence = line.confidence ?? 0.68;
        var score = digits.length * 10 + (confidence * 100).round();
        if (digits.length == expectedLengths.last) score += 50;

        if (score > bestScore) {
          bestScore = score;
          best = OcrDigitSequence(
            value: digits,
            averageConfidence: confidence,
            digits: [
              for (var i = 0; i < digits.length; i++)
                DigitObservation(
                  digit: digits[i],
                  confidence: confidence,
                  position: i,
                ),
            ],
            sourceLabel: label,
          );
        }
      }
    }

    return best;
  }

  double _estimateImageHeight(RecognizedText recognizedText) {
    var maxBottom = 0.0;
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final bottom = line.boundingBox.bottom;
        if (bottom > maxBottom) maxBottom = bottom;
      }
    }
    return maxBottom <= 0 ? 1 : maxBottom * 1.05;
  }
}
