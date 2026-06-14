import 'package:dartz/dartz.dart';

import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/settings/domain/repositories/settings_repository.dart';

/// Use case for getting WiFi IP
class GetWifiIpUseCase implements NoParamsUseCase<String?> {
  const GetWifiIpUseCase({required this.repository});
  final SettingsRepository repository;

  @override
  Future<Either<Failure, String?>> call(NoParams params) async =>
      repository.getWifiIP();
}
