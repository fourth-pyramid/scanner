/// Base Exception class for handling errors
abstract class AppException implements Exception {
  const AppException({required this.message, this.statusCode});
  final String message;
  final int? statusCode;
}

/// Server exception when API call fails
class ServerException extends AppException {
  const ServerException({required super.message, super.statusCode});
}

/// Cache exception when local storage fails
class CacheException extends AppException {
  const CacheException({required super.message, super.statusCode});
}

/// Network exception when no internet connection
class NetworkException extends AppException {
  const NetworkException({required super.message, super.statusCode});
}

/// Validation exception for input validation errors
class ValidationException extends AppException {
  const ValidationException({required super.message, super.statusCode});
}
