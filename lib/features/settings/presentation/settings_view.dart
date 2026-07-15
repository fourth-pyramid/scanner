import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:qrscanner/core/router/router.dart';
import 'package:qrscanner/core/theme/app_colors.dart';
import 'package:qrscanner/core/theme/app_text_styles.dart';
import 'package:qrscanner/core/widgets/custom_button.dart';
import 'package:qrscanner/core/widgets/custom_text_field.dart';
import 'package:qrscanner/core/widgets/server_type_indicator.dart';
import 'package:qrscanner/features/login/presentation/login_view.dart';
import 'package:qrscanner/features/settings/presentation/bloc/settings_bloc.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => GetIt.I<SettingsBloc>()..add(const LoadSettingsEvent()),
    child: Scaffold(
      backgroundColor: colorBackground,
      appBar: AppBar(
        title: Text(
          'Server Settings',
          style: AppTextStyles.titleMedium.copyWith(color: colorTextPrimary),
        ),
        backgroundColor: colorSurface,
        foregroundColor: colorPrimary,
        centerTitle: true,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: colorDivider),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<SettingsBloc, SettingsState>(
          listener: (context, state) {
            if (state is SettingsSaved) {
              unawaited(MagicRouter.navigateToReplacment(const LogInView()));
            }
          },
          buildWhen: (previous, current) =>
              previous.runtimeType != current.runtimeType,
          builder: (context, state) {
            final bloc = context.read<SettingsBloc>();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: bloc.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Header ───
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colorPrimary.withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.dns_outlined,
                          size: 34,
                          color: colorPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Configure Server',
                        style: AppTextStyles.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Enter the server address to connect to the system',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ─── Card ───
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorBorder, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: colorPrimary.withAlpha(10),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Server Address',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: colorTextSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            hint: '192.168.x.x:8000 or domain.com',
                            controller: bloc.ipController,
                            prefixIcon: const Icon(
                              Icons.lan_outlined,
                              size: 20,
                            ),
                            onChanged: (val) {
                              bloc.add(UpdateAddressEvent(val));
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a server address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          BlocSelector<SettingsBloc, SettingsState, String>(
                            selector: (state) => bloc.ipController.text.trim(),
                            builder: (context, ipText) => ServerTypeIndicator(
                              text: ipText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ─── Save Button ───
                    CustomButton(
                      text: 'Save & Continue',
                      isIcon: true,
                      icon: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPress: () {
                        if (bloc.formKey.currentState!.validate()) {
                          bloc.add(const SaveSettingsEvent());
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}
