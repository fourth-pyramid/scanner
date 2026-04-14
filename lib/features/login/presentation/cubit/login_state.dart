import 'package:equatable/equatable.dart';

/// States for LoginCubit
abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class LoginInitial extends LoginState {}

/// Loading state
class LoginLoading extends LoginState {}

/// Success state with user data
class LoginSuccess extends LoginState {
  const LoginSuccess({required this.token, this.userName});
  final String token;
  final String? userName;

  @override
  List<Object?> get props => [token, userName];
}

/// Error state
class LoginError extends LoginState {
  const LoginError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}
