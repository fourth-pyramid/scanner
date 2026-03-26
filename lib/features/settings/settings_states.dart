import 'package:equatable/equatable.dart';

abstract class SettingsStates extends Equatable {
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsStates {}

class SettingsLoaded extends SettingsStates {}

class SettingsSaved extends SettingsStates {}
