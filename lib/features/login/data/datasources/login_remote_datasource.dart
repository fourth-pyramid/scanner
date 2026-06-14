import 'dart:async';

import 'package:dio/dio.dart';

import 'package:qrscanner/core/dioHelper/dio_helper.dart';
import 'package:qrscanner/core/errors/exceptions.dart';

/// Remote data source for login feature
abstract class LoginRemoteDataSource {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String phoneType,
  });
}

/// Implementation of remote data source
class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String phoneType,
  }) async {
    try {
      final body = {
        'email': email.trim(),
        'password': password,
        'phone': phoneType,
      };

      final response = await DioHelper.post('login', isAuth: false, body: body);
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
