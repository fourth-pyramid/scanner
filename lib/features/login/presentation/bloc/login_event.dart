part of 'login_bloc.dart';

// ponytail: standard bloc events for login
abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class LoginSubmitEvent extends LoginEvent {
  const LoginSubmitEvent();
}
