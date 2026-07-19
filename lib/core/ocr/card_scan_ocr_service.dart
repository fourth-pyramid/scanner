import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

// ponytail: combined all ocr utility, service, and engine classes into one file for simplicity.

/// Ensures async critical sections run one at a time.
class AsyncLock {
  Future<void> _tail = Future.value();

  Future<T> synchronized<T>(Future<T> Function() action) {
    final completer = Completer<void>();
    final previous = _tail;
    _tail = completer.future;

    return previous.then((_) => action()).whenComplete(completer.complete);
  }
}

/// Mistral OCR engine connecting to the Mistral AI OCR API.
class MistralOcrEngine {
  MistralOcrEngine({Dio? dio})
    : _dio =
          dio ??
          Dio(BaseOptions(connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 30)));

  final Dio _dio;

  // ponytail: placeholder for user to fill in their Mistral API Key
  static const String _mistralApiKey = 'TGlou8530ObxFBInO8YMdJ7DSGmkr29g';
  static const String _ocrEndpoint = 'https://api.mistral.ai/v1/ocr';

  bool _isReadableImage(File image) {
    try {
      return image.existsSync() && image.lengthSync() > 0;
    } on Object {
      return false;
    }
  }

  Future<void> dispose() async {}

  /// Recognize both PIN (14 digits) and Serial (12 digits) from full card image using Mistral OCR.
  Future<({String? pin, String? serial})?> recognizeCard(File image) async {
    if (!_isReadableImage(image)) return null;

    try {
      final bytes = await image.readAsBytes();
      final base64Str = base64Encode(bytes);
      final extension = p.extension(image.path).toLowerCase();
      final mimeType = extension == '.png' ? 'image/png' : 'image/jpeg';
      final dataUrl = 'data:$mimeType;base64,$base64Str';

      developer.log('MistralOCR recognizeCard posting to: $_ocrEndpoint', name: 'OCR_ENGINE');
      final response = await _dio.post<Map<String, dynamic>>(
        _ocrEndpoint,
        data: {
          'model': 'mistral-ocr-latest',
          'document': {'type': 'image_url', 'image_url': dataUrl},
        },
        options: Options(headers: {'Authorization': 'Bearer $_mistralApiKey', 'Content-Type': 'application/json'}),
      );

      final data = response.data;
      if (data == null) return null;

      final pages = data['pages'] as List<dynamic>? ?? const [];
      String? pin;
      String? serial;

      // Normalizes Eastern Arabic/Persian digits to standard Western Arabic (0-9)
      String normalizeDigits(String text) {
        const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
        const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '٩'];
        var normalized = text;
        for (var i = 0; i < 10; i++) {
          normalized = normalized.replaceAll(arabicDigits[i], '$i');
          normalized = normalized.replaceAll(persianDigits[i], '$i');
        }
        return normalized;
      }

      String? cleanPinCandidate(String digits) {
        if (digits.length == 14) {
          return digits;
        }
        return null;
      }

      String? cleanSerialCandidate(String digits) {
        // Serial is always 12 digits, typically starting with '103' or '60000'
        if (digits.length == 12) {
          if (digits.startsWith('103') || digits.startsWith('60000')) {
            return digits;
          }
          return digits; // Fallback if no prefix matches
        }
        
        // Handle common OCR noise cases (e.g. adding 1 at the start or end of the serial)
        if (digits.length == 13) {
          if (digits.startsWith('1103') || digits.startsWith('160000')) {
            return digits.substring(1);
          }
          if (digits.endsWith('1') && (digits.startsWith('60000') || digits.startsWith('103'))) {
            return digits.substring(0, 12);
          }
          // Default trim if it starts with 1 and looks like Zain serial
          if (digits.startsWith('1') && (digits.substring(1).startsWith('103') || digits.substring(1).startsWith('60000'))) {
            return digits.substring(1);
          }
        }
        
        if (digits.length == 14) {
          // If starts and ends with '1' and middle is a valid serial
          if (digits.startsWith('1') && digits.endsWith('1')) {
            final middle = digits.substring(1, 13);
            if (middle.startsWith('103') || middle.startsWith('60000')) {
              return middle;
            }
          }
        }
        return null;
      }

      for (final page in pages) {
        final pageMap = page as Map<String, dynamic>;
        final rawMarkdown = pageMap['markdown'] as String? ?? '';
        final markdown = normalizeDigits(rawMarkdown);

        developer.log('MistralOCR markdown output:\n$markdown', name: 'OCR_ENGINE');

        // Extract using regex sequences of digits (with spaces or dashes)
        final regex = RegExp(r'\d+(?:[\s\-]\d+)+|\d{10,}');
        for (final match in regex.allMatches(markdown)) {
          final text = match.group(0)!;
          final digits = text.replaceAll(RegExp(r'\D'), '');
          
          final pCandidate = cleanPinCandidate(digits);
          if (pCandidate != null) pin = pCandidate;

          final sCandidate = cleanSerialCandidate(digits);
          if (sCandidate != null) serial = sCandidate;
        }

        // If not found yet, try line-by-line strategy
        if (pin == null || serial == null) {
          final lines = markdown.split('\n');
          for (final line in lines) {
            final lineDigits = line.replaceAll(RegExp(r'\D'), '');
            
            final pCandidate = cleanPinCandidate(lineDigits);
            if (pCandidate != null) pin ??= pCandidate;

            final sCandidate = cleanSerialCandidate(lineDigits);
            if (sCandidate != null) serial ??= sCandidate;
          }
        }

        if (pin != null && serial != null) break;
      }

      return (pin: pin, serial: serial);
    } on DioException catch (e) {
      developer.log('MistralOCR recognizeCard DioError: ${e.message}, response: ${e.response}', name: 'OCR_ENGINE');
      return null;
    } on Object catch (e) {
      developer.log('MistralOCR recognizeCard generic error: $e', name: 'OCR_ENGINE');
      return null;
    }
  }
}

/// Builds OCR engines tuned for speed vs accuracy per field.
class OcrEngineFactory {
  OcrEngineFactory._();

  /// PIN: MistralOCR
  static MistralOcrEngine createPinEngine() => MistralOcrEngine();
}

/// Fast, accurate on-device OCR pipeline for STC recharge cards.
class CardScanOcrService {
  CardScanOcrService({required MistralOcrEngine pinOcrEngine}) : _pinEngine = pinOcrEngine;

  final MistralOcrEngine _pinEngine;
  final AsyncLock _scanLock = AsyncLock();

  Future<CardScanOcrResult> scan(File imageFile) => _scanLock.synchronized(() => _scanInternal(imageFile));

  Future<CardScanOcrResult> _scanInternal(File imageFile) async {
    // ponytail: no enhancement, send image directly to OCR
    final result = await _pinEngine.recognizeCard(imageFile);
    return CardScanOcrResult(
      pin: result?.pin,
      serial: result?.serial,
      pinConfidence: result?.pin != null ? 0.9 : 0.0,
      serialConfidence: result?.serial != null ? 0.9 : 0.0,
      pinDetected: result?.pin != null,
      serialDetected: result?.serial != null,
      workingImage: imageFile,
    );
  }
}

class CardScanOcrResult {
  const CardScanOcrResult({
    required this.pin,
    required this.serial,
    required this.pinConfidence,
    required this.serialConfidence,
    required this.pinDetected,
    required this.serialDetected,
    required this.workingImage,
  });

  final String? pin;
  final String? serial;
  final double pinConfidence;
  final double serialConfidence;
  final bool pinDetected;
  final bool serialDetected;
  final File workingImage;
}
