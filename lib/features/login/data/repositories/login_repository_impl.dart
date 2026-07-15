import 'package:dartz/dartz.dart';
import 'package:qrscanner/core/appStorage/app_storage.dart';
import 'package:qrscanner/core/appStorage/user_model.dart';
import 'package:qrscanner/core/errors/exceptions.dart';
import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/network/network_info.dart';
import 'package:qrscanner/features/login/data/datasources/login_remote_datasource.dart';
import 'package:qrscanner/features/login/data/models/user_model_mapper.dart';
import 'package:qrscanner/features/login/domain/entities/user_entity.dart';
import 'package:qrscanner/features/login/domain/repositories/login_repository.dart';

/// Implementation of LoginRepository
class LoginRepositoryImpl implements LoginRepository {
  LoginRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final LoginRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
    required String phoneType,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection available.'));
    }
    try {
      final data = await remoteDataSource.login(
        email: email,
        password: password,
        phoneType: phoneType,
      );

      final message = (data['massage'] as String?) ?? 'login failed';

      if (data['status'] == 1) {
        try {
          final userModel = UserModel.fromJson(data);
          await AppStorage.cacheUserInfo(userModel);
          return Right(userModel.toEntity());
        } on Object catch (_) {
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
