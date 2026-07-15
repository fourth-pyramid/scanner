import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:qrscanner/core/ocr/async_lock.dart';
import 'package:qrscanner/core/ocr/card_region_detector.dart';
import 'package:qrscanner/core/ocr/cloud_vision_digit_ocr_engine.dart';
import 'package:qrscanner/core/ocr/digit_consensus_resolver.dart';
import 'package:qrscanner/core/ocr/digit_ocr_engine.dart';
import 'package:qrscanner/core/ocr/digit_sequence_parser.dart';
import 'package:qrscanner/core/ocr/image_preprocessor.dart';
import 'package:qrscanner/core/ocr/layout_scan_extractor.dart';
import 'package:qrscanner/core/ocr/models/ocr_models.dart';
import 'package:qrscanner/core/ocr/ocr_engine_factory.dart';
import 'package:qrscanner/core/ocr/paddle_ocr_digit_ocr_engine.dart';

/// Fast, accurate on-device OCR pipeline for STC recharge cards.
class CardScanOcrService {
  CardScanOcrService({
    required DigitOcrEngine pinOcrEngine,
    required DigitOcrEngine serialOcrEngine,
    CardRegionDetector? regionDetector,
    DigitConsensusResolver? consensusResolver,
    DigitSequenceParser? sequenceParser,
    LayoutScanExtractor? layoutExtractor,
  }) : _pinEngine = pinOcrEngine,
       _serialEngine = serialOcrEngine,
       _regionDetector = regionDetector ?? CardRegionDetector(),
       _consensusResolver = consensusResolver ?? const DigitConsensusResolver(),
       _sequenceParser = sequenceParser ?? const DigitSequenceParser(),
       _layoutExtractor = layoutExtractor ?? const LayoutScanExtractor(),
       _ownsEngines = false;

  final DigitOcrEngine _pinEngine;
  final DigitOcrEngine _serialEngine;
  final CardRegionDetector _regionDetector;
  final DigitConsensusResolver _consensusResolver;
  final DigitSequenceParser _sequenceParser;
  final LayoutScanExtractor _layoutExtractor;
  final bool _ownsEngines;
  final AsyncLock _scanLock = AsyncLock();
  TextRecognizer? _layoutRecognizer;

  TextRecognizer get _layout => _layoutRecognizer ??= TextRecognizer();

  Future<CardScanOcrResult> scan(File imageFile) =>
      _scanLock.synchronized(() => _scanInternal(imageFile));

  Future<CardScanOcrResult> _scanInternal(File imageFile) async {
    final preparedImage = await compute(_prepareWorkingImage, imageFile.path);
    if (preparedImage == null) {
      throw const FormatException('Failed to decode image');
    }

    final workingImage = File(preparedImage['path'] as String);

    // Direct reliance on PaddleOCR engine for testing
    final engine = _pinEngine as PaddleOcrDigitOcrEngine;
    final result = await engine.recognizeCard(workingImage);
    return CardScanOcrResult(
      pin: result?.pin != null ? _sequenceParser.formatPin(result!.pin!) : null,
      serial: result?.serial,
      pinRaw: result?.pin,
      serialRaw: result?.serial,
      pinConfidence: result?.pin != null ? 0.9 : 0.0,
      serialConfidence: result?.serial != null ? 0.9 : 0.0,
      pinDetected: result?.pin != null,
      serialDetected: result?.serial != null,
      workingImage: workingImage,
      pinCroppedImage: workingImage,
      serialCroppedImage: workingImage,
    );
  }


  Future<RecognizedText> _readLayout(File workingImage) async {
    try {
      return await _layout.processImage(
        InputImage.fromFilePath(workingImage.absolute.path),
      );
    } on PlatformException {
      throw const FormatException('Failed to read image for OCR');
    }
  }

  Future<({RegionScanResult result, PreparedRegionAssets assets})> _scanPin({
    required PreparedRegionAssets primaryAssets,
    required OcrDigitSequence? layoutHint,
    required String workingImagePath,
    required double imageWidth,
    required double imageHeight,
  }) async {
    final primary = await _scanRegion(
      assets: primaryAssets,
      engine: _pinEngine,
      expectedLengths: const [14],
      preferredLength: 14,
      regionKind: CardRegionKind.pin,
      layoutHint: layoutHint,
    );

    if (_isReliablePinResult(primary)) {
      return (result: primary, assets: primaryAssets);
    }

    if (primary.detected &&
        primary.value != null &&
        primary.value!.length == 14) {
      return (result: primary, assets: primaryAssets);
    }

    final fallbacks = _regionDetector.pinFallbackRects(imageWidth, imageHeight);
    if (fallbacks.isEmpty) {
      return (result: primary, assets: primaryAssets);
    }

    final fallbackAssets = await compute(_prepareSingleRegion, {
      'imagePath': workingImagePath,
      'cropBox': ScanCropBox.fromRect(fallbacks.first).toMap(),
      'prefix': 'pin_fallback_${DateTime.now().millisecondsSinceEpoch}',
    });

    if (fallbackAssets == null) {
      return (result: primary, assets: primaryAssets);
    }

    final assets = PreparedRegionAssets.fromMap(fallbackAssets);
    final fallback = await _scanRegion(
      assets: assets,
      engine: _pinEngine,
      expectedLengths: const [14],
      preferredLength: 14,
      regionKind: CardRegionKind.pin,
      layoutHint: layoutHint,
    );

    if (_isReliablePinResult(fallback)) {
      return (result: fallback, assets: assets);
    }

    if (fallback.detected &&
        fallback.value != null &&
        (!_isReliablePinResult(primary) ||
            fallback.confidence > primary.confidence)) {
      return (result: fallback, assets: assets);
    }

    return (result: primary, assets: primaryAssets);
  }

