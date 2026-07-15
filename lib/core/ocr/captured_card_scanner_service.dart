import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CapturedCardScannerService {
  CapturedCardScannerService();

  final TextRecognizer _recognizer = TextRecognizer();

  /// Detect PIN and serial from a single captured card photo.
  Future<CapturedCardScanResult?> scan(File imageFile) async {
    if (!imageFile.existsSync()) return null;

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _recognizer.processImage(inputImage);

      String getDigits(String text) => text.replaceAll(RegExp(r'[^0-9]'), '');
      List<int> validPinLengths = [14, 16, 17, 20];
      int targetSerialLength = 12;

      String? pinRaw;
      String? serialRaw;

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String digitsOnly = getDigits(line.text);
          
          if (validPinLengths.contains(digitsOnly.length)) {
            pinRaw = digitsOnly;
          }
          
          if (digitsOnly.length == targetSerialLength) {
            if (serialRaw == null || line.text.toLowerCase().contains('serial')) {
               serialRaw = digitsOnly;
            }
          }
        }
        
        String blockDigits = getDigits(block.text);
        if (pinRaw == null && validPinLengths.contains(blockDigits.length)) {
          pinRaw = blockDigits;
        }
        if (serialRaw == null && blockDigits.length == targetSerialLength) {
          serialRaw = blockDigits;
        }
      }

      if (pinRaw == null && serialRaw == null) return null;

      String? formattedPin = pinRaw;
      if (pinRaw != null && pinRaw.length == 14) {
         formattedPin = '${pinRaw.substring(0,4)} ${pinRaw.substring(4,7)} ${pinRaw.substring(7,11)} ${pinRaw.substring(11)}';
      }

      return CapturedCardScanResult(
        pin: formattedPin ?? pinRaw,
        serial: serialRaw,
        pinRaw: pinRaw,
        serialRaw: serialRaw,
        cardImage: imageFile,
        pinCropImage: imageFile,
        serialCropImage: imageFile,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}

class CapturedCardScanResult {
  const CapturedCardScanResult({
    required this.pin,
    required this.serial,
    required this.pinRaw,
    required this.serialRaw,
    required this.cardImage,
    required this.pinCropImage,
    required this.serialCropImage,
  });

  final String? pin;
  final String? serial;
  final String? pinRaw;
  final String? serialRaw;
  final File cardImage;
  final File pinCropImage;
  final File serialCropImage;

  bool get pinDetected => pinRaw != null && pinRaw!.length == 14;
  bool get serialDetected => serialRaw != null && serialRaw!.length == 12;
  bool get isComplete => pinDetected && serialDetected;
}
