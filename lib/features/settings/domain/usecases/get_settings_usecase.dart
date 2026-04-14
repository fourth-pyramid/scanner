import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/settings_repository.dart';

/// Use case for getting current settings
class GetSettingsUseCase implements NoParamsUseCase<String?> {
  const GetSettingsUseCase({required this.repository});
  final SettingsRepository repository;

  @override
  Future<Either<Failure, String?>> call(NoParams params) async =>
      await repository.getBaseUrl();
}
