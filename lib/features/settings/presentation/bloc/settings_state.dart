part of 'settings_bloc.dart';

// ponytail: standard 6 states for settings
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoaded extends SettingsState {
  const SettingsLoaded({this.baseUrl});
  final String? baseUrl;

  @override
  List<Object?> get props => [baseUrl];
}

class SettingsSaved extends SettingsState {}

class SettingsError extends SettingsState {
  const SettingsError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class SettingsEmpty extends SettingsState {}

class SettingsRefreshing extends SettingsState {}
