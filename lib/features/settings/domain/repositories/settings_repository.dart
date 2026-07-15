import 'package:dartz/dartz.dart';
import 'package:qrscanner/core/errors/failures.dart';

/// Repository contract for settings
/// Defined in Domain Layer - implemented in Data Layer
abstract class SettingsRepository {
  /// Get current IP/base URL
  Future<Either<Failure, String?>> getBaseUrl();
  
  /// Save base URL
  Future<Either<Failure, Unit>> saveBaseUrl(String url);
  
  // ponytail: removed getWifiIP definition
}
