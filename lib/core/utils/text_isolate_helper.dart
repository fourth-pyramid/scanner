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
    } catch (e) {
      return {'pin': null, 'serial': null};
    }
  }

  /// Internal function that runs in isolate
  static Map<String, String?> _extractNumbers(String text) {
    try {
      // Same regex logic as the original implementation
      final RegExp regExp = RegExp(r'\d(?:[ \t]*\d){11,}');
      final Iterable<RegExpMatch> matches = regExp.allMatches(text);

      String? foundPin;
      String? foundSerial;

      for (final match in matches) {
        final String rawValue = match.group(0)!;
        final String cleanValue = rawValue.replaceAll(RegExp(r'\s+'), '');

        if (cleanValue.length == 14) {
          foundPin = cleanValue;
        } else if (cleanValue.length == 12) {
          foundSerial = cleanValue;
        }
      }

      return {'pin': foundPin, 'serial': foundSerial};
    } catch (e) {
      return {'pin': null, 'serial': null};
    }
  }
}
