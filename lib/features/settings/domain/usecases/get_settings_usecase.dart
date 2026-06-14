import 'package:dartz/dartz.dart';

import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/settings/domain/repositories/settings_repository.dart';

/// Use case for getting current settings
class GetSettingsUseCase implements NoParamsUseCase<String?> {
  const GetSettingsUseCase({required this.repository});
  final SettingsRepository repository;

  @override
  Future<Either<Failure, String?>> call(NoParams params) async =>
      repository.getBaseUrl();
}
