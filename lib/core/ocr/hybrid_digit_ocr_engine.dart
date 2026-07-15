import 'dart:io';

import 'package:qrscanner/core/ocr/digit_ocr_engine.dart';
import 'package:qrscanner/core/ocr/models/ocr_models.dart';

/// On-device ML Kit first for speed; Cloud Vision only when ML Kit is weak.
class HybridDigitOcrEngine implements DigitOcrEngine {
  HybridDigitOcrEngine({
    required DigitOcrEngine cloudEngine,
    required DigitOcrEngine onDeviceEngine,
  })  : _cloudEngine = cloudEngine,
        _onDeviceEngine = onDeviceEngine;

  final DigitOcrEngine _cloudEngine;
  final DigitOcrEngine _onDeviceEngine;

  @override
  Future<OcrDigitSequence?> recognizeDigits(
    File image, {
    required String label,
    required CardRegionKind regionKind,
  }) async {
    final onDevice = await _onDeviceEngine.recognizeDigits(
      image,
      label: label,
      regionKind: regionKind,
    );

    if (_isStrongResult(onDevice, regionKind: regionKind)) {
      return onDevice;
    }

    if (_isAcceptableResult(onDevice, regionKind: regionKind)) {
      return onDevice;
    }

    final cloud = await _cloudEngine.recognizeDigits(
      image,
      label: '${label}_cloud',
      regionKind: regionKind,
    );

    return _pickBest(cloud, onDevice, regionKind: regionKind);
  }

  bool _isStrongResult(
    OcrDigitSequence? sequence, {
    required CardRegionKind regionKind,
  }) {
    if (sequence == null || sequence.value.isEmpty) return false;

    final expectedLength = regionKind == CardRegionKind.pin ? 14 : 12;
    return sequence.value.length == expectedLength &&
        sequence.averageConfidence >= 0.72;
  }

  bool _isAcceptableResult(
    OcrDigitSequence? sequence, {
    required CardRegionKind regionKind,
  }) {
    if (sequence == null || sequence.value.isEmpty) return false;

    if (regionKind == CardRegionKind.pin) {
      return sequence.value.length == 14 && sequence.averageConfidence >= 0.58;
    }

    return sequence.value.length >= 10 &&
        sequence.averageConfidence >= 0.52;
  }

  OcrDigitSequence? _pickBest(
    OcrDigitSequence? cloud,
    OcrDigitSequence? onDevice, {
    required CardRegionKind regionKind,
  }) {
    if (cloud == null) return onDevice;
    if (onDevice == null) return cloud;

    final targetLength = regionKind == CardRegionKind.pin ? 14 : 12;
    final cloudExact = cloud.value.length == targetLength;
    final onDeviceExact = onDevice.value.length == targetLength;

    if (cloudExact && !onDeviceExact) return cloud;
    if (onDeviceExact && !cloudExact) return onDevice;

    return cloud.averageConfidence >= onDevice.averageConfidence
        ? cloud
        : onDevice;
  }

  @override
  Future<void> dispose() async {
    await _cloudEngine.dispose();
    await _onDeviceEngine.dispose();
  }
}
