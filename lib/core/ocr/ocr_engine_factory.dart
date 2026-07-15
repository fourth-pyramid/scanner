import 'package:qrscanner/core/ocr/cloud_vision_digit_ocr_engine.dart';
import 'package:qrscanner/core/ocr/digit_ocr_engine.dart';
import 'package:qrscanner/core/ocr/paddle_ocr_digit_ocr_engine.dart';

/// Builds OCR engines tuned for speed vs accuracy per field.
class OcrEngineFactory {
  OcrEngineFactory._();

  /// Toggle this to true to switch from Google Cloud Vision to self-hosted PaddleOCR
  static const bool usePaddleOcr = true;

  /// Base URL of your PaddleOCR server
  /// 'http://10.0.2.2:8000' is the loopback address to your host PC from Android Emulator.
  /// If running on a physical device, change this to your PC's local IP address (e.g. 'http://192.168.1.50:8000').
  static const String paddleOcrBaseUrl = 'https://ai-model-qvs3.onrender.com';

  /// Google Cloud Vision API Key
  static const String cloudVisionApiKey = 'AIzaSyCAq07uVZVv2YlHgxcQnqAaahXs-t0M-v4';

  /// PIN: Cloud or PaddleOCR
  static DigitOcrEngine createPinEngine() {
    if (usePaddleOcr) {
      return PaddleOcrDigitOcrEngine(baseUrl: paddleOcrBaseUrl);
    }
    return CloudVisionDigitOcrEngine(apiKey: cloudVisionApiKey);
  }

  /// Serial: Cloud or PaddleOCR
  static DigitOcrEngine createSerialEngine() {
    if (usePaddleOcr) {
      return PaddleOcrDigitOcrEngine(baseUrl: paddleOcrBaseUrl);
    }
    return CloudVisionDigitOcrEngine(apiKey: cloudVisionApiKey);
  }
}
