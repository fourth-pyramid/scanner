import 'package:dartz/dartz.dart';

import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/settings/domain/repositories/settings_repository.dart';

/// Use case for saving settings
class SaveSettingsUseCase implements UseCase<Unit, SaveSettingsParams> {
  const SaveSettingsUseCase({required this.repository});
  final SettingsRepository repository;

  @override
  Future<Either<Failure, Unit>> call(SaveSettingsParams params) async =>
      repository.saveBaseUrl(params.url);
}

class SaveSettingsParams {
  const SaveSettingsParams({required this.url});
  final String url;
}
