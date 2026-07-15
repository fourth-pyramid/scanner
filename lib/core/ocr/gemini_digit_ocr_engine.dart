import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:qrscanner/core/ocr/digit_ocr_engine.dart';
import 'package:qrscanner/core/ocr/models/ocr_models.dart';

/// Gemini 1.5 Flash OCR Engine — A free, highly intelligent vision-based digit OCR.
class GeminiDigitOcrEngine implements DigitOcrEngine {
  GeminiDigitOcrEngine({
    required String apiKey,
    Dio? dio,
  })  : _apiKey = apiKey,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 12),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  final String _apiKey;
  final Dio _dio;

  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent';

  @override
  Future<OcrDigitSequence?> recognizeDigits(
    File image, {
    required String label,
    required CardRegionKind regionKind,
  }) async {
    if (_apiKey.isEmpty || !_isReadableImage(image)) return null;

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final targetLength = regionKind == CardRegionKind.pin ? 14 : 12;

      final prompt = 'Identify all numeric digits in this cropped image of a recharge card. '
          'We expect a ${regionKind.name.toUpperCase()} number, which is exactly $targetLength digits long. '
          'Ignore any text or noise and return ONLY a JSON object in this format: {"digits": "extracted_numbers"}. '
          'Do not include markdown code block formatting or any other text.';

      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        queryParameters: {'key': _apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ]
        },
      );

      final data = response.data;
      if (data == null) {
        print('Gemini OCR: Received null response');
        return null;
      }

      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        print('Gemini OCR: candidates list is empty');
        return null;
      }

      final firstCandidate = candidates.first as Map<String, dynamic>;
      final content = firstCandidate['content'] as Map<String, dynamic>?;
      if (content == null) return null;

      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return null;

      final firstPart = parts.first as Map<String, dynamic>;
      final rawText = firstPart['text'] as String? ?? '';

      print('Gemini OCR: Raw response: "${rawText.trim()}"');

      var digits = '';
      try {
        final cleanedText = rawText.replaceAll(RegExp('```json|```'), '').trim();
        if (cleanedText.startsWith('{')) {
          final jsonResponse = jsonDecode(cleanedText) as Map<String, dynamic>;
          digits = jsonResponse['digits'] as String? ?? '';
        } else {
          digits = cleanedText;
        }
      } on Object catch (_) {
        digits = rawText;
      }

      final cleanedDigits = digits.replaceAll(RegExp(r'\D'), '');

      if (cleanedDigits.isEmpty) {
        print('Gemini OCR: No digits found in response');
        return null;
      }

      print('Gemini OCR: Successfully extracted digits: "$cleanedDigits"');

      return OcrDigitSequence(
        value: cleanedDigits,
        averageConfidence: 0.88,
        digits: [
          for (var i = 0; i < cleanedDigits.length; i++)
            DigitObservation(
              digit: cleanedDigits[i],
              confidence: 0.88,
              position: i,
            ),
        ],
        sourceLabel: 'gemini_$label',
      );
    } on DioException catch (e) {
      print('Gemini OCR: DioException: ${e.response?.statusCode} - ${e.response?.data}');
      return null;
    } on Object catch (e, stackTrace) {
      print('Gemini OCR: Error: $e\n$stackTrace');
      return null;
    }
  }

  /// Recognizes both PIN and Serial directly from the full un-cropped card image.
  Future<({String? pin, String? serial})?> recognizeCard(File image) async {
    if (_apiKey.isEmpty || !_isReadableImage(image)) return null;

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      const prompt = 'Analyze this image of a recharge card. '
          'Identify and extract: '
          '1. The PIN number (usually 14 digits). '
          '2. The Serial number (usually 12 digits). '
          'Ignore any other text or numbers on the card. '
          'Return ONLY a JSON object in this format: '
          '{"pin": "extracted_pin_digits_only", "serial": "extracted_serial_digits_only"}. '
          'Do not include markdown code block formatting or any other text.';

      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        queryParameters: {'key': _apiKey},
        data: {
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ]
        },
      );

      final data = response.data;
      if (data == null) {
        print('Gemini OCR Full: Received null response');
        return null;
      }

      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        print('Gemini OCR Full: candidates list is empty');
        return null;
      }

      final firstCandidate = candidates.first as Map<String, dynamic>;
      final content = firstCandidate['content'] as Map<String, dynamic>?;
      if (content == null) return null;

      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) return null;

      final firstPart = parts.first as Map<String, dynamic>;
      final rawText = firstPart['text'] as String? ?? '';

      print('Gemini OCR Full: Raw response: "${rawText.trim()}"');

      var pin = '';
      var serial = '';
      try {
        final cleanedText = rawText.replaceAll(RegExp('```json|```'), '').trim();
        if (cleanedText.startsWith('{')) {
          final jsonResponse = jsonDecode(cleanedText) as Map<String, dynamic>;
          pin = (jsonResponse['pin'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
          serial = (jsonResponse['serial'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
        }
      } on Object catch (_) {
        final digitsOnly = rawText.replaceAll(RegExp(r'\D'), '');
        if (digitsOnly.length >= 26) {
          pin = digitsOnly.substring(0, 14);
          serial = digitsOnly.substring(14, 26);
        }
      }

      return (pin: pin.isNotEmpty ? pin : null, serial: serial.isNotEmpty ? serial : null);
    } on DioException catch (e) {
      print('Gemini OCR Full: DioException: ${e.response?.statusCode} - ${e.response?.data}');
      return null;
    } on Object catch (e, stackTrace) {
      print('Gemini OCR Full: Error: $e\n$stackTrace');
      return null;
    }
  }

  bool _isReadableImage(File image) {
    try {
      return image.existsSync() && image.lengthSync() > 0;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> dispose() async {}
}
