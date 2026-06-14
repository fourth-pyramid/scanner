import 'package:flutter/foundation.dart';

// ignore: avoid_classes_with_only_static_members
/// Helper class for text processing operations in isolates
class TextIsolateHelper {
  /// Extract numbers (PIN and Serial) from OCR text in a separate isolate
  /// Returns a map with 'pin' and 'serial' keys
  static Future<Map<String, String?>> extractNumbersInIsolate(
    String text,
  ) async {
    try {
      // Run extraction in isolate using compute
      final result = await compute(_extractNumbers, text);
      return result;
    } on Object catch (_) {
      return {'pin': null, 'serial': null};
    }
  }

  /// Internal function that runs in isolate
  static Map<String, String?> _extractNumbers(String text) {
    try {
      // Normalize Arabic digits and keep only numeric candidates.
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

      // Try strict PIN pattern first: 4-3-4-3 (with optional separators)
      final strictPin = _extractStrictPinPattern(normalizedText);
      if (strictPin != null) {
        candidates.insert(0, strictPin);
      }

      // Remove duplicates while preserving order
      final uniqueCandidates = <String>[];
      for (final c in candidates) {
        if (!uniqueCandidates.contains(c)) {
          uniqueCandidates.add(c);
        }
      }

      String? foundPin;
      String? foundSerial;

      // PIN غالبا 14 رقم
      for (final candidate in uniqueCandidates) {
        if (candidate.length == 14) {
          foundPin = candidate;
          break;
        }
      }

      foundSerial = _pickBestSerialCandidate(uniqueCandidates, foundPin);

      // لا نستخدم fallback للـ PIN حتى لا نملأه برقم خاطئ.
      // PIN يجب أن يكون 14 رقم فقط (صيغة 4-3-4-3).

      return <String, String?>{'pin': foundPin, 'serial': foundSerial};
    } on Object catch (_) {
      return {'pin': null, 'serial': null};
    }
  }

  static String _normalizeDigits(String text) {
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
    arabicDigits.forEach((k, v) {
      normalized = normalized.replaceAll(k, v);
    });
    return normalized;
  }

  // Conservative digit normalization:
  // 1) Prefer already-recognized digits as-is.
  // 2) Apply only low-risk substitutions.
  // 3) Apply ambiguous substitutions (S/G) only as a fallback.
  static String _normalizePotentialDigits(String token) {
    final upper = token.toUpperCase();
    final digitsOnly = upper.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 10) {
      return digitsOnly;
    }

    final lowRisk = StringBuffer();
    for (final rune in upper.runes) {
      final ch = String.fromCharCode(rune);
      switch (ch) {
        case 'O':
        case 'Q':
        case 'D':
          lowRisk.write('0');
          break;
        case 'I':
        case 'L':
        case '|':
        case '!':
          lowRisk.write('1');
          break;
        case 'Z':
          lowRisk.write('2');
          break;
        case 'B':
          lowRisk.write('8');
          break;
        default:
          if (RegExp(r'\d').hasMatch(ch)) lowRisk.write(ch);
      }
    }
    final lowRiskValue = lowRisk.toString();
    if (lowRiskValue.length >= 10) {
      return lowRiskValue;
    }

    // Fallback only when needed: include ambiguous OCR substitutions.
    final withAmbiguous = StringBuffer();
    for (final rune in upper.runes) {
      final ch = String.fromCharCode(rune);
      switch (ch) {
        case 'S':
          withAmbiguous.write('5');
          break;
        case 'G':
          withAmbiguous.write('6');
          break;
        default:
          if (RegExp(r'\d').hasMatch(ch)) {
            withAmbiguous.write(ch);
          } else {
            // reuse low-risk mapping for remaining chars
            final mapped = _mapLowRiskChar(ch);
            if (mapped != null) withAmbiguous.write(mapped);
          }
      }
    }

    return withAmbiguous.toString();
  }

  static String? _mapLowRiskChar(String ch) {
    switch (ch) {
      case 'O':
      case 'Q':
      case 'D':
        return '0';
      case 'I':
      case 'L':
      case '|':
      case '!':
        return '1';
      case 'Z':
        return '2';
      case 'B':
        return '8';
      default:
        return null;
    }
  }

  static String? _extractStrictPinPattern(String text) {
    final pinPattern = RegExp(
      r'([0-9A-Za-z]{4})[ \t\-]*([0-9A-Za-z]{3})[ \t\-]*([0-9A-Za-z]{4})[ \t\-]*([0-9A-Za-z]{3})',
    );
    final m = pinPattern.firstMatch(text);
    if (m == null) return null;

    final raw = '${m.group(1)}${m.group(2)}${m.group(3)}${m.group(4)}';
    final normalized = _normalizePotentialDigits(raw);
    return normalized.length == 14 ? normalized : null;
  }

  static String? _pickBestSerialCandidate(
    List<String> candidates,
    String? foundPin,
  ) {
    final serialCandidates = candidates.where((c) {
      if (c == foundPin) return false;
      return c.length == 10 || c.length == 11 || c.length == 12;
    }).toList();

    if (serialCandidates.isEmpty) return null;

    int score(String v) {
      var s = 0;

      // Favor common serial lengths: 12 > 11 > 10
      if (v.length == 12) {
        s += 300;
      } else if (v.length == 11) {
        s += 200;
      } else {
        s += 100;
      }

      // Penalize suspicious "00..." short values that often come from OCR noise
      if (v.length <= 10 && v.startsWith('00')) {
        s -= 120;
      }

      // Prefer candidates with more digit variety (less likely OCR artifacts)
      return s + v.split('').toSet().length * 5;
    }

    serialCandidates.sort((a, b) => score(b).compareTo(score(a)));
    return serialCandidates.first;
  }
}
