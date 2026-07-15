import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qrscanner/core/usecases/usecase.dart';
import 'package:qrscanner/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:qrscanner/features/settings/domain/usecases/save_settings_usecase.dart';

part 'settings_event.dart';
part 'settings_state.dart';

// ponytail: bloc for settings feature
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required this.getSettingsUseCase,
    required this.saveSettingsUseCase,
  }) : super(SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<SaveSettingsEvent>(_onSaveSettings);
    on<UpdateAddressEvent>(_onUpdateAddress);
  }

  final GetSettingsUseCase getSettingsUseCase;
  final SaveSettingsUseCase saveSettingsUseCase;

  final TextEditingController ipController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final result = await getSettingsUseCase(NoParams());

    result.fold(
      (failure) => emit(SettingsError(message: failure.message)),
      (baseUrl) {
        if (baseUrl != null && baseUrl.isNotEmpty) {
          ipController.text = _cleanUrl(baseUrl);
        }
        emit(SettingsLoaded(baseUrl: baseUrl));
      },
    );
  }

  Future<void> _onSaveSettings(
    SaveSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final text = ipController.text.trim();

    final result = await saveSettingsUseCase(SaveSettingsParams(url: text));

    result.fold(
      (failure) => emit(SettingsError(message: failure.message)),
      (_) => emit(SettingsSaved()),
    );
  }

  void _onUpdateAddress(
    UpdateAddressEvent event,
    Emitter<SettingsState> emit,
  ) {
    emit(SettingsLoaded(baseUrl: event.address));
  }

  String _cleanUrl(String url) => url
      .replaceAll('http://', '')
      .replaceAll('https://', '')
      .replaceAll('/api/v1', '')
      .replaceAll('/', '')
      .trim();

  @override
  Future<void> close() {
    ipController.dispose();
    return super.close();
  }
}
