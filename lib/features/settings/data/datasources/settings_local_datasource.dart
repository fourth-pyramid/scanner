import 'dart:async';

import 'package:network_info_plus/network_info_plus.dart';

import '../../../../core/appStorage/app_storage.dart';
import '../../../../core/dioHelper/dio_helper.dart';
import '../../../../core/errors/exceptions.dart';

/// Local data source for settings feature
abstract class SettingsLocalDataSource {
  Future<String?> getBaseUrl();
  Future<void> saveBaseUrl(String url);
  Future<String?> getWifiIP();
}

/// Implementation of local data source
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final NetworkInfo _networkInfo = NetworkInfo();

  // Pre-compile regex for better performance
  static final RegExp _ipPattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}(:\d+)?$');

  @override
  Future<String?> getBaseUrl() async => AppStorage.getBaseUrl;

  @override
  Future<void> saveBaseUrl(String url) async {
    try {
      final text = url.trim();

      if (text.isEmpty) {
        // Default to production if empty
        const baseUrl = 'https://bestscan.store';
        await AppStorage.cacheBaseUrl(baseUrl);
        DioHelper.updateBaseUrl(baseUrl);
        return;
      }

      // Detect if user wrote IP -> Local
      if (_isIP(text)) {
        final baseUrl = 'http://$text';
        await AppStorage.cacheBaseUrl(baseUrl);
        DioHelper.updateBaseUrl(baseUrl);
        return;
      }

      // Otherwise treat it as full domain -> Production
      final cleaned = _cleanUrl(text);
      final baseUrl = 'https://$cleaned';

      await AppStorage.cacheBaseUrl(baseUrl);
      DioHelper.updateBaseUrl(baseUrl);
    } on Exception catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<String?> getWifiIP() async {
    try {
      final wifiIP = await _networkInfo.getWifiIP();
      if (wifiIP != null && wifiIP.isNotEmpty) {
        return '$wifiIP:8000';
      }
      return null;
    } on Exception catch (e) {
      throw NetworkException(message: e.toString());
    }
  }

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
