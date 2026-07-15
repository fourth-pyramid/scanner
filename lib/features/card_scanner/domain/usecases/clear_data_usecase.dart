import 'package:dartz/dartz.dart';
import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/card_scanner/domain/repositories/card_scanner_repository.dart';

// ponytail: usecase for clearing scanner data
class ClearDataUseCase extends NoParamsUseCase<void> {
  ClearDataUseCase({required this.repository});
  final CardScannerRepository repository;

  @override
  Future<Either<Failure, void>> call(NoParams params) => repository.clearData();
}
