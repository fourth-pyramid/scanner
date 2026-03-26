import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

// ignore: avoid_classes_with_only_static_members
/// Helper class for image processing operations in isolates
class ImageIsolateHelper {
  /// Compress image in a separate isolate to avoid UI blocking
  /// Returns the path to the compressed image file
  static Future<File?> compressImageInIsolate({
    required String imagePath,
    int targetWidth = 2000,
  }) async {
    try {
      // Create parameters for isolate
      final params = _CompressionParams(
        imagePath: imagePath,
        targetWidth: targetWidth,
      );

      // Run compression in isolate
      final result = await compute(_compressImage, params);

      return result;
    } catch (e) {
      return null;
    }
  }

  /// Internal function that runs in isolate
  static Future<File?> _compressImage(_CompressionParams params) async {
    try {
      // Read image bytes
      final imageFile = File(params.imagePath);
      final bytes = await imageFile.readAsBytes();

      // Decode image
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        return null;
      }

      // Resize image - preserves aspect ratio and quality
      final resized = img.copyResize(decodedImage, width: params.targetWidth);

      // Encode as JPG - maintains quality
      final compressedBytes = img.encodeJpg(resized);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(compressedBytes);

      return tempFile;
    } catch (e) {
      return null;
    }
  }
}

/// Parameters for image compression
class _CompressionParams {
  final String imagePath;
  final int targetWidth;

  _CompressionParams({required this.imagePath, required this.targetWidth});
}
