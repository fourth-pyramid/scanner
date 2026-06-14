import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/extract_image/domain/entities/card_data.dart';
import 'package:qrscanner/features/extract_image/domain/repositories/extract_image_repository.dart';

/// Use case for processing an image and extracting card data
class ProcessImageUseCase implements UseCase<CardData, ProcessImageParams> {
  const ProcessImageUseCase({required this.repository});
  final ExtractImageRepository repository;

  @override
  Future<Either<Failure, CardData>> call(ProcessImageParams params) async =>
      repository.processImage(params.imageFile);
}

class ProcessImageParams {
  const ProcessImageParams({required this.imageFile});
  final File imageFile;
}
