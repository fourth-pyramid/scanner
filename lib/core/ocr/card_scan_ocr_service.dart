import 'dart:io';

import 'package:qrscanner/core/ocr/async_lock.dart';
import 'package:qrscanner/core/ocr/card_scan_ocr_result.dart';
import 'package:qrscanner/core/ocr/image_preprocessor.dart';
import 'package:qrscanner/core/ocr/mistral_ocr_engine.dart';
import 'package:qrscanner/core/ocr/ocr_logger.dart';

// Barrel exports — existing `import 'card_scan_ocr_service.dart'` keeps working.
export 'async_lock.dart';
export 'card_digit_extractor.dart';
export 'card_scan_ocr_result.dart';
export 'image_preprocessor.dart';
export 'mistral_ocr_engine.dart';
export 'ocr_logger.dart';

/// On-device preprocessing + OCR pipeline for STC recharge cards.
class CardScanOcrService {
  CardScanOcrService({required MistralOcrEngine pinOcrEngine, ImagePreprocessor? preprocessor})
    : _pinEngine = pinOcrEngine,
      _preprocessor = preprocessor ?? const ImagePreprocessor();

  final MistralOcrEngine _pinEngine;
  final ImagePreprocessor _preprocessor;
  final AsyncLock _scanLock = AsyncLock();

  Future<CardScanOcrResult> scan(File imageFile) => _scanLock.synchronized(() => _scanInternal(imageFile));

  Future<CardScanOcrResult> _scanInternal(File imageFile) async {
    final sw = Stopwatch()..start();
    logOcr('═══════════════════════════════════════', name: 'OCR_PIPELINE');
    logOcr('🔄 OCR Pipeline started', name: 'OCR_PIPELINE');
    logOcr('📁 Input: ${imageFile.path}', name: 'OCR_PIPELINE');
    var workingImage = imageFile;

    try {
      workingImage = await _preprocessor.enhance(imageFile);
    } on Object catch (e) {
      // Preprocessing is best-effort — fall back to the original image
      // instead of failing the whole scan.
      logOcr('⚠️ Preprocessing failed, using original: $e', name: 'OCR_PIPELINE');
    }
    final preprocessMs = sw.elapsedMilliseconds;
    logOcr('⏱ [Phase 1] Preprocessing: ${preprocessMs}ms', name: 'OCR_PIPELINE');

    final result = await _pinEngine.recognizeCard(workingImage);
    final modelMs = sw.elapsedMilliseconds - preprocessMs;
    logOcr('⏱ [Phase 2] Model upload + recognition: ${modelMs}ms', name: 'OCR_PIPELINE');

    final totalMs = sw.elapsedMilliseconds;
    sw.stop();

    logOcr('───────────── RESULTS ─────────────', name: 'OCR_PIPELINE');
    logOcr('PIN:          ${result?.pin ?? "NOT FOUND"}', name: 'OCR_PIPELINE');
    logOcr('Serial:       ${result?.serial ?? "NOT FOUND"}', name: 'OCR_PIPELINE');
    logOcr('PIN guess:    ${result?.pinGuess ?? "—"}', name: 'OCR_PIPELINE');
    logOcr('Serial guess: ${result?.serialGuess ?? "—"}', name: 'OCR_PIPELINE');
    logOcr('⏱ Preprocess: ${preprocessMs}ms | Model: ${modelMs}ms | Total: ${totalMs}ms', name: 'OCR_PIPELINE');
    logOcr('═══════════════════════════════════════', name: 'OCR_PIPELINE');

    return CardScanOcrResult(
      pin: result?.pin,
      serial: result?.serial,
      pinConfidence: result?.pin != null ? 0.9 : 0.0,
      serialConfidence: result?.serial != null ? 0.9 : 0.0,
      pinDetected: result?.pin != null,
      serialDetected: result?.serial != null,
      pinGuess: result?.pinGuess,
      serialGuess: result?.serialGuess,
      workingImage: workingImage,
    );
  }
}
