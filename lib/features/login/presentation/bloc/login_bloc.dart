import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qrscanner/features/login/domain/usecases/login_usecase.dart';

part 'login_event.dart';
part 'login_state.dart';

// ponytail: bloc for login feature
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required this.loginUseCase}) : super(LoginInitial()) {
    on<LoginSubmitEvent>(_onLoginSubmit);
  }

  final LoginUseCase loginUseCase;

  // Controllers for form fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Future<void> _onLoginSubmit(
    LoginSubmitEvent event,
    Emitter<LoginState> emit,
  ) async {
    if (state is LoginLoading) return;
    if (!formKey.currentState!.validate()) return;

    emit(LoginLoading());

    final phoneType = Platform.isAndroid ? 'Samsung' : 'iPhone';

    final result = await loginUseCase(
      LoginParams(
        email: emailController.text.trim(),
        password: passwordController.text,
        phoneType: phoneType,
      ),
    );

    result.fold(
      (failure) => emit(LoginError(message: failure.message)),
      (user) => emit(LoginSuccess(token: user.token ?? '', userName: user.name)),
    );
  }

  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    return super.close();
  }
}
