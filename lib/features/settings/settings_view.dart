import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qrscanner/common_component/custom_button.dart';
import 'package:qrscanner/common_component/custom_text_field.dart';
import 'package:qrscanner/common_component/server_type_indicator.dart';
import 'package:qrscanner/constant.dart';
import 'package:qrscanner/core/router/router.dart';
import 'package:qrscanner/features/login/login_view.dart';
import 'package:qrscanner/features/settings/settings_controller.dart';
import 'package:qrscanner/features/settings/settings_states.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsController()..loadCurrentSettings(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          foregroundColor: Colors.white,
          centerTitle: true,
          backgroundColor: colorPrimary,
        ),
        body: SafeArea(
          child: ListView(
            children: [
              // const CustomAppBar(text: 'Settings'),
              // Optimization: Only rebuild when settings state changes
              BlocBuilder<SettingsController, SettingsStates>(
                buildWhen: (previous, current) =>
                    previous.runtimeType != current.runtimeType,
                builder: (context, state) {
                  final controller = SettingsController.of(context);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20.0,
                      horizontal: 10,
                    ),
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // -------- Text Field --------
                          CustomTextField(
                            hint:
                                'Enter IP (192.168.x.x:8000) or domain (bestscan.store)',
                            labelText: 'Server Address',
                            controller: controller.ipController,
                            onChanged: (_) {
                              // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                              controller.emit(SettingsLoaded());
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter server address';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 10),

                          // -------- Server Type Detector --------
                          // Optimization: Use separate widget to minimize rebuilds
                          ServerTypeIndicator(
                            text: controller.ipController.text.trim(),
                          ),

                          const SizedBox(height: 30),

                          // -------- Save Button --------
                          CustomButton(
                            text: 'Save',
                            onPress: () {
                              if (controller.formKey.currentState!.validate()) {
                                controller.saveSettings();
                                MagicRouter.navigateToReplacment(
                                  const LogInView(),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
