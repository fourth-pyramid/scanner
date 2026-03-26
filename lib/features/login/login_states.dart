import 'package:equatable/equatable.dart';
import 'package:qrscanner/core/appStorage/user_model.dart';

abstract class LoginStates extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginInit extends LoginStates {}

class LoginLoading extends LoginStates {}

class LoginSuccess extends LoginStates {
  final UserModel userModel;
  LoginSuccess(this.userModel);

  @override
  List<Object?> get props => [userModel];
}

class LoginError extends LoginStates {}
