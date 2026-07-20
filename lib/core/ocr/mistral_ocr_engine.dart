import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:qrscanner/core/ocr/card_digit_extractor.dart';
import 'package:qrscanner/core/ocr/ocr_logger.dart';

/// Mistral OCR engine connecting to the Mistral AI OCR API.
class MistralOcrEngine {
  MistralOcrEngine({Dio? dio, CardDigitExtractor? extractor})
    : _dio =
          dio ??
          Dio(BaseOptions(connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 30))),
      _extractor = extractor ?? const CardDigitExtractor();

  final Dio _dio;
  final CardDigitExtractor _extractor;

  // ponytail: placeholder API key — move this to `--dart-define` or a secure
  // secrets manager before shipping. Hardcoded keys in source are a leak risk.
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

  /// Recognizes both PIN (14 digits) and Serial (12 digits) from a full card
  /// image using Mistral OCR. [image] should already be preprocessed.
  Future<({String? pin, String? serial, String? pinGuess, String? serialGuess})?> recognizeCard(File image) async {
    if (!_isReadableImage(image)) {
      logOcr('❌ Image not readable, aborting', name: 'OCR_ENGINE');
      return null;
    }

    final sw = Stopwatch()..start();

    try {
      final bytes = await image.readAsBytes();
      logOcr(
        '[1/6] ✅ Image bytes read (${(bytes.length / 1024).toStringAsFixed(1)} KB) — ${sw.elapsedMilliseconds}ms',
        name: 'OCR_ENGINE',
      );

      final base64Str = base64Encode(bytes);
      logOcr(
        '[2/6] ✅ Base64 encoded (${(base64Str.length / 1024).toStringAsFixed(1)} KB) — ${sw.elapsedMilliseconds}ms',
        name: 'OCR_ENGINE',
      );

      final extension = p.extension(image.path).toLowerCase();
      final mimeType = extension == '.png' ? 'image/png' : 'image/jpeg';
      final dataUrl = 'data:$mimeType;base64,$base64Str';

      logOcr('[3/6] 🚀 Uploading to Mistral API...', name: 'OCR_ENGINE');
      final response = await _dio.post<Map<String, dynamic>>(
        _ocrEndpoint,
        data: {
          'model': 'mistral-ocr-latest',
          'document': {'type': 'image_url', 'image_url': dataUrl},
        },
        options: Options(headers: {'Authorization': 'Bearer $_mistralApiKey', 'Content-Type': 'application/json'}),
      );
      logOcr('[4/6] ✅ API response received — ${sw.elapsedMilliseconds}ms', name: 'OCR_ENGINE');

      final data = response.data;
      if (data == null) {
        logOcr('❌ API returned null data', name: 'OCR_ENGINE');
        return null;
      }

      final pages = data['pages'] as List<dynamic>? ?? const [];
      logOcr('[5/6] 📄 Parsing ${pages.length} page(s)...', name: 'OCR_ENGINE');

      String? pin;
      String? serial;
      String? pinGuess;
      String? serialGuess;

      for (final page in pages) {
        final pageMap = page as Map<String, dynamic>;
        final rawMarkdown = pageMap['markdown'] as String? ?? '';

        logOcr('📝 Raw markdown (${rawMarkdown.length} chars):\n$rawMarkdown', name: 'OCR_ENGINE');

        final result = _extractor.extractFromMarkdown(rawMarkdown);
        logOcr(
          '🔍 Extracted → pin: ${result.pin ?? "null"}, serial: ${result.serial ?? "null"}, pinGuess: ${result.pinGuess ?? "null"}, serialGuess: ${result.serialGuess ?? "null"}',
          name: 'OCR_ENGINE',
        );

        pin ??= result.pin;
        serial ??= result.serial;
        pinGuess ??= result.pinGuess;
        serialGuess ??= result.serialGuess;

        if (pin != null && serial != null) break;
      }

      sw.stop();
      logOcr(
        '[6/6] 🏁 Recognition complete — total ${sw.elapsedMilliseconds}ms | pin: ${pin != null ? "✅" : "❌"}, serial: ${serial != null ? "✅" : "❌"}',
        name: 'OCR_ENGINE',
      );

      return (
        pin: pin,
        serial: serial,
        pinGuess: pin == null ? pinGuess : null,
        serialGuess: serial == null ? serialGuess : null,
      );
    } on DioException catch (e) {
      sw.stop();
      logOcr('❌ DioError at ${sw.elapsedMilliseconds}ms: ${e.message}, response: ${e.response}', name: 'OCR_ENGINE');
      return null;
    } on Object catch (e) {
      sw.stop();
      logOcr('❌ Error at ${sw.elapsedMilliseconds}ms: $e', name: 'OCR_ENGINE');
      return null;
    }
  }
}

/// Builds OCR engines tuned for speed vs accuracy per field.
class OcrEngineFactory {
  OcrEngineFactory._();

  /// PIN: MistralOCR.
  static MistralOcrEngine createPinEngine() => MistralOcrEngine();
}
