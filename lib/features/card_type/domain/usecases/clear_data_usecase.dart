import 'package:dartz/dartz.dart';

import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/card_type/domain/repositories/card_type_repository.dart';

/// Use case for clearing data
class ClearDataUseCase implements NoParamsUseCase<Unit> {
  const ClearDataUseCase({required this.repository});
  final CardTypeRepository repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async =>
      repository.clearData();
}
