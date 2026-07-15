import 'package:dio/dio.dart';

import 'package:qrscanner/core/dioHelper/dio_helper.dart';
import 'package:qrscanner/core/errors/exceptions.dart';

/// Remote data source for card type feature
abstract class CardTypeRemoteDataSource {
  Future<Map<String, dynamic>> getCategories();
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

  // ponytail: removed clearData remote source implementation
}
