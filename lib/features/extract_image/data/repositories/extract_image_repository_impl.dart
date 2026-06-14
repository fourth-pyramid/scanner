import 'dart:io';
import 'dart:ui';

import 'package:dartz/dartz.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:qrscanner/core/errors/exceptions.dart';
import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/utils/image_isolate_helper.dart';
import 'package:qrscanner/core/utils/text_isolate_helper.dart';
import 'package:qrscanner/features/extract_image/data/datasources/extract_image_remote_datasource.dart';
import 'package:qrscanner/features/extract_image/domain/entities/card_data.dart';
import 'package:qrscanner/features/extract_image/domain/repositories/extract_image_repository.dart';

class ExtractImageRepositoryImpl implements ExtractImageRepository {
  ExtractImageRepositoryImpl({required this.remoteDataSource});

  final ExtractImageRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, CardData>> processImage(File imageFile) async {
    try {
      final textRecognizer = TextRecognizer();

      try {
        var finalImage = imageFile;
        final fileSizeInKB = await imageFile.length() / 1024;

        if (fileSizeInKB > 4096) {
          try {
            final compressedFile =
                await ImageIsolateHelper.compressImageInIsolate(
                  imagePath: imageFile.path,
                );
            if (compressedFile != null && compressedFile.existsSync()) {
              finalImage = compressedFile;
            }
          } on Object catch (_) {
            // Continue with original file.
          }
        }

        final dimensions = await ImageIsolateHelper.getImageDimensionsInIsolate(
          imagePath: finalImage.path,
        );
        if (dimensions == null) {
          return const Left(
            ValidationFailure(message: 'Failed to decode image'),
          );
        }

        final imgWidth = dimensions.width.toDouble();
        final imgHeight = dimensions.height.toDouble();

        final fullScan = await textRecognizer.processImage(
          InputImage.fromFilePath(finalImage.path),
        );

        final pinBox = _detectRegionBox(
              recognizedText: fullScan,
              imageHeight: imgHeight,
              expectedMinLength: 12,
              minRelativeY: 0.00,
              maxRelativeY: 0.26,
              preferredLength: 14,
            ) ??
            Rect.fromLTWH(
              imgWidth * 0.08,
              imgHeight * 0.02,
              imgWidth * 0.84,
              imgHeight * 0.18,
            );

        final serialBox = _detectRegionBox(
              recognizedText: fullScan,
              imageHeight: imgHeight,
              expectedMinLength: 10,
              minRelativeY: 0.72,
              maxRelativeY: 1.00,
              preferredLength: 12,
            ) ??
            Rect.fromLTWH(
              imgWidth * 0.08,
              imgHeight * 0.78,
              imgWidth * 0.84,
              imgHeight * 0.18,
            );

        final pinCropBox = _addPadding(pinBox, imgWidth, imgHeight, 0.12);
        final serialCropBox = _addPadding(serialBox, imgWidth, imgHeight, 0.12);

        final preparedAssets = await ImageIsolateHelper.prepareScanAssetsInIsolate(
          imagePath: finalImage.path,
          pinCropBox: _toScanCropBox(pinCropBox),
          serialCropBox: _toScanCropBox(serialCropBox),
        );
        if (preparedAssets == null) {
          return const Left(
            ValidationFailure(message: 'Failed to prepare scan image'),
          );
        }

        final pinRegionImage = File(preparedAssets.pinBasePath);
        final serialRegionImage = File(preparedAssets.serialBasePath);

        String? foundPin;
        String? foundSerial;
        var pinDetected = false;
        var serialDetected = false;

        if (pinRegionImage.existsSync()) {
          foundPin = await _extractBestPin(
            textRecognizer: textRecognizer,
            baseImage: pinRegionImage,
            variantPaths: preparedAssets.pinVariantPaths,
          );
          pinDetected = foundPin != null;
        }

        if (serialRegionImage.existsSync()) {
          foundSerial = await _extractBestSerial(
            textRecognizer: textRecognizer,
            baseImage: serialRegionImage,
            variantPaths: preparedAssets.serialVariantPaths,
          );
          serialDetected = foundSerial != null;
        }

        return Right(
          CardData(
            pin: foundPin != null ? _formatPin(foundPin) : null,
            serial: foundSerial,
            originalImage: finalImage,
            pinCroppedImage: pinRegionImage,
            serialCroppedImage: serialRegionImage,
            pinDetected: pinDetected,
            serialDetected: serialDetected,
          ),
        );
      } finally {
        await textRecognizer.close();
      }
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> submitScan({
    required String pin,
    required String serial,
    required String phoneType,
    required int categoryId,
    File? image,
  }) async {
    try {
      await remoteDataSource.submitScan(
        pin: pin,
        serial: serial,
        phoneType: phoneType,
        categoryId: categoryId,
        image: image,
      );
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, statusCode: e.statusCode));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getHistoryCount() async {
    try {
      final count = await remoteDataSource.getHistoryCount();
      return Right(count);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, statusCode: e.statusCode));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  Rect? _detectRegionBox({
    required RecognizedText recognizedText,
    required double imageHeight,
    required int expectedMinLength,
    required double minRelativeY,
    required double maxRelativeY,
    required int preferredLength,
  }) {
    Rect? selectedBox;
    var bestScore = -1;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final normalized = line.text.replaceAll(RegExp('[^0-9A-Za-z]'), '');
        if (normalized.length < expectedMinLength) continue;

        final box = line.boundingBox;
        final centerY = box.top + box.height / 2;
        final relativeY = centerY / imageHeight;
        if (relativeY < minRelativeY || relativeY > maxRelativeY) continue;

        var score = normalized.length;
        if (normalized.length == preferredLength) {
          score += 100;
        }
        score += (box.width / box.height).round();

        if (score > bestScore) {
          bestScore = score;
          selectedBox = box;
        }
      }
    }

    return selectedBox;
  }

