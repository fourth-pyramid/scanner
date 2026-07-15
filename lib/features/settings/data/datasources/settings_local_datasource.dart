import 'dart:async';

// ponytail: removed network_info_plus import

import 'package:qrscanner/core/appStorage/app_storage.dart';
import 'package:qrscanner/core/dioHelper/dio_helper.dart';
import 'package:qrscanner/core/errors/exceptions.dart';

/// Local data source for settings feature
abstract class SettingsLocalDataSource {
  Future<String?> getBaseUrl();
  Future<void> saveBaseUrl(String url);
}

/// Implementation of local data source
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  // ponytail: removed NetworkInfo instantiation

  // Pre-compile regex for better performance
  static final RegExp _ipPattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}(:\d+)?$');

  @override
  Future<String?> getBaseUrl() async => AppStorage.getBaseUrl;

  @override
  Future<void> saveBaseUrl(String url) async {
    try {
      final text = url.trim();

      final previousUrl = AppStorage.getBaseUrl;

      if (text.isEmpty) {
        // Default to production if empty
        const baseUrl = 'https://bestscan.store';
        if (previousUrl != baseUrl) {
          await AppStorage.clearUserSession();
        }
        await AppStorage.cacheBaseUrl(baseUrl);
        DioHelper.updateBaseUrl(baseUrl);
        return;
      }

      // Detect if user wrote IP -> Local
      if (_isIP(text)) {
        final baseUrl = 'http://$text';
        if (previousUrl != baseUrl) {
          await AppStorage.clearUserSession();
        }
        await AppStorage.cacheBaseUrl(baseUrl);
        DioHelper.updateBaseUrl(baseUrl);
        return;
      }

      // Otherwise treat it as full domain -> Production
      final cleaned = _cleanUrl(text);
      final baseUrl = 'https://$cleaned';

      if (previousUrl != baseUrl) {
        await AppStorage.clearUserSession();
      }
      await AppStorage.cacheBaseUrl(baseUrl);
      DioHelper.updateBaseUrl(baseUrl);
    } on Exception catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  // ponytail: removed getWifiIP implementation

  /// Detect Local IP (e.g., 192.168.x.x)
  bool _isIP(String text) => _ipPattern.hasMatch(text);

  /// Clean full URL to only the domain/IP
  String _cleanUrl(String url) => url
      .replaceAll('http://', '')
      .replaceAll('https://', '')
      .replaceAll('/api/v1', '')
      .replaceAll('/', '')
      .trim();
}
