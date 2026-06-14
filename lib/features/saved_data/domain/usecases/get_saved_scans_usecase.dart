import 'package:dartz/dartz.dart';

import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/saved_data/domain/entities/saved_scan_entity.dart';
import 'package:qrscanner/features/saved_data/domain/repositories/saved_data_repository.dart';

/// Use case for getting saved scans
class GetSavedScansUseCase implements NoParamsUseCase<List<SavedScanEntity>> {
  const GetSavedScansUseCase({required this.repository});
  final SavedDataRepository repository;

  @override
  Future<Either<Failure, List<SavedScanEntity>>> call(NoParams params) async =>
      repository.getSavedScans();
}
