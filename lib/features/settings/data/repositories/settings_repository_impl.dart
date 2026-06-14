import 'package:dartz/dartz.dart';
import 'package:qrscanner/core/errors/exceptions.dart';
import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:qrscanner/features/settings/domain/repositories/settings_repository.dart';

/// Implementation of SettingsRepository
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required this.localDataSource});
  final SettingsLocalDataSource localDataSource;

  @override
  Future<Either<Failure, String?>> getBaseUrl() async {
    try {
      final url = await localDataSource.getBaseUrl();
      return Right(url);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveBaseUrl(String url) async {
    try {
      await localDataSource.saveBaseUrl(url);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getWifiIP() async {
    try {
      final ip = await localDataSource.getWifiIP();
      return Right(ip);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
