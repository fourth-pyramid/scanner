import 'package:dartz/dartz.dart';
import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/features/login/domain/entities/user_entity.dart';

/// Repository contract for authentication
/// Defined in Domain Layer - implemented in Data Layer
abstract class LoginRepository {
  /// Login user with email and password
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
    required String phoneType,
  });
}
