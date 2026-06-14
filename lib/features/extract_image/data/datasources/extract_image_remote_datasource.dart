import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'package:qrscanner/core/dioHelper/dio_helper.dart';
import 'package:qrscanner/core/errors/exceptions.dart';

/// Remote data source for extract image feature
/// Handles API calls for scan submission and history count
abstract class ExtractImageRemoteDataSource {
  Future<void> submitScan({
    required String pin,
    required String serial,
    required String phoneType,
    required int categoryId,
    File? image,
  });

  Future<int> getHistoryCount();
}

/// Implementation of remote data source
class ExtractImageRemoteDataSourceImpl implements ExtractImageRemoteDataSource {
  @override
  Future<void> submitScan({
    required String pin,
    required String serial,
    required String phoneType,
    required int categoryId,
    File? image,
  }) async {
    try {
      final fields = <String, dynamic>{
        'pin': pin.replaceAll(' ', ''),
        'serial': serial.replaceAll(' ', ''),
        'phone_type': phoneType,
        'category_id': categoryId.toString(),
      };

      final formData = FormData.fromMap(fields);

      if (image != null && image.existsSync()) {
        final filename = p.basename(image.path);
        final multipartFile = await MultipartFile.fromFile(
          image.path,
          filename: filename,
        );
        formData.files.add(MapEntry('image', multipartFile));
      }

      final response = await DioHelper.post('scan', isAuth: true, formData: formData);

      if (response.data is! Map<String, dynamic>) {
        throw const ServerException(message: 'Invalid server response');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['status'] != 1) {
        final msg = data['massage'] ?? data['message'] ?? 'Error occurred';
        throw ServerException(message: msg.toString());
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

  @override
  Future<int> getHistoryCount() async {
    try {
      final response = await DioHelper.get('count');

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;

        if (data['status'] == 1 && data['data'] != null) {
          final rawData = data['data'];
          if (rawData is int) {
            return rawData;
          }
          return int.tryParse(rawData.toString()) ?? 0;
        }
      }

      return 0;
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
