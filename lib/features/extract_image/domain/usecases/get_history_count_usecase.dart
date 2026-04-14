import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/extract_image_repository.dart';

/// Use case for getting history count of saved cards
class GetHistoryCountUseCase implements NoParamsUseCase<int> {
  const GetHistoryCountUseCase({required this.repository});
  final ExtractImageRepository repository;

  @override
  Future<Either<Failure, int>> call(NoParams params) async =>
      await repository.getHistoryCount();
}