  Future<String?> _extractBestPin({
    required TextRecognizer textRecognizer,
    required File baseImage,
    required List<String> variantPaths,
  }) async {
    final candidates = <String>[];
    final variantFiles = variantPaths.map(File.new).toList();

    try {
      for (final file in [baseImage, ...variantFiles]) {
        if (!file.existsSync()) continue;

        final text = await _recognizeText(textRecognizer, file);
        if (text.isEmpty) continue;

        final result = await TextIsolateHelper.extractNumbersInIsolate(text);
        final pin = result['pin'];
        if (pin != null && pin.isNotEmpty) {
          candidates.add(pin);
        }
      }
    } finally {
      await _deleteTempVariants(baseImage, variantFiles);
    }

    return _pickBestCandidate(
      candidates,
      expectedLengths: const [14],
      preferRepeatedResult: true,
    );
  }

  Future<String?> _extractBestSerial({
    required TextRecognizer textRecognizer,
    required File baseImage,
    required List<String> variantPaths,
  }) async {
    final candidates = <String>[];
    final variantFiles = variantPaths.map(File.new).toList();

    try {
      for (final file in [baseImage, ...variantFiles]) {
        if (!file.existsSync()) continue;

        final text = await _recognizeText(textRecognizer, file);
        if (text.isEmpty) continue;

        final result = await TextIsolateHelper.extractNumbersInIsolate(text);
        final serial = result['serial'];
        if (serial != null && serial.isNotEmpty) {
          candidates.add(serial);
        }
      }
    } finally {
      await _deleteTempVariants(baseImage, variantFiles);
    }

    return _pickBestCandidate(
      candidates,
      expectedLengths: const [10, 11, 12],
      preferRepeatedResult: true,
    );
  }

  Future<String> _recognizeText(TextRecognizer textRecognizer, File image) async {
    final recognized = await textRecognizer.processImage(
      InputImage.fromFilePath(image.path),
    );
    return recognized.text.trim();
  }

