import 'package:equatable/equatable.dart';

/// Base Failure class for Domain Layer
/// Pure Dart - no Flutter dependencies
abstract class Failure extends Equatable {
  const Failure({required this.message, this.statusCode});
  final String message;
  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// Server failure when API call fails
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

/// Cache failure when local storage fails
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.statusCode});
}

/// Network failure when no internet connection
class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.statusCode});
}

/// Validation failure for input validation errors
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.statusCode});
}

/// Unexpected failure for unhandled errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message, super.statusCode});
}
