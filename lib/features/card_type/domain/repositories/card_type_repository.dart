import 'package:dartz/dartz.dart';
import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/features/card_type/domain/entities/category_entity.dart';

/// Repository contract for card types/categories
/// Defined in Domain Layer - implemented in Data Layer
abstract class CardTypeRepository {
  /// Get all categories
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
  
  /// Clear all data
  Future<Either<Failure, Unit>> clearData();
}
