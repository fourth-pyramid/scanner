import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/features/extract_image/domain/entities/card_data.dart';

/// Repository contract for image processing and extraction
/// Defined in Domain Layer - implemented in Data Layer
abstract class ExtractImageRepository {
  /// Process an image and extract PIN and SERIAL numbers
  Future<Either<Failure, CardData>> processImage(File imageFile);
  
  /// Submit scanned card data to server
  Future<Either<Failure, Unit>> submitScan({
    required String pin,
    required String serial,
    required String phoneType,
    required int categoryId,
    File? image,
  });
  
  /// Get history count of saved cards
  Future<Either<Failure, int>> getHistoryCount();
}
