part of 'login_bloc.dart';

// ponytail: standard 6 states for login
abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  const LoginSuccess({required this.token, this.userName});
  final String token;
  final String? userName;

  @override
  List<Object?> get props => [token, userName];
}

class LoginError extends LoginState {
  const LoginError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}

class LoginEmpty extends LoginState {}

class LoginRefreshing extends LoginState {}
