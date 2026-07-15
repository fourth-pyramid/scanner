import 'package:dio/dio.dart';
import 'package:qrscanner/core/dioHelper/dio_helper.dart';
import 'package:qrscanner/core/errors/exceptions.dart';

// ponytail: remote datasource for card scanner
abstract class CardScannerRemoteDataSource {
  Future<void> clearData();
}

class CardScannerRemoteDataSourceImpl implements CardScannerRemoteDataSource {
  @override
  Future<void> clearData() async {
    try {
      await DioHelper.post('delete', isAuth: true, body: {});
    } on DioException catch (e) {
      throw NetworkException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    } on Exception catch (e) {
      if (e is AppException) rethrow;
      throw ServerException(message: e.toString());
    }
  }
}
