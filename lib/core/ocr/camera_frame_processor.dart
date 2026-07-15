import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:qrscanner/core/ocr/live_card_scan_models.dart';

/// Crops the centered card ROI, splits PIN/serial zones, upscales 2× for OCR.
class CameraFrameProcessor {
  CameraFrameProcessor._();

  static Future<PreparedLiveFrame?> prepareFromCameraImage(
    CameraImage cameraImage,
  ) async {
    final encoded = await compute(_encodeFromCameraImage, {
      'width': cameraImage.width,
      'height': cameraImage.height,
      'isYuv420': cameraImage.format.group == ImageFormatGroup.yuv420,
      'isBgra': cameraImage.format.group == ImageFormatGroup.bgra8888,
      'planes': cameraImage.planes
          .map(
            (plane) => {
              'bytes': plane.bytes,
              'bytesPerRow': plane.bytesPerRow,
              'bytesPerPixel': plane.bytesPerPixel,
            },
          )
          .toList(),
    });

    return _writeEncodedFrame(encoded);
  }

  static Future<PreparedLiveFrame?> prepareFromJpegBytes(Uint8List bytes) async {
    final encoded = await compute(_encodeFromJpegBytes, bytes);
    return _writeEncodedFrame(encoded);
  }

  static Future<PreparedLiveFrame?> _writeEncodedFrame(
    Map<String, Uint8List>? encoded,
  ) async {
    if (encoded == null) return null;

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final cardPath = '${dir.path}/live_card_$stamp.jpg';
    final pinPath = '${dir.path}/live_pin_$stamp.jpg';
    final serialPath = '${dir.path}/live_serial_$stamp.jpg';

    await Future.wait([
      File(cardPath).writeAsBytes(encoded['card']!),
      File(pinPath).writeAsBytes(encoded['pin']!),
      File(serialPath).writeAsBytes(encoded['serial']!),
    ]);

    return PreparedLiveFrame(
      cardImagePath: cardPath,
      pinImagePath: pinPath,
      serialImagePath: serialPath,
    );
  }

  static Map<String, Uint8List>? _encodeFromJpegBytes(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      return _encodeRegions(decoded);
    } on Object {
      return null;
    }
  }

  static Map<String, Uint8List>? _encodeFromCameraImage(
    Map<String, dynamic> payload,
  ) {
    try {
      final width = payload['width'] as int;
      final height = payload['height'] as int;
      final isYuv420 = payload['isYuv420'] as bool? ?? false;
      final isBgra = payload['isBgra'] as bool? ?? false;
      final planesRaw = payload['planes'] as List<dynamic>;

      final planes = planesRaw.cast<Map<String, dynamic>>();
      final yPlane = planes[0];
      final yBytes = (yPlane['bytes'] as Uint8List).buffer.asUint8List();
      final yRow = yPlane['bytesPerRow'] as int;

      img.Image? rgb;

      if (isYuv420 && planes.length >= 3) {
        rgb = _yuv420ToImage(
          width: width,
          height: height,
          yBytes: yBytes,
          yRow: yRow,
          uBytes: (planes[1]['bytes'] as Uint8List).buffer.asUint8List(),
          uRow: planes[1]['bytesPerRow'] as int,
          vBytes: (planes[2]['bytes'] as Uint8List).buffer.asUint8List(),
          vRow: planes[2]['bytesPerRow'] as int,
        );
      } else if (isBgra) {
        rgb = _bgraToImage(
          width: width,
          height: height,
          bytes: yBytes,
          row: yRow,
        );
      }

      if (rgb == null) return null;
      return _encodeRegions(rgb);
    } on Object {
      return null;
    }
  }

  static Map<String, Uint8List> _encodeRegions(img.Image source) {
    final card = _cropCardRoi(source);
    final pinCrop = _cropRelative(
      card,
      CardRoiLayout.pinLeft,
      CardRoiLayout.pinTop,
      CardRoiLayout.pinWidth,
      CardRoiLayout.pinHeight,
    );
    final serialCrop = _cropRelative(
      card,
      CardRoiLayout.serialLeft,
      CardRoiLayout.serialTop,
      CardRoiLayout.serialWidth,
      CardRoiLayout.serialHeight,
    );

    return {
      'card': Uint8List.fromList(img.encodeJpg(_upscale(card), quality: 92)),
      'pin': Uint8List.fromList(img.encodeJpg(_upscale(pinCrop), quality: 92)),
      'serial': Uint8List.fromList(
        img.encodeJpg(_upscale(serialCrop), quality: 92),
      ),
    };
  }

  static img.Image _cropCardRoi(img.Image source) {
    final side = (source.width < source.height ? source.width : source.height) *
        CardRoiLayout.cardSizeFraction;
    final left = ((source.width - side) / 2).round();
    final top = ((source.height - side) / 2).round();
    return img.copyCrop(
      source,
      x: left.clamp(0, source.width - 1),
      y: top.clamp(0, source.height - 1),
      width: side.round().clamp(1, source.width),
      height: side.round().clamp(1, source.height),
    );
  }

  static img.Image _cropRelative(
    img.Image source,
    double left,
    double top,
    double width,
    double height,
  ) {
    final x = (source.width * left).round();
    final y = (source.height * top).round();
    final w = (source.width * width).round().clamp(1, source.width - x);
    final h = (source.height * height).round().clamp(1, source.height - y);
    return img.copyCrop(source, x: x, y: y, width: w, height: h);
  }

  static img.Image _upscale(img.Image source) {
    final targetWidth =
        (source.width * CardRoiLayout.upscaleFactor).round().clamp(400, 2400);
    var image = img.copyResize(
      source,
      width: targetWidth,
      interpolation: img.Interpolation.cubic,
    );
    image = img.grayscale(image);
    image = img.adjustColor(image, contrast: 1.35, brightness: 1.03);
    return image;
  }

  static img.Image _yuv420ToImage({
    required int width,
    required int height,
    required Uint8List yBytes,
    required int yRow,
    required Uint8List uBytes,
    required int uRow,
    required Uint8List vBytes,
    required int vRow,
  }) {
    final out = img.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      final yOffset = y * yRow;
      final uvOffset = (y >> 1) * uRow;
      for (var x = 0; x < width; x++) {
        final yValue = yBytes[yOffset + x];
        final uValue = uBytes[uvOffset + (x >> 1)];
        final vValue = vBytes[uvOffset + (x >> 1)];

        final yp = yValue.toDouble();
        final up = uValue - 128.0;
        final vp = vValue - 128.0;

        final r = (yp + 1.402 * vp).round().clamp(0, 255);
        final g = (yp - 0.344136 * up - 0.714136 * vp).round().clamp(0, 255);
        final b = (yp + 1.772 * up).round().clamp(0, 255);
        out.setPixelRgb(x, y, r, g, b);
      }
    }
    return out;
  }

  static img.Image _bgraToImage({
    required int width,
    required int height,
    required Uint8List bytes,
    required int row,
  }) {
    final out = img.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      final offset = y * row;
      for (var x = 0; x < width; x++) {
        final i = offset + x * 4;
        if (i + 3 >= bytes.length) continue;
        out.setPixelRgb(x, y, bytes[i + 2], bytes[i + 1], bytes[i]);
      }
    }
    return out;
  }
}

class PreparedLiveFrame {
  const PreparedLiveFrame({
    required this.cardImagePath,
    required this.pinImagePath,
    required this.serialImagePath,
  });

  final String cardImagePath;
  final String pinImagePath;
  final String serialImagePath;
}
