import 'package:dartz/dartz.dart';

import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/extract_image/domain/repositories/extract_image_repository.dart';

/// Use case for getting history count of saved cards
class GetHistoryCountUseCase implements NoParamsUseCase<int> {
  const GetHistoryCountUseCase({required this.repository});
  final ExtractImageRepository repository;

  @override
  Future<Either<Failure, int>> call(NoParams params) async =>
      repository.getHistoryCount();
}
