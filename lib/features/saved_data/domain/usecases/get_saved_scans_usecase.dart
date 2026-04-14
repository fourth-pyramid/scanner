import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/saved_scan_entity.dart';
import '../repositories/saved_data_repository.dart';

/// Use case for getting saved scans
class GetSavedScansUseCase implements NoParamsUseCase<List<SavedScanEntity>> {
  const GetSavedScansUseCase({required this.repository});
  final SavedDataRepository repository;

  @override
  Future<Either<Failure, List<SavedScanEntity>>> call(NoParams params) async =>
      await repository.getSavedScans();
}
