import 'package:dartz/dartz.dart';
import 'package:qrscanner/core/appStorage/get_categories_model.dart';
import 'package:qrscanner/core/errors/exceptions.dart';
import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/features/card_type/data/datasources/card_type_remote_datasource.dart';
import 'package:qrscanner/features/card_type/data/models/category_model_mapper.dart';
import 'package:qrscanner/features/card_type/domain/entities/category_entity.dart';
import 'package:qrscanner/features/card_type/domain/repositories/card_type_repository.dart';

/// Implementation of CardTypeRepository
class CardTypeRepositoryImpl implements CardTypeRepository {
  CardTypeRepositoryImpl({required this.remoteDataSource});
  final CardTypeRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    try {
      final data = await remoteDataSource.getCategories();
      final model = GetCategoriesModel.fromJson(data);
      return Right(model.toEntityList());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearData() async {
    try {
      await remoteDataSource.clearData();
      return const Right(unit);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
