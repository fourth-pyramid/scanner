import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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

/// PaddleOCR engine connecting to a self-hosted API endpoint.
class PaddleOcrDigitOcrEngine {
  PaddleOcrDigitOcrEngine({String? baseUrl, Dio? dio})
    : _baseUrl = baseUrl ?? 'http://10.0.2.2:8000', // Default Android emulator loopback host
      _dio =
          dio ??
          Dio(BaseOptions(connectTimeout: const Duration(seconds: 20), receiveTimeout: const Duration(seconds: 20)));

  final String _baseUrl;
  final Dio _dio;

  bool _isReadableImage(File image) {
    try {
      return image.existsSync() && image.lengthSync() > 0;
    } on Object {
      return false;
    }
  }

  Future<void> dispose() async {}

  /// Recognize both PIN (14 digits) and Serial (12 digits) from full card image.
  Future<({String? pin, String? serial})?> recognizeCard(File image) async {
    if (!_isReadableImage(image)) return null;

    try {
      final formData = FormData.fromMap({'file': await MultipartFile.fromFile(image.path, filename: 'image.jpg')});

      developer.log('PaddleOCR recognizeCard posting to: $_baseUrl/ocr', name: 'OCR_ENGINE');
      final response = await _dio.post<Map<String, dynamic>>('$_baseUrl/ocr', data: formData);

      String prettyJson;
      try {
        prettyJson = const JsonEncoder.withIndent('  ').convert(response.data);
      } on Object catch (_) {
        prettyJson = response.data.toString();
      }
      developer.log(
        'PaddleOCR recognizeCard response status: ${response.statusCode}\nResponse Body:\n$prettyJson',
        name: 'OCR_ENGINE',
      );

      final data = response.data;
      if (data == null || data['status'] != 'success') return null;

      final ocrResults = data['data'] as List<dynamic>? ?? const [];

      // ponytail: scan per-entry — 14 digits = PIN, 12 digits = serial
      String? pin;
      String? serial;
      for (final result in ocrResults) {
        final text = (result as Map<String, dynamic>)['text'] as String? ?? '';
        final digits = text.replaceAll(RegExp(r'\D'), '');
        if (digits.length == 14) pin ??= digits;
        if (digits.length == 12) serial ??= digits;
        if (pin != null && serial != null) break;
      }

      return (pin: pin, serial: serial);
    } on DioException catch (e) {
      developer.log('PaddleOCR recognizeCard DioError: ${e.message}, response: ${e.response}', name: 'OCR_ENGINE');
      return null;
    } on Object catch (e) {
      developer.log('PaddleOCR recognizeCard generic error: $e', name: 'OCR_ENGINE');
      return null;
    }
  }
}

/// Builds OCR engines tuned for speed vs accuracy per field.
class OcrEngineFactory {
  OcrEngineFactory._();

  /// Base URL of your PaddleOCR server
  static const String paddleOcrBaseUrl = 'https://ai-model-qvs3.onrender.com';

  /// PIN: PaddleOCR
  static PaddleOcrDigitOcrEngine createPinEngine() => PaddleOcrDigitOcrEngine(baseUrl: paddleOcrBaseUrl);
}

/// Fast, accurate on-device OCR pipeline for STC recharge cards.
class CardScanOcrService {
  CardScanOcrService({required PaddleOcrDigitOcrEngine pinOcrEngine}) : _pinEngine = pinOcrEngine;

  final PaddleOcrDigitOcrEngine _pinEngine;
  final AsyncLock _scanLock = AsyncLock();

  Future<CardScanOcrResult> scan(File imageFile) => _scanLock.synchronized(() => _scanInternal(imageFile));

  Future<CardScanOcrResult> _scanInternal(File imageFile) async {
    final preparedImage = await compute(_prepareWorkingImage, imageFile.path);
    if (preparedImage == null) {
      throw const FormatException('Failed to decode image');
    }

    final workingImage = File(preparedImage['path'] as String);

    final result = await _pinEngine.recognizeCard(workingImage);
    return CardScanOcrResult(
      pin: result?.pin, // ponytail: raw digits, no formatting
      serial: result?.serial,
      pinConfidence: result?.pin != null ? 0.9 : 0.0,
      serialConfidence: result?.serial != null ? 0.9 : 0.0,
      pinDetected: result?.pin != null,
      serialDetected: result?.serial != null,
      workingImage: workingImage,
    );
  }

  static Map<String, dynamic>? _prepareWorkingImage(String imagePath) => {'path': imagePath};
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
