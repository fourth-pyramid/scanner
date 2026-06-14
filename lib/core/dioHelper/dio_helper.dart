// ignore_for_file: avoid_classes_with_only_static_members

import 'package:dio/dio.dart';

import 'package:qrscanner/core/appStorage/app_storage.dart';

class DioHelper {
  static const _defaultBaseUrl = 'https://bestscan.store/api/v1/';

  static final Dio dioSingleton = Dio(
    BaseOptions(
      baseUrl: _defaultBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: false,
      validateStatus: (status) => status != null && status < 500,
      headers: {'Accept': 'application/json', 'Accept-Language': 'en'},
    ),
  );

  // Update base URL dynamically
  static void updateBaseUrl(String baseUrl) {
    var formattedUrl = baseUrl;
    if (!formattedUrl.endsWith('/')) formattedUrl += '/';
    if (!formattedUrl.contains('api/v1')) formattedUrl += 'api/v1/';
    dioSingleton.options.baseUrl = formattedUrl;
  }

  // Initialize with saved base URL or default
  static void initBaseUrl() {
    final savedBaseUrl = AppStorage.getBaseUrl;
    if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
      updateBaseUrl(savedBaseUrl);
    }
  }

  // POST request
  static Future<Response<dynamic>> post(
    String path, {
    required bool isAuth,
    FormData? formData,
    Map<String, dynamic>? body,
    void Function(int, int)? onSendProgress,
  }) {
    final headers = isAuth && AppStorage.getToken != null
        ? {'Authorization': 'Bearer ${AppStorage.getToken}'}
        : <String, dynamic>{};

    // Use JSON content-type when sending body, FormData has its own content-type
    final contentType = formData == null && body != null
        ? 'application/json'
        : null;

    final options = contentType != null
        ? Options(headers: {...headers, 'Content-Type': contentType})
        : Options(headers: headers.isNotEmpty ? headers : null);

    return dioSingleton.post(
      path,
      data: formData ?? body,
      options: options,
      onSendProgress: onSendProgress,
    );
  }

  // DELETE request
  static Future<Response<dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    bool isAuth = true,
  }) {
    final headers = isAuth && AppStorage.getToken != null
        ? {'Authorization': 'Bearer ${AppStorage.getToken}'}
        : null;

    return dioSingleton.delete(
      path,
      data: body,
      options: Options(headers: headers),
    );
  }

  // GET request
  static Future<Response<dynamic>> get(String path, {bool isAuth = true}) {
    final headers = isAuth && AppStorage.getToken != null
        ? {'Authorization': 'Bearer ${AppStorage.getToken}'}
        : null;

    return dioSingleton.get(path, options: Options(headers: headers));
  }
}
