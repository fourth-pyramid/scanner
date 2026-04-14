import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/login_repository.dart';

/// Use case for user login
class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  const LoginUseCase({required this.repository});
  final LoginRepository repository;

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async =>
      await repository.login(
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
