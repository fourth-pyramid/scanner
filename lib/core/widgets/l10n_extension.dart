import 'package:flutter/material.dart';
import 'package:qrscanner/l10n/app_localizations.dart';

// ponytail: context extension for clean and quick l10n access
extension LocalizationsExt on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
