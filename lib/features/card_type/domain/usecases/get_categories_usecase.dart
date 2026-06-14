import 'package:dartz/dartz.dart';

import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/card_type/domain/entities/category_entity.dart';
import 'package:qrscanner/features/card_type/domain/repositories/card_type_repository.dart';

/// Use case for getting categories
class GetCategoriesUseCase implements NoParamsUseCase<List<CategoryEntity>> {
  const GetCategoriesUseCase({required this.repository});
  final CardTypeRepository repository;

  @override
  Future<Either<Failure, List<CategoryEntity>>> call(NoParams params) async =>
      repository.getCategories();
}
