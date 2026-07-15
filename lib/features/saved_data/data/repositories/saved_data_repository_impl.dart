import 'package:dartz/dartz.dart';
import 'package:qrscanner/core/errors/exceptions.dart';
import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/network/network_info.dart';
import 'package:qrscanner/features/saved_data/data/datasources/saved_data_remote_datasource.dart';
import 'package:qrscanner/features/saved_data/data/models/my_scans_model.dart';
import 'package:qrscanner/features/saved_data/data/models/saved_scan_model_mapper.dart';
import 'package:qrscanner/features/saved_data/domain/entities/saved_scan_entity.dart';
import 'package:qrscanner/features/saved_data/domain/repositories/saved_data_repository.dart';

/// Implementation of SavedDataRepository
class SavedDataRepositoryImpl implements SavedDataRepository {
  SavedDataRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final SavedDataRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, List<SavedScanEntity>>> getSavedScans() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection available.'));
    }
    try {
      final data = await remoteDataSource.getSavedScans();
      final model = MyScansModel.fromJson(data);
      return Right(model.toEntityList());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
