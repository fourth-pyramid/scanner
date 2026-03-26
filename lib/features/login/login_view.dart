import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qrscanner/common_component/custom_button.dart';
import 'package:qrscanner/common_component/custom_text_field.dart';
import 'package:qrscanner/constant.dart';
import 'package:qrscanner/features/login/login_controller.dart';
import 'package:qrscanner/features/login/login_states.dart';

class LogInView extends StatelessWidget {
  const LogInView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LogInController(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Login'),
          centerTitle: true,
          backgroundColor: colorPrimary,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          children: [
            BlocBuilder<LogInController, LoginStates>(
              builder: (context, state) => Form(
                key: LogInController.of(context).formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 15,
                      ),
                      child: Column(
                        children: [
                          CustomTextField(
                            hint: 'Enter your email',
                            controller: LogInController.of(context).email,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          CustomTextField(
                            hint: 'Enter your password',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            secure: true,
                            controller: LogInController.of(context).password,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      // Optimization: Only rebuild button on state type change
                      child: BlocBuilder<LogInController, LoginStates>(
                        buildWhen: (previous, current) =>
                            previous.runtimeType != current.runtimeType,
                        builder: (context, state) {
                          if (state is LoginLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else {
                            return CustomButton(
                              text: 'Login',
                              onPress: () => login(context),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void login(BuildContext context) {
    if (LogInController.of(context).formKey.currentState!.validate()) {
      LogInController.of(context).login();
    }
  }
}
