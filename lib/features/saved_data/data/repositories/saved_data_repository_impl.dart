import 'package:dartz/dartz.dart';

import '../../../../core/appStorage/my_scans_model.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/saved_scan_entity.dart';
import '../../domain/repositories/saved_data_repository.dart';
import '../datasources/saved_data_remote_datasource.dart';
import '../models/saved_scan_model_mapper.dart';

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
