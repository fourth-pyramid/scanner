import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:qrscanner/core/ocr/models/ocr_models.dart';

/// Advanced on-device preprocessing tuned for small printed numeric codes.
class ImagePreprocessor {
  static const int _maxOutputWidth = 1600;
  static const int _minOutputWidth = 1000;
  static const int _maxWorkingWidth = 1200;

  /// Downscale large captures so layout OCR stays fast.
  static File? resizeForOcr(File imageFile) {
    try {
      final bytes = imageFile.readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null || decoded.width <= _maxWorkingWidth) return null;

      final resized = img.copyResize(decoded, width: _maxWorkingWidth);
      final tempPath =
          '${imageFile.parent.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(tempPath)
        ..writeAsBytesSync(img.encodeJpg(resized, quality: 90));
      return tempFile;
    } on Object {
      return null;
    }
  }

  /// Compress oversized captures before OCR.
  static File? compressIfNeeded(File imageFile, {int maxSizeKb = 4096}) {
    try {
      final sizeKb = imageFile.lengthSync() / 1024;
      if (sizeKb <= maxSizeKb) return null;

      final bytes = imageFile.readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final resized = img.copyResize(decoded, width: 1200);
      final compressedBytes = img.encodeJpg(resized, quality: 85);
      final tempPath =
          '${imageFile.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(tempPath)..writeAsBytesSync(compressedBytes);
      return tempFile;
    } on Object {
      return null;
    }
  }

  /// Enhance contrast, brightness, and sharpness of the full card image to make closed-loop numbers (like 6) clearer.
  static File? enhanceForOcr(File imageFile) {
    try {
      final bytes = imageFile.readAsBytesSync();
      var decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // Downscale if very large
      if (decoded.width > _maxWorkingWidth) {
        decoded = img.copyResize(decoded, width: _maxWorkingWidth);
      }

      // Convert to grayscale for cleaner OCR
      decoded = img.grayscale(decoded);

      // Normalize histogram to maximize contrast range
      decoded = _normalizeHistogram(decoded);

      // Light unsharp mask to keep character edges crisp
      decoded = _unsharpMask(decoded, amount: 1.2, radius: 1);

      // Boost contrast and brightness slightly
      decoded = img.adjustColor(decoded, contrast: 1.35, brightness: 1.03);

      final tempPath =
          '${imageFile.parent.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(tempPath)
        ..writeAsBytesSync(img.encodeJpg(decoded, quality: 90));
      return tempFile;
    } on Object {
      return null;
    }
  }

  /// Fast preparation for modern/robust engines (like PaddleOCR) that don't need heavy pixel enhancements.
  /// Only downscales and compresses to keep network uploads fast.
  static File? fastPrepare(File imageFile) {
    try {
      final bytes = imageFile.readAsBytesSync();
      var decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      // Downscale if very large
      if (decoded.width > _maxWorkingWidth) {
        decoded = img.copyResize(decoded, width: _maxWorkingWidth);
      }

      final tempPath =
          '${imageFile.parent.path}/fast_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(tempPath)
        ..writeAsBytesSync(img.encodeJpg(decoded, quality: 80));
      return tempFile;
    } on Object {
      return null;
    }
  }

  static ({int width, int height})? readDimensions(String imagePath) {
    try {
      final bytes = File(imagePath).readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      return (width: decoded.width, height: decoded.height);
    } on Object {
      return null;
    }
  }

  /// Crop PIN/serial regions and build OCR-ready variants in one pass.
  static PreparedScanAssets? prepareRegions({
    required String imagePath,
    required ScanCropBox pinCropBox,
    required ScanCropBox serialCropBox,
    required bool pinDetectedAutomatically,
    required bool serialDetectedAutomatically,
  }) {
    try {
      final imageFile = File(imagePath);
      final bytes = imageFile.readAsBytesSync();
      final source = img.decodeImage(bytes);
      if (source == null) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final parentPath = imageFile.parent.path;

      final pin = _prepareRegion(
        source: source,
        cropBox: pinCropBox,
        parentPath: parentPath,
        prefix: 'pin_$timestamp',
      );
      final serial = _prepareRegion(
        source: source,
        cropBox: serialCropBox,
        parentPath: parentPath,
        prefix: 'serial_$timestamp',
        includeVariants: false,
      );

      if (pin == null || serial == null) return null;

      return PreparedScanAssets(
        pin: pin,
        serial: serial,
        pinDetectedAutomatically: pinDetectedAutomatically,
        serialDetectedAutomatically: serialDetectedAutomatically,
      );
    } on Object {
      return null;
    }
  }

  /// Prepare a single cropped region (used for PIN fallback zones).
  static PreparedRegionAssets? prepareSingleRegion({
    required String imagePath,
    required ScanCropBox cropBox,
    required String prefix,
  }) {
    try {
      final imageFile = File(imagePath);
      final bytes = imageFile.readAsBytesSync();
      final source = img.decodeImage(bytes);
      if (source == null) return null;

      return _prepareRegion(
        source: source,
        cropBox: cropBox,
        parentPath: imageFile.parent.path,
        prefix: prefix,
      );
    } on Object {
      return null;
    }
  }

  static PreparedRegionAssets? _prepareRegion({
    required img.Image source,
    required ScanCropBox cropBox,
    required String parentPath,
    required String prefix,
    bool includeVariants = true,
  }) {
    final cropped = img.copyCrop(
      source,
      x: cropBox.left,
      y: cropBox.top,
      width: cropBox.width,
      height: cropBox.height,
    );

    final base = _buildBaseImage(cropped);
    final basePath = '$parentPath/${prefix}_base.jpg';
    File(basePath).writeAsBytesSync(img.encodeJpg(base, quality: 95));

    final variantPaths = <String>[];
    if (includeVariants) {
      final variants = _createVariants(base);
      for (var i = 0; i < variants.length; i++) {
        final path = '$parentPath/${prefix}_v$i.jpg';
        File(path).writeAsBytesSync(img.encodeJpg(variants[i], quality: 92));
        variantPaths.add(path);
      }
    }

    return PreparedRegionAssets(basePath: basePath, variantPaths: variantPaths);
  }

  static img.Image _buildBaseImage(img.Image cropped) {
    return cropped;
  }

  /// Soft binarized variant helps 5/6 on STC cards without a second pass.
  static List<img.Image> _createVariants(img.Image base) => [
    _variantSoftBinarized(base),
  ];

  /// Gentler threshold keeps the bottom opening visible on closed-loop 6 glyphs.
  static img.Image _variantSoftBinarized(img.Image source) {
    var image = img.copyResize(
      source,
      width: source.width.clamp(_minOutputWidth, _maxOutputWidth),
      interpolation: img.Interpolation.cubic,
    );
    image = img.grayscale(image);
    image = _normalizeHistogram(image);
    image = _unsharpMask(image, amount: 1.8, radius: 1);
    image = img.adjustColor(image, contrast: 1.7, brightness: 1.06);
    final threshold = (_otsuThreshold(image) + 14).clamp(110, 215);
    return _binarize(image, threshold: threshold);
  }

  static img.Image _normalizeHistogram(img.Image source) {
    var minLum = 255;
    var maxLum = 0;
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final lum = source.getPixel(x, y).luminance.round();
        if (lum < minLum) minLum = lum;
        if (lum > maxLum) maxLum = lum;
      }
    }

    if (maxLum <= minLum) return source;

    final range = maxLum - minLum;
    final result = img.Image(width: source.width, height: source.height);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final lum = source.getPixel(x, y).luminance;
        final stretched = (((lum - minLum) / range) * 255).round().clamp(0, 255);
        result.setPixel(x, y, img.ColorRgb8(stretched, stretched, stretched));
      }
    }
    return result;
  }

  static img.Image _unsharpMask(
    img.Image source, {
    required double amount,
    required int radius,
  }) {
    final blurred = img.gaussianBlur(source, radius: radius);
    final result = img.Image(width: source.width, height: source.height);

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final original = source.getPixel(x, y).luminance;
        final blur = blurred.getPixel(x, y).luminance;
        final sharpened = (original + amount * (original - blur)).round().clamp(
          0,
          255,
        );
        result.setPixel(
          x,
          y,
          img.ColorRgb8(sharpened, sharpened, sharpened),
        );
      }
    }
    return result;
  }

  static int _otsuThreshold(img.Image source) {
    final histogram = List<int>.filled(256, 0);
    final total = source.width * source.height;

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        histogram[source.getPixel(x, y).luminance.round()]++;
      }
    }

    var sum = 0;
    for (var i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    var sumB = 0;
    var weightB = 0;
    var maxVariance = 0.0;
    var threshold = 128;

    for (var t = 0; t < 256; t++) {
      weightB += histogram[t];
      if (weightB == 0) continue;

      final weightF = total - weightB;
      if (weightF == 0) break;

      sumB += t * histogram[t];
      final meanB = sumB / weightB;
      final meanF = (sum - sumB) / weightF;
      final variance = weightB * weightF * (meanB - meanF) * (meanB - meanF);

      if (variance > maxVariance) {
        maxVariance = variance;
        threshold = t;
      }
    }

    return threshold;
  }

  static img.Image _binarize(img.Image source, {required int threshold}) {
    final result = img.Image(width: source.width, height: source.height);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final lum = source.getPixel(x, y).luminance;
        final value = lum < threshold ? 0 : 255;
        result.setPixel(x, y, img.ColorRgb8(value, value, value));
      }
    }
    return result;
  }
}
