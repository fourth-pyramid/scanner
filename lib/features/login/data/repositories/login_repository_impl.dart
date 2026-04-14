import 'package:dartz/dartz.dart';

import '../../../../core/appStorage/app_storage.dart';
import '../../../../core/appStorage/user_model.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/login_repository.dart';
import '../datasources/login_remote_datasource.dart';
import '../models/user_model_mapper.dart';

/// Implementation of LoginRepository
class LoginRepositoryImpl implements LoginRepository {
  LoginRepositoryImpl({required this.remoteDataSource});
  final LoginRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
    required String phoneType,
  }) async {
    try {
      final data = await remoteDataSource.login(
        email: email,
        password: password,
        phoneType: phoneType,
      );

      final message = data['massage'] ?? 'login failed';

      if (data['status'] == 1) {
        try {
          final userModel = UserModel.fromJson(data);
          await AppStorage.cacheUserInfo(userModel);
          return Right(userModel.toEntity());
        } catch (e) {
          return const Left(
            ValidationFailure(message: 'Invalid user data received'),
          );
        }
      } else {
        return Left(ServerFailure(message: message));
      }
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