  String? _pickBestCandidate(
    List<String> rawCandidates, {
    required List<int> expectedLengths,
    required bool preferRepeatedResult,
  }) {
    if (rawCandidates.isEmpty) return null;

    final normalizedCandidates = rawCandidates
        .where((candidate) => expectedLengths.contains(candidate.length))
        .toList();
    final candidates = normalizedCandidates.isNotEmpty
        ? normalizedCandidates
        : rawCandidates;

    final frequency = <String, int>{};
    for (final candidate in candidates) {
      frequency[candidate] = (frequency[candidate] ?? 0) + 1;
    }

    candidates.sort((a, b) {
      final scoreB = _candidateScore(
        b,
        expectedLengths: expectedLengths,
        repeats: frequency[b] ?? 1,
        preferRepeatedResult: preferRepeatedResult,
      );
      final scoreA = _candidateScore(
        a,
        expectedLengths: expectedLengths,
        repeats: frequency[a] ?? 1,
        preferRepeatedResult: preferRepeatedResult,
      );
      return scoreB.compareTo(scoreA);
    });

    var best = candidates.first;
    for (final candidate in candidates.skip(1)) {
      best = _mergeCandidates(
        best,
        candidate,
        preferSixOverFive: true,
      )!;
    }

    return best;
  }

  int _candidateScore(
    String value, {
    required List<int> expectedLengths,
    required int repeats,
    required bool preferRepeatedResult,
  }) {
    var score = value.split('').toSet().length * 5;

    if (expectedLengths.contains(value.length)) {
      score += 200;
      score += (expectedLengths.length - expectedLengths.indexOf(value.length)) *
          20;
    }

    if (preferRepeatedResult) {
      score += repeats * 80;
    }

    if (value.startsWith('00') && value.length <= 10) {
      score -= 80;
    }

    return score;
  }

  String _formatPin(String number) {
    if (number.length != 14) return number;
    return '${number.substring(0, 4)} ${number.substring(4, 7)} ${number.substring(7, 11)} ${number.substring(11, 14)}';
  }

  String? _mergeCandidates(
    String? primary,
    String? secondary, {
    required bool preferSixOverFive,
  }) {
    if (primary == null || primary.isEmpty) return secondary;
    if (secondary == null || secondary.isEmpty) return primary;
    if (primary == secondary) return primary;
    if (primary.length != secondary.length) return primary;

    final merged = StringBuffer();
    for (var i = 0; i < primary.length; i++) {
      final a = primary[i];
      final b = secondary[i];

      if (a == b) {
        merged.write(a);
        continue;
      }

      if (preferSixOverFive &&
          ((a == '5' && b == '6') || (a == '6' && b == '5'))) {
        merged.write('6');
        continue;
      }

      merged.write(a);
    }

    return merged.toString();
  }

  Future<void> _deleteTempVariants(File baseImage, List<File> files) async {
    for (final file in files) {
      if (file.path == baseImage.path) continue;
      await _deleteIfTemp(file);
    }
  }

  ScanCropBox _toScanCropBox(Rect rect) => ScanCropBox(
    left: rect.left.toInt(),
    top: rect.top.toInt(),
    width: rect.width.toInt(),
    height: rect.height.toInt(),
  );

  Future<void> _deleteIfTemp(File file) async {
    try {
      if (file.existsSync()) {
        await file.delete();
      }
    } on Object catch (_) {
      // Ignore cleanup errors.
    }
  }

  Rect _addPadding(
    Rect box,
    double imgWidth,
    double imgHeight,
    double paddingPercent,
  ) {
    final padX = box.width * paddingPercent;
    final padY = box.height * paddingPercent;
    return Rect.fromLTWH(
      (box.left - padX).clamp(0, imgWidth),
      (box.top - padY).clamp(0, imgHeight),
      (box.width + padX * 2).clamp(
        0,
        imgWidth - (box.left - padX).clamp(0, imgWidth),
      ),
      (box.height + padY * 2).clamp(
        0,
        imgHeight - (box.top - padY).clamp(0, imgHeight),
      ),
    );
  }

}
