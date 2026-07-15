import 'package:dartz/dartz.dart';
import 'package:qrscanner/core/errors/exceptions.dart';
import 'package:qrscanner/core/errors/failures.dart';
import 'package:qrscanner/core/network/network_info.dart';
import 'package:qrscanner/features/card_scanner/data/datasources/card_scanner_remote_datasource.dart';
import 'package:qrscanner/features/card_scanner/domain/repositories/card_scanner_repository.dart';

// ponytail: repository implementation with connectivity check
class CardScannerRepositoryImpl implements CardScannerRepository {
  CardScannerRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CardScannerRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  @override
  Future<Either<Failure, void>> clearData() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(message: 'No internet connection available.'));
    }
    try {
      await remoteDataSource.clearData();
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message, statusCode: e.statusCode));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on Exception catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
