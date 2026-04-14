import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/saved_scan_entity.dart';

/// Repository contract for saved data
/// Defined in Domain Layer - implemented in Data Layer
abstract class SavedDataRepository {
  /// Get all saved scans
  Future<Either<Failure, List<SavedScanEntity>>> getSavedScans();
}
