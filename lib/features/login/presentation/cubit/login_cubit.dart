import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/login_usecase.dart';
import 'login_state.dart';

/// Cubit for Login feature
/// Only handles UI state and calls UseCases - no business logic
class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required this.loginUseCase}) : super(LoginInitial());
  final LoginUseCase loginUseCase;

  // Controllers for form fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool get isLoading => state is LoginLoading;

  /// Perform login
  Future<bool> login() async {
    // Prevent duplicate login attempts
    if (isLoading) return false;

    // Form validation
    if (!formKey.currentState!.validate()) return false;

    emit(LoginLoading());

    final phoneType = Platform.isAndroid ? 'Samsung' : 'iPhone';

    final result = await loginUseCase(
      LoginParams(
        email: emailController.text.trim(),
        password: passwordController.text,
        phoneType: phoneType,
      ),
    );

    return result.fold(
      (failure) {
        emit(LoginError(message: failure.message));
        return false;
      },
      (user) {
        emit(LoginSuccess(token: user.token ?? '', userName: user.name));
        return true;
      },
    );
  }

  /// Static method to get cubit from context
  static LoginCubit of(BuildContext context) =>
      BlocProvider.of<LoginCubit>(context);

  @override
  Future<void> close() {
    emailController.dispose();
    passwordController.dispose();
    return super.close();
  }
}
