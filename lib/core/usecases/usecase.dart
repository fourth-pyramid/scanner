import 'package:dartz/dartz.dart';

import 'package:qrscanner/core/errors/failures.dart';

/// Abstract base class for all use cases
/// [Type] - The return type
/// [Params] - The parameters type
///
/// Usage:
/// ```dart
/// class GetUserUseCase extends UseCase<User, GetUserParams> {
///   @override
///   Future<Either<Failure, User>> call(GetUserParams params) async {
///     // implementation
///   }
/// }
/// ```
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use case for operations that don't need parameters
/// Usage:
/// ```dart
/// class GetAllUsersUseCase extends NoParamsUseCase<List<User>> {
///   @override
///   Future<Either<Failure, List<User>>> call(NoParams params) async {
///     // implementation
///   }
/// }
/// ```
abstract class NoParamsUseCase<T> extends UseCase<T, NoParams> {
  @override
  Future<Either<Failure, T>> call(NoParams params);
}

/// Use case for stream-based operations
abstract class StreamUseCase<T, Params> {
  Stream<Either<Failure, T>> call(Params params);
}

/// Parameter class for use cases that don't need parameters
class NoParams {
  @override
  bool operator ==(Object other) => other is NoParams;

  @override
  int get hashCode => 0;
}
