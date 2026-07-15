import 'package:qrscanner/core/ocr/digit_confusion_corrector.dart';
import 'package:qrscanner/core/ocr/digit_sequence_parser.dart';

/// Strict RegEx extraction for 14-digit PIN and 12-digit serial from OCR text.
class LiveCardCodeExtractor {
  const LiveCardCodeExtractor({DigitSequenceParser? parser})
    : _parser = parser ?? const DigitSequenceParser();

  final DigitSequenceParser _parser;

  /// PIN grouped as 4-3-4-3 with optional separators.
  static final RegExp pinGrouped = RegExp(
    r'(?:\D|^)(\d{4})\D{0,4}(\d{3})\D{0,4}(\d{4})\D{0,4}(\d{3})(?:\D|$)',
  );

  /// Any contiguous 14-digit run.
  static final RegExp pinDigits = RegExp(r'(?<!\d)(\d{14})(?!\d)');

  /// Any contiguous 12-digit run.
  static final RegExp serialDigits = RegExp(r'(?<!\d)(\d{12})(?!\d)');

  /// Extract both codes; returns null for either field when not found.
  ({String? pin, String? serial}) extractPair(String text) {
    final pin = extractPin(text);
    final serial = extractSerial(text, excludePin: pin);
    return (pin: pin, serial: serial);
  }

  String? extractPin(String text) {
    final normalized = _normalizeOcrText(text);

    final grouped = pinGrouped.firstMatch(normalized);
    if (grouped != null) {
      final value =
          '${grouped.group(1)}${grouped.group(2)}${grouped.group(3)}${grouped.group(4)}';
      if (value.length == 14) return value;
    }

    final parsed = _parser.parse(normalized);
    final fromParser = parsed['pin'];
    if (fromParser != null && fromParser.length == 14) return fromParser;

    final digits = _digitsFromOcr(normalized);
    final direct = pinDigits.firstMatch(digits);
    return direct?.group(1);
  }

  String? extractSerial(String text, {String? excludePin}) {
    final normalized = _normalizeOcrText(text);

    final parsed = _parser.parse(normalized);
    final fromParser = parsed['serial'];
    if (fromParser != null &&
        fromParser.length == 12 &&
        fromParser != excludePin) {
      return fromParser;
    }

    final digits = _digitsFromOcr(normalized);
    for (final match in serialDigits.allMatches(digits)) {
      final value = match.group(1)!;
      if (value == excludePin) continue;
      if (value.length == 12) return value;
    }

    return null;
  }

  String _normalizeOcrText(String text) {
    const arabicDigits = <String, String>{
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
      '۰': '0', '۱': '1', '۲': '2', '۳': '3', '۴': '4',
      '۵': '5', '۶': '6', '۷': '7', '۸': '8', '۹': '9',
    };
    var out = text;
    for (final entry in arabicDigits.entries) {
      out = out.replaceAll(entry.key, entry.value);
    }
    return out;
  }

  String _digitsFromOcr(String text) {
    final buffer = StringBuffer();
    for (final rune in text.toUpperCase().runes) {
      final ch = String.fromCharCode(rune);
      if (RegExp(r'\d').hasMatch(ch)) {
        buffer.write(ch);
        continue;
      }
      final digit = DigitConfusionCorrector.normalizeChar(ch);
      if (digit != null) buffer.write(digit);
    }
    return buffer.toString();
  }

  String formatPin(String pin14) => _parser.formatPin(pin14);
}