  bool _isReliablePinResult(RegionScanResult result) =>
      result.detected &&
      result.value != null &&
      result.value!.length == 14 &&
      result.confidence >= 0.58;

  Future<RegionScanResult> _scanRegion({
    required PreparedRegionAssets assets,
    required DigitOcrEngine engine,
    required List<int> expectedLengths,
    required int preferredLength,
    required CardRegionKind regionKind,
    OcrDigitSequence? layoutHint,
    bool progressiveVariants = true,
  }) async {
    final sequences = <OcrDigitSequence>[];

    if (layoutHint != null &&
        expectedLengths.contains(layoutHint.value.length)) {
      sequences.add(layoutHint);
    }

    final baseSequence = await _recognizeVariant(
      assets.basePath,
      engine: engine,
      index: 0,
      expectedLengths: expectedLengths,
      regionKind: regionKind,
    );
    if (baseSequence != null) {
      sequences.add(baseSequence);
    }

    if (_canStopEarly(
      sequences,
      preferredLength: preferredLength,
      regionKind: regionKind,
      layoutHint: layoutHint,
    )) {
      await _cleanupVariantFiles(assets);
      return _resolveRegionResult(
        sequences: sequences,
        expectedLengths: expectedLengths,
        preferredLength: preferredLength,
        regionKind: regionKind,
      );
    }

    if (progressiveVariants) {
      for (var i = 0; i < assets.variantPaths.length; i++) {
        final sequence = await _recognizeVariant(
          assets.variantPaths[i],
          engine: engine,
          index: i + 1,
          expectedLengths: expectedLengths,
          regionKind: regionKind,
        );
        if (sequence != null) {
          sequences.add(sequence);
        }

        if (_hasStrongAgreement(sequences, preferredLength: preferredLength)) {
          break;
        }
      }
    }

    await _cleanupVariantFiles(assets);

    if (sequences.isEmpty) {
      return const RegionScanResult(value: null, confidence: 0, detected: false);
    }

    return _resolveRegionResult(
      sequences: sequences,
      expectedLengths: expectedLengths,
      preferredLength: preferredLength,
      regionKind: regionKind,
    );
  }

  bool _canStopEarly(
    List<OcrDigitSequence> sequences, {
    required int preferredLength,
    required CardRegionKind regionKind,
    OcrDigitSequence? layoutHint,
  }) {
    if (_hasStrongAgreement(sequences, preferredLength: preferredLength)) {
      return true;
    }

    final cropReads = sequences.where((s) => !s.sourceLabel.startsWith('layout'));
    final latest = cropReads.isEmpty ? null : cropReads.last;

    if (latest == null) return false;

    if (regionKind == CardRegionKind.pin) {
      if (latest.value.length != 14) return false;
      if (latest.averageConfidence >= 0.65) return true;
      if (layoutHint != null &&
          layoutHint.value.length == 14 &&
          layoutHint.value == latest.value) {
        return true;
      }
      return false;
    }

    return latest.value.length >= 10 && latest.averageConfidence >= 0.55;
  }

  bool _hasStrongAgreement(
    List<OcrDigitSequence> sequences, {
    required int preferredLength,
  }) {
    final matching = sequences
        .where((s) => s.value.length == preferredLength)
        .map((s) => s.value)
        .toList();
    if (matching.length < 2) return false;

    final counts = <String, int>{};
    for (final value in matching) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    return counts.values.any((count) => count >= 2);
  }

  Future<OcrDigitSequence?> _recognizeVariant(
    String path, {
    required DigitOcrEngine engine,
    required int index,
    required List<int> expectedLengths,
    required CardRegionKind regionKind,
  }) async {
    final file = File(path);
    if (!file.existsSync() || file.lengthSync() == 0) return null;

    final sequence = await engine.recognizeDigits(
      file,
      label: '${regionKind.name}_$index',
      regionKind: regionKind,
    );
    if (sequence == null || sequence.value.isEmpty) return null;

    return _filterToExpectedLengths(
      sequence,
      expectedLengths: expectedLengths,
      regionKind: regionKind,
    );
  }

