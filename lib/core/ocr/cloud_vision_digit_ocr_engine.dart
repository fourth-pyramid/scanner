import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:qrscanner/core/ocr/digit_confusion_corrector.dart';
import 'package:qrscanner/core/ocr/digit_ocr_engine.dart';
import 'package:qrscanner/core/ocr/digit_sequence_parser.dart';
import 'package:qrscanner/core/ocr/models/ocr_models.dart';

/// Google Cloud Vision OCR — closest public API to Lens-quality text reading.
///
/// Uses DOCUMENT_TEXT_DETECTION with the latest Google OCR model.
/// Requires Vision API enabled on the GCP project and a valid API key.
class CloudVisionDigitOcrEngine implements DigitOcrEngine {
  CloudVisionDigitOcrEngine({
    required String apiKey,
    Dio? dio,
  })  : _apiKey = apiKey,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 8),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  final String _apiKey;
  final Dio _dio;
  final DigitSequenceParser _parser = const DigitSequenceParser();

  static const _endpoint =
      'https://vision.googleapis.com/v1/images:annotate';

  @override
  Future<OcrDigitSequence?> recognizeDigits(
    File image, {
    required String label,
    required CardRegionKind regionKind,
  }) async {
    if (_apiKey.isEmpty || !_isReadableImage(image)) return null;

    try {
      final bytes = await image.readAsBytes();
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        queryParameters: {'key': _apiKey},
        data: {
          'requests': [
            {
              'image': {'content': base64Encode(bytes)},
              'features': [
                {
                  'type': 'DOCUMENT_TEXT_DETECTION',
                },
              ],
              'imageContext': {
                'languageHints': ['en'],
              },
            },
          ],
        },
      );

      final data = response.data;
      if (data == null) return null;

      final responses = data['responses'] as List<dynamic>?;
      if (responses == null || responses.isEmpty) return null;

      final first = responses.first as Map<String, dynamic>;
      if (first.containsKey('error')) return null;

      final annotation = first['fullTextAnnotation'] as Map<String, dynamic>?;
      if (annotation == null) return null;

      final symbolSequence = _extractSymbolSequence(
        annotation,
        regionKind: regionKind,
      );
      if (symbolSequence != null && symbolSequence.digits.isNotEmpty) {
        return symbolSequence.copyWithSource('cloud_$label');
      }

      final rawText = annotation['text'] as String? ?? '';
      return _extractFromRawText(
        rawText,
        label: 'cloud_$label',
        regionKind: regionKind,
      );
    } on DioException {
      return null;
    } on Object {
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

  OcrDigitSequence? _extractSymbolSequence(
    Map<String, dynamic> annotation, {
    required CardRegionKind regionKind,
  }) {
    OcrDigitSequence? bestSequence;
    var bestScore = -1;

    for (final page in _asMaps(annotation['pages'])) {
      for (final block in _asMaps(page['blocks'])) {
        for (final paragraph in _asMaps(block['paragraphs'])) {
          for (final word in _asMaps(paragraph['words'])) {
            final observations = <DigitObservation>[];
            final rawWord = _wordText(word);

            for (final symbol in _asMaps(word['symbols'])) {
              final text = symbol['text'] as String? ?? '';
              final confidence =
                  (symbol['confidence'] as num?)?.toDouble() ?? 0.75;
              _addSymbol(observations, text, confidence);
            }

            if (observations.isEmpty) continue;

            final value = observations.map((d) => d.digit).join();
            final avgConfidence = observations
                    .map((d) => d.confidence)
                    .reduce((a, b) => a + b) /
                observations.length;

            final score = _scoreLine(
              value: value,
              rawLine: rawWord,
              avgConfidence: avgConfidence,
              regionKind: regionKind,
            );

            if (score > bestScore) {
              bestScore = score;
              bestSequence = OcrDigitSequence(
                value: value,
                averageConfidence: avgConfidence,
                digits: observations,
                sourceLabel: 'cloud_symbols',
              );
            }
          }
        }
      }
    }

    return bestSequence;
  }

  List<Map<String, dynamic>> _asMaps(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList();
  }

  String _wordText(Map<String, dynamic> word) {
    final symbols = _asMaps(word['symbols']);
    return symbols.map((s) => s['text'] as String? ?? '').join();
  }

  int _scoreLine({
    required String value,
    required String rawLine,
    required double avgConfidence,
    required CardRegionKind regionKind,
  }) {
    final normalized = rawLine.replaceAll(RegExp('[^0-9A-Za-z]'), '');
    final digitRatio = normalized.isEmpty
        ? 0.0
        : value.length / normalized.length;

    var score = (avgConfidence * 100).round();

    if (regionKind == CardRegionKind.pin) {
      if (value.length == 14) {
        score += 800;
      } else if (value.length >= 12) {
        score += 120;
      } else {
        score -= 300;
      }

      if (digitRatio < 0.85) score -= 250;
      if (_matchesPinGrouping(rawLine)) score += 180;
    } else {
      if (value.length == 12) {
        score += 500;
      } else if (value.length == 11) {
        score += 350;
      } else if (value.length == 10) {
        score += 200;
      }

      if (digitRatio < 0.70) score -= 150;
    }

    return score + value.length * 8;
  }

  bool _matchesPinGrouping(String rawLine) => RegExp(
        r'\d{4}[ \t-]*\d{3}[ \t-]*\d{4}[ \t-]*\d{3}',
      ).hasMatch(rawLine.replaceAll(RegExp('[^0-9 \t-]'), ''));

  void _addSymbol(
    List<DigitObservation> observations,
    String raw,
    double confidence,
  ) {
    final digit = DigitConfusionCorrector.normalizeChar(raw);
    if (digit == null) return;

    observations.add(
      DigitObservation(
        digit: digit,
        confidence: confidence,
        position: observations.length,
      ),
    );
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
        return _sequenceFromValue(pin, label: label, confidence: 0.72);
      }
      return null;
    }

    final serial = parsed['serial'];
    if (serial != null && serial.length >= 10) {
      return _sequenceFromValue(serial, label: label, confidence: 0.72);
    }

    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10 && digits.length <= 12) {
      return _sequenceFromValue(digits, label: label, confidence: 0.65);
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

  /// Recognizes both PIN and Serial directly from the full un-cropped card image.
  Future<({String? pin, String? serial})?> recognizeCard(File image) async {
    if (_apiKey.isEmpty || !_isReadableImage(image)) return null;

    try {
      final bytes = await image.readAsBytes();
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        queryParameters: {'key': _apiKey},
        data: {
          'requests': [
            {
              'image': {'content': base64Encode(bytes)},
              'features': [
                {
                  'type': 'DOCUMENT_TEXT_DETECTION',
                },
              ],
              'imageContext': {
                'languageHints': ['en'],
              },
            },
          ],
        },
      );

      final data = response.data;
      if (data == null) return null;

      final responses = data['responses'] as List<dynamic>?;
      if (responses == null || responses.isEmpty) return null;

      final first = responses.first as Map<String, dynamic>;
      if (first.containsKey('error')) return null;

      final annotation = first['fullTextAnnotation'] as Map<String, dynamic>?;
      if (annotation == null) return null;

      final rawText = annotation['text'] as String? ?? '';
      final parsed = _parser.parse(rawText.trim());

      var pin = parsed['pin'];
      var serial = parsed['serial'];

      if (pin != null && pin.length != 14) pin = null;

      return (pin: pin, serial: serial);
    } on DioException {
      return null;
    } on Object {
      return null;
    }
  }
}

extension _CloudOcrDigitSequenceCopy on OcrDigitSequence {
  OcrDigitSequence copyWithSource(String label) => OcrDigitSequence(
        value: value,
        averageConfidence: averageConfidence,
        digits: digits,
        sourceLabel: label,
      );
}
