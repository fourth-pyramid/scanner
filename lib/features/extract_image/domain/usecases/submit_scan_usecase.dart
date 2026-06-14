import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/extract_image/domain/repositories/extract_image_repository.dart';

/// Use case for submitting scanned card data
class SubmitScanUseCase implements UseCase<Unit, SubmitScanParams> {
  const SubmitScanUseCase({required this.repository});
  final ExtractImageRepository repository;

  @override
  Future<Either<Failure, Unit>> call(SubmitScanParams params) async =>
      repository.submitScan(
        pin: params.pin,
        serial: params.serial,
        phoneType: params.phoneType,
        categoryId: params.categoryId,
        image: params.image,
      );
}

class SubmitScanParams {
  const SubmitScanParams({
    required this.pin,
    required this.serial,
    required this.phoneType,
    required this.categoryId,
    this.image,
  });
  final String pin;
  final String serial;
  final String phoneType;
  final int categoryId;
  final File? image;
}
