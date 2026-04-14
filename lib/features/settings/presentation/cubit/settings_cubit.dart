import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_settings_usecase.dart';
import '../../domain/usecases/get_wifi_ip_usecase.dart';
import '../../domain/usecases/save_settings_usecase.dart';
import 'settings_state.dart';

/// Cubit for Settings feature
/// Only handles UI state and calls UseCases - no business logic
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required this.getSettingsUseCase,
    required this.saveSettingsUseCase,
    required this.getWifiIpUseCase,
  }) : super(SettingsInitial());
  final GetSettingsUseCase getSettingsUseCase;
  final SaveSettingsUseCase saveSettingsUseCase;
  final GetWifiIpUseCase getWifiIpUseCase;

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

  /// Auto-detect Wi-Fi IP
  Future<void> getWifiIp() async {
    final result = await getWifiIpUseCase(NoParams());

    result.fold(
      (failure) {
        // Silently fail for IP detection
      },
      (ip) {
        if (ip != null && ip.isNotEmpty) {
          ipController.text = ip;
          emit(SettingsWifiIpDetected(ip: ip));
          emit(SettingsLoaded(baseUrl: ip));
        }
      },
    );
  }

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
