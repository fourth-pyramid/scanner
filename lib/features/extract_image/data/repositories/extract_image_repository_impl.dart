import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:qrscanner/core/errors/exceptions.dart';
import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/network/network_info.dart';
import 'package:qrscanner/core/ocr/card_scan_ocr_service.dart';
import 'package:qrscanner/features/extract_image/data/datasources/extract_image_remote_datasource.dart';
import 'package:qrscanner/features/extract_image/domain/entities/card_data.dart';
import 'package:qrscanner/features/extract_image/domain/repositories/extract_image_repository.dart';

class ExtractImageRepositoryImpl implements ExtractImageRepository {
  ExtractImageRepositoryImpl({
    required this.remoteDataSource,
    required this.cardScanOcrService,
    required this.networkInfo,
  });

  final ExtractImageRemoteDataSource remoteDataSource;
  final CardScanOcrService cardScanOcrService;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, CardData>> processImage(File imageFile) async {
    try {
      final result = await cardScanOcrService.scan(imageFile);

      return Right(
        CardData(
          pin: result.pin,
          serial: result.serial,
          originalImage: imageFile,
          pinDetected: result.pinDetected,
          serialDetected: result.serialDetected,
        ),
      );
    } on FormatException catch (e) {
      return Left(ValidationFailure(message: e.message));
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
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection available.'));
    }
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
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection available.'));
    }
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
}
