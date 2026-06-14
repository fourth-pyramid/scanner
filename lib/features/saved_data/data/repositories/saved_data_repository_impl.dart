import 'package:dartz/dartz.dart';
import 'package:qrscanner/core/appStorage/my_scans_model.dart';
import 'package:qrscanner/core/errors/exceptions.dart';
import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/features/saved_data/data/datasources/saved_data_remote_datasource.dart';
import 'package:qrscanner/features/saved_data/data/models/saved_scan_model_mapper.dart';
import 'package:qrscanner/features/saved_data/domain/entities/saved_scan_entity.dart';
import 'package:qrscanner/features/saved_data/domain/repositories/saved_data_repository.dart';

/// Implementation of SavedDataRepository
class SavedDataRepositoryImpl implements SavedDataRepository {
  SavedDataRepositoryImpl({required this.remoteDataSource});
  final SavedDataRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<SavedScanEntity>>> getSavedScans() async {
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
