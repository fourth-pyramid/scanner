import 'package:dio/dio.dart';

import '../../../../core/dioHelper/dio_helper.dart';
import '../../../../core/errors/exceptions.dart';

/// Remote data source for card type feature
abstract class CardTypeRemoteDataSource {
  Future<Map<String, dynamic>> getCategories();
  Future<void> clearData();
}

/// Implementation of remote data source
class CardTypeRemoteDataSourceImpl implements CardTypeRemoteDataSource {
  @override
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await DioHelper.get('category');
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

  @override
  Future<void> clearData() async {
    try {
      final response = await DioHelper.post('delete', true, body: {});
      final data = response.data as Map<String, dynamic>;

      if (data['status'] != 1) {
        final message = data['message'] ?? 'Unknown error';
        throw ServerException(message: message);
      }
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
