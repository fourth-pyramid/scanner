import 'package:flutter/material.dart';
import 'package:qrscanner/core/appStorage/app_storage.dart';
import 'package:qrscanner/features/card_scanner/card_scanner_view.dart';
import 'package:qrscanner/features/login/presentation/login_view.dart';
import 'package:qrscanner/features/settings/presentation/settings_view.dart';

/// Chooses the first screen based on saved server URL and login token.
class AppStartup {
  static Widget resolveInitialScreen() {
    if (!AppStorage.hasBaseUrl) {
      return const SettingsView();
    }

    if (AppStorage.hasValidSession) {
      return const CardScannerView();
    }

    return const LogInView();
  }
}
