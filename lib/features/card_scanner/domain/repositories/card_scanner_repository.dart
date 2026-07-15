import 'package:dartz/dartz.dart';
import 'package:qrscanner/core/errors/failures.dart';

// ponytail: repository interface for card scanner
abstract class CardScannerRepository {
  Future<Either<Failure, void>> clearData();
}
