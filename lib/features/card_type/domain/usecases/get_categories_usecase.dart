import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/card_type_repository.dart';

/// Use case for getting categories
class GetCategoriesUseCase implements NoParamsUseCase<List<CategoryEntity>> {
  const GetCategoriesUseCase({required this.repository});
  final CardTypeRepository repository;

  @override
  Future<Either<Failure, List<CategoryEntity>>> call(NoParams params) async =>
      await repository.getCategories();
}