  RegionScanResult _resolveRegionResult({
    required List<OcrDigitSequence> sequences,
    required List<int> expectedLengths,
    required int preferredLength,
    required CardRegionKind regionKind,
  }) {
    final resolved = _consensusResolver.resolve(
      sequences: sequences,
      expectedLengths: expectedLengths,
      preferredLength: preferredLength,
    );

    final finalValue = regionKind == CardRegionKind.pin &&
            resolved != null &&
            resolved.length != 14
        ? null
        : resolved;

    final confidence = sequences
        .map((s) => s.averageConfidence)
        .reduce((a, b) => a + b) /
        sequences.length;

    return RegionScanResult(
      value: finalValue,
      confidence: confidence,
      detected: finalValue != null,
    );
  }

  OcrDigitSequence? _filterToExpectedLengths(
    OcrDigitSequence sequence, {
    required List<int> expectedLengths,
    required CardRegionKind regionKind,
  }) {
    if (expectedLengths.contains(sequence.value.length)) {
      return sequence;
    }

    final parsed = _sequenceParser.parse(sequence.value);
    final extracted = regionKind == CardRegionKind.pin
        ? parsed['pin']
        : parsed['serial'];

    if (extracted == null || !expectedLengths.contains(extracted.length)) {
      return null;
    }

    return OcrDigitSequence(
      value: extracted,
      averageConfidence: sequence.averageConfidence,
      digits: [
        for (var i = 0; i < extracted.length; i++)
          DigitObservation(
            digit: extracted[i],
            confidence: sequence.averageConfidence,
            position: i,
          ),
      ],
      sourceLabel: sequence.sourceLabel,
    );
  }

  Future<void> _cleanupVariantFiles(PreparedRegionAssets assets) async {
    for (final path in assets.variantPaths) {
      final file = File(path);
      if (file.existsSync()) {
        try {
          await file.delete();
        } on Object {
          // Ignore cleanup errors.
        }
      }
    }
  }

  Future<void> dispose() async {
    if (_layoutRecognizer != null) {
      await _layoutRecognizer!.close();
      _layoutRecognizer = null;
    }
    if (_ownsEngines) {
      await _pinEngine.dispose();
      await _serialEngine.dispose();
    }
  }

  static Map<String, dynamic>? _prepareWorkingImage(String imagePath) {
    // If we are using PaddleOCR, completely skip any image decoding, resizing, or enhancement.
    // The camera page already outputs a cropped and compressed JPEG image of the card.
    // Skipping this step saves 2-3 seconds of CPU processing time on the client.
    if (OcrEngineFactory.usePaddleOcr) {
      return {
        'path': imagePath,
        'width': 1200,
        'height': 1200,
      };
    }

    final file = File(imagePath);
    final enhanced = ImagePreprocessor.enhanceForOcr(file);
    final workingPath = enhanced?.path ?? imagePath;
    final dimensions = ImagePreprocessor.readDimensions(workingPath);
    if (dimensions == null) return null;

    return {
      'path': workingPath,
      'width': dimensions.width,
      'height': dimensions.height,
    };
  }

  static PreparedScanAssets? _prepareRegions(Map<String, dynamic> params) {
    final imagePath = params['imagePath'] as String?;
    final pinCrop = params['pinCropBox'] as Map<Object?, Object?>?;
    final serialCrop = params['serialCropBox'] as Map<Object?, Object?>?;
    if (imagePath == null || pinCrop == null || serialCrop == null) {
      return null;
    }

    return ImagePreprocessor.prepareRegions(
      imagePath: imagePath,
      pinCropBox: ScanCropBox.fromMap(pinCrop.cast<String, int>()),
      serialCropBox: ScanCropBox.fromMap(serialCrop.cast<String, int>()),
      pinDetectedAutomatically: params['pinDetectedAutomatically'] as bool? ?? false,
      serialDetectedAutomatically:
          params['serialDetectedAutomatically'] as bool? ?? false,
    );
  }

  static Map<String, dynamic>? _prepareSingleRegion(Map<String, dynamic> params) {
    final imagePath = params['imagePath'] as String?;
    final crop = params['cropBox'] as Map<Object?, Object?>?;
    final prefix = params['prefix'] as String?;
    if (imagePath == null || crop == null || prefix == null) return null;

    final assets = ImagePreprocessor.prepareSingleRegion(
      imagePath: imagePath,
      cropBox: ScanCropBox.fromMap(crop.cast<String, int>()),
      prefix: prefix,
    );

    return assets?.toMap();
  }
}

class CardScanOcrResult {
  const CardScanOcrResult({
    required this.pin,
    required this.serial,
    required this.pinRaw,
    required this.serialRaw,
    required this.pinConfidence,
    required this.serialConfidence,
    required this.pinDetected,
    required this.serialDetected,
    required this.workingImage,
    required this.pinCroppedImage,
    required this.serialCroppedImage,
  });

  final String? pin;
  final String? serial;
  final String? pinRaw;
  final String? serialRaw;
  final double pinConfidence;
  final double serialConfidence;
  final bool pinDetected;
  final bool serialDetected;
  final File workingImage;
  final File pinCroppedImage;
  final File serialCroppedImage;
}
