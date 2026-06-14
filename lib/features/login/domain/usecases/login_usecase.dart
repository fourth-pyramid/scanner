import 'package:dartz/dartz.dart';

import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/login/domain/entities/user_entity.dart';
import 'package:qrscanner/features/login/domain/repositories/login_repository.dart';

/// Use case for user login
class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  const LoginUseCase({required this.repository});
  final LoginRepository repository;

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async =>
      repository.login(
        email: params.email,
        password: params.password,
        phoneType: params.phoneType,
      );
}

class LoginParams {
  const LoginParams({
    required this.email,
    required this.password,
    required this.phoneType,
  });
  final String email;
  final String password;
  final String phoneType;
}
