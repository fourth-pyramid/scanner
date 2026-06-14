import 'package:dio/dio.dart';

import 'package:qrscanner/core/dioHelper/dio_helper.dart';
import 'package:qrscanner/core/errors/exceptions.dart';

/// Remote data source for saved data feature
abstract class SavedDataRemoteDataSource {
  Future<Map<String, dynamic>> getSavedScans();
}

/// Implementation of remote data source
class SavedDataRemoteDataSourceImpl implements SavedDataRemoteDataSource {
  @override
  Future<Map<String, dynamic>> getSavedScans() async {
    try {
      final response = await DioHelper.get('history');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw NetworkException(
        message: e.message ?? 'Network error occurred',
        statusCode: e.response?.statusCode,
      );
    } on Exception catch (e) {
      // Check if already an AppException to preserve the original message
      if (e is AppException) {
        rethrow;
      }
      throw ServerException(message: e.toString());
    }
  }
}
