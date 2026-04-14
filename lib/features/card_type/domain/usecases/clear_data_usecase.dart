import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/card_type_repository.dart';

/// Use case for clearing data
class ClearDataUseCase implements NoParamsUseCase<Unit> {
  const ClearDataUseCase({required this.repository});
  final CardTypeRepository repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async =>
      await repository.clearData();
}
