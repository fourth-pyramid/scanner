import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:qrscanner/features/settings/domain/usecases/save_settings_usecase.dart';
import 'package:qrscanner/features/settings/presentation/cubit/settings_state.dart';

/// Cubit for Settings feature
/// Only handles UI state and calls UseCases - no business logic
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required this.getSettingsUseCase,
    required this.saveSettingsUseCase,
  }) : super(SettingsInitial());
  final GetSettingsUseCase getSettingsUseCase;
  final SaveSettingsUseCase saveSettingsUseCase;

  final TextEditingController ipController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  /// Load current settings
  Future<void> loadSettings() async {
    final result = await getSettingsUseCase(NoParams());

    result.fold((failure) => emit(SettingsError(message: failure.message)), (
      baseUrl,
    ) {
      if (baseUrl != null && baseUrl.isNotEmpty) {
        ipController.text = _cleanUrl(baseUrl);
      }
      emit(SettingsLoaded(baseUrl: baseUrl));
    });
  }

  // ponytail: removed unused getWifiIp detection logic

  /// Save settings
  Future<bool> saveSettings() async {
    final text = ipController.text.trim();

    final result = await saveSettingsUseCase(SaveSettingsParams(url: text));

    return result.fold(
      (failure) {
        emit(SettingsError(message: failure.message));
        return false;
      },
      (_) {
        emit(SettingsSaved());
        return true;
      },
    );
  }

  /// Clean full URL to only the domain/IP
  String _cleanUrl(String url) => url
      .replaceAll('http://', '')
      .replaceAll('https://', '')
      .replaceAll('/api/v1', '')
      .replaceAll('/', '')
      .trim();

  /// Static method to get cubit from context
  static SettingsCubit of(BuildContext context) =>
      BlocProvider.of<SettingsCubit>(context);

  @override
  Future<void> close() {
    ipController.dispose();
    return super.close();
  }
}
