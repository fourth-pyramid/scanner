part of 'settings_bloc.dart';

// ponytail: standard bloc events for settings
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

class SaveSettingsEvent extends SettingsEvent {
  const SaveSettingsEvent();
}

class UpdateAddressEvent extends SettingsEvent {
  const UpdateAddressEvent(this.address);
  final String address;

  @override
  List<Object?> get props => [address];
}
