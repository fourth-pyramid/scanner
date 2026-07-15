import 'package:equatable/equatable.dart';

/// States for SettingsCubit
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SettingsInitial extends SettingsState {}

/// Settings loaded state
class SettingsLoaded extends SettingsState {
  const SettingsLoaded({this.baseUrl});
  final String? baseUrl;

  @override
  List<Object?> get props => [baseUrl];
}

/// Settings saved state
class SettingsSaved extends SettingsState {}

// ponytail: removed SettingsWifiIpDetected state

/// Error state
class SettingsError extends SettingsState {
  const SettingsError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Empty state
class SettingsEmpty extends SettingsState {}

/// Refreshing state
class SettingsRefreshing extends SettingsState {}
