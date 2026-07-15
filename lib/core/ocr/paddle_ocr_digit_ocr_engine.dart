import 'dart:io';

import 'package:dio/dio.dart';
import 'package:qrscanner/core/ocr/digit_ocr_engine.dart';
import 'package:qrscanner/core/ocr/digit_sequence_parser.dart';
import 'package:qrscanner/core/ocr/models/ocr_models.dart';

/// PaddleOCR engine connecting to a self-hosted API endpoint.
class PaddleOcrDigitOcrEngine implements DigitOcrEngine {
  PaddleOcrDigitOcrEngine({
    String? baseUrl,
    Dio? dio,
  })  : _baseUrl = baseUrl ?? 'http://10.0.2.2:8000', // Default Android emulator loopback host
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  final String _baseUrl;
  final Dio _dio;
  final DigitSequenceParser _parser = const DigitSequenceParser();

  @override
  Future<OcrDigitSequence?> recognizeDigits(
    File image, {
    required String label,
    required CardRegionKind regionKind,
  }) async {
    if (!_isReadableImage(image)) return null;

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path, filename: 'image.jpg'),
      });

      print('PaddleOCR recognizeDigits posting to: $_baseUrl/ocr');
      final response = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/ocr',
        data: formData,
      );
      print('PaddleOCR recognizeDigits response status: ${response.statusCode}, data: ${response.data}');

      final data = response.data;
      if (data == null || data['status'] != 'success') return null;

      final ocrResults = data['data'] as List<dynamic>? ?? const [];
      final buffer = StringBuffer();
      
      for (final result in ocrResults) {
        final text = (result as Map<String, dynamic>)['text'] as String? ?? '';
        buffer.writeln(text);
      }

      final rawText = buffer.toString();
      return _extractFromRawText(
        rawText,
        label: 'paddle_$label',
        regionKind: regionKind,
      );
    } on DioException catch (e) {
      print('PaddleOCR recognizeDigits DioError: ${e.message}, response: ${e.response}');
      return null;
    } on Object catch (e) {
      print('PaddleOCR recognizeDigits generic error: $e');
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
        return _sequenceFromValue(pin, label: label, confidence: 0.90);
      }
      return null;
    }

    final serial = parsed['serial'];
    if (serial != null && serial.length >= 10) {
      return _sequenceFromValue(serial, label: label, confidence: 0.90);
    }

    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10 && digits.length <= 12) {
      return _sequenceFromValue(digits, label: label, confidence: 0.85);
    }

    return null;
  }

  OcrDigitSequence _sequenceFromValue(
    String value, {
    required String label,
    required double confidence,
  }) =>
      OcrDigitSequence(
        value: value,
        averageConfidence: confidence,
        digits: [
          for (var i = 0; i < value.length; i++)
            DigitObservation(
              digit: value[i],
              confidence: confidence,
              position: i,
            ),
        ],
        sourceLabel: label,
      );

  @override
  Future<void> dispose() async {}

  /// Recognize both PIN and Serial from full card image.
  Future<({String? pin, String? serial})?> recognizeCard(File image) async {
    if (!_isReadableImage(image)) return null;

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(image.path, filename: 'image.jpg'),
      });

      print('PaddleOCR recognizeCard posting to: $_baseUrl/ocr');
      final response = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/ocr',
        data: formData,
      );
      print('PaddleOCR recognizeCard response status: ${response.statusCode}, data: ${response.data}');

      final data = response.data;
      if (data == null || data['status'] != 'success') return null;

      final ocrResults = data['data'] as List<dynamic>? ?? const [];
      final buffer = StringBuffer();
      
      for (final result in ocrResults) {
        final text = (result as Map<String, dynamic>)['text'] as String? ?? '';
        buffer.writeln(text);
      }

      final parsed = _parser.parse(buffer.toString().trim());
      var pin = parsed['pin'];
      var serial = parsed['serial'];

      if (pin != null && pin.length != 14) pin = null;

      return (pin: pin, serial: serial);
    } on DioException catch (e) {
      print('PaddleOCR recognizeCard DioError: ${e.message}, response: ${e.response}');
      return null;
    } on Object catch (e) {
      print('PaddleOCR recognizeCard generic error: $e');
      return null;
    }
  }
}
