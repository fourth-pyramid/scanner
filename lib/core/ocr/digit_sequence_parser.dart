import 'package:qrscanner/core/ocr/digit_confusion_corrector.dart';

/// Parses OCR text into strict PIN (14-digit) and serial candidates.
class DigitSequenceParser {
  const DigitSequenceParser();

  Map<String, String?> parse(String text) {
    try {
      final normalizedText = _normalizeDigits(text);
      final regExp = RegExp(r'[0-9A-Za-z](?:[ \t\-]*[0-9A-Za-z]){8,}');
      final matches = regExp.allMatches(normalizedText);

      final candidates = <String>[];
      for (final match in matches) {
        final rawValue = match.group(0)!;
        final cleanValue = _normalizePotentialDigits(rawValue);
        if (cleanValue.length >= 10 && cleanValue.length <= 16) {
          candidates.add(cleanValue);
        }
      }

      final strictPin = _extractStrictPinPattern(normalizedText);
      if (strictPin != null) {
        candidates.insert(0, strictPin);
      }

      final uniqueCandidates = <String>[];
      for (final candidate in candidates) {
        if (!uniqueCandidates.contains(candidate)) {
          uniqueCandidates.add(candidate);
        }
      }

      String? foundPin;
      for (final candidate in uniqueCandidates) {
        if (candidate.length == 14) {
          foundPin = candidate;
          break;
        }
      }

      final foundSerial = _pickBestSerialCandidate(uniqueCandidates, foundPin);

      return {'pin': foundPin, 'serial': foundSerial};
    } on Object {
      return {'pin': null, 'serial': null};
    }
  }

  String _normalizeDigits(String text) {
    const arabicDigits = <String, String>{
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
    };

    var normalized = text;
    for (final entry in arabicDigits.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized;
  }

  String _normalizePotentialDigits(String token) {
    final upper = token.toUpperCase();
    final digitsOnly = upper.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 10) return digitsOnly;

    final buffer = StringBuffer();
    for (final rune in upper.runes) {
      final ch = String.fromCharCode(rune);
      final digit = DigitConfusionCorrector.normalizeChar(ch);
      if (digit != null) buffer.write(digit);
    }

    return buffer.toString();
  }

  String? _extractStrictPinPattern(String text) {
    final pinPattern = RegExp(
      r'([0-9A-Za-z]{4})[ \t\-]*([0-9A-Za-z]{3})[ \t\-]*([0-9A-Za-z]{4})[ \t\-]*([0-9A-Za-z]{3})',
    );
    final match = pinPattern.firstMatch(text);
    if (match == null) return null;

    final raw =
        '${match.group(1)}${match.group(2)}${match.group(3)}${match.group(4)}';
    final normalized = _normalizePotentialDigits(raw);
    return normalized.length == 14 ? normalized : null;
  }

  String? _pickBestSerialCandidate(
    List<String> candidates,
    String? foundPin,
  ) {
    final serialCandidates = candidates.where((candidate) {
      if (candidate == foundPin) return false;
      return candidate.length == 10 ||
          candidate.length == 11 ||
          candidate.length == 12;
    }).toList();

    if (serialCandidates.isEmpty) return null;

    int score(String value) {
      var result = 0;
      if (value.length == 12) {
        result += 300;
      } else if (value.length == 11) {
        result += 200;
      } else {
        result += 100;
      }

      if (value.length <= 10 && value.startsWith('00')) {
        result -= 120;
      }

      return result + value.split('').toSet().length * 5;
    }

    serialCandidates.sort((a, b) => score(b).compareTo(score(a)));
    return serialCandidates.first;
  }

  String formatPin(String number) {
    if (number.length != 14) return number;
    return '${number.substring(0, 4)} ${number.substring(4, 7)} ${number.substring(7, 11)} ${number.substring(11, 14)}';
  }
}
