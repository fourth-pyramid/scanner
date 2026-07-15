import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qrscanner/core/theme/app_colors.dart';
import 'package:qrscanner/core/theme/app_text_styles.dart';
import 'package:qrscanner/core/widgets/custom_button.dart';
import 'package:qrscanner/core/widgets/custom_text_field.dart';
import 'package:qrscanner/core/widgets/snack_bar.dart';
import 'package:qrscanner/features/extract_image/presentation/cubit/extract_image_cubit.dart';
import 'package:qrscanner/features/extract_image/presentation/cubit/extract_image_state.dart';
import 'package:qrscanner/features/extract_image/presentation/pages/qr_camera_page.dart';

class ExtractImagePage extends StatefulWidget {
  const ExtractImagePage({required this.categoryId, super.key, this.scanType});
  final String? scanType;
  final int categoryId;

  @override
  State<ExtractImagePage> createState() => _ExtractImagePageState();
}

class _ExtractImagePageState extends State<ExtractImagePage> {
  late final TextEditingController _pinController;
  late final TextEditingController _serialController;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
    _serialController = TextEditingController();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  Future<void> _captureImage(BuildContext context) async {
    final capturedFile = await QrCameraPage.capture(context);
    if (capturedFile == null) return;

    final capturedPath = capturedFile.path.replaceFirst('file://', '');
    final sourceFile = File(capturedPath);

    if (!sourceFile.existsSync()) {
      if (context.mounted) {
        showSnackBar('Failed to save image', color: Colors.red);
      }
      return;
    }

    if (context.mounted) {
      context.read<ExtractImageCubit>().setImage(sourceFile);
      await context.read<ExtractImageCubit>().processImage();
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<ExtractImageCubit, ExtractImageState>(
      listener: (context, state) {
        if (state is ScanResultLoaded) {
          _pinController.text = state.pin ?? '';
          _serialController.text = state.serial ?? '';
        }
        if (state is ScanError && state.message != null) {
          showSnackBar(state.message!, color: Colors.red);
        }
        if (state is ScanSuccess) {
          showSnackBar('Saved successfully', color: Colors.green);
          _pinController.clear();
          _serialController.clear();
          // Clear image and reset state
          context.read<ExtractImageCubit>().reset();
        }
      },
      child: Scaffold(
        backgroundColor: colorBackground,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePreview(),
                const SizedBox(height: 20),
                _buildCameraButton(),
                const SizedBox(height: 24),
                _buildFieldsCard(),
                const SizedBox(height: 24),
                _buildSaveButton(),
                const SizedBox(height: 20),
                const _HistoryCountWidget(),
              ],
            ),
          ),
        ),
      ),
  );

  PreferredSizeWidget _buildAppBar() => AppBar(
    title: Text(
      widget.scanType != null ? 'Scan: ${widget.scanType}' : 'Scan Card',
      style: AppTextStyles.titleMedium,
    ),
    backgroundColor: colorSurface,
    foregroundColor: colorPrimary,
    centerTitle: true,
    elevation: 0,
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: Divider(height: 1, color: colorDivider),
    ),
  );

  Widget _buildImagePreview() =>
      BlocBuilder<ExtractImageCubit, ExtractImageState>(
        buildWhen: (previous, current) =>
            current is ImagePickedSuccess || current is ExtractImageInitial,
        builder: (context, state) {
          final cubit = context.read<ExtractImageCubit>();
          final previewFile = cubit.currentImage;

          return Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: BoxDecoration(
              color: colorSurfaceVariant,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: previewFile != null ? colorAccent : colorBorder,
                width: previewFile != null ? 2 : 1.2,
              ),
            ),
            child: previewFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: RepaintBoundary(
                      child: Image.file(previewFile, fit: BoxFit.contain),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 52,
                        color: colorTextHint,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No image selected',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap "Capture Card" to photograph the card',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
          );
        },
      );

  Widget _buildCameraButton() =>
      BlocBuilder<ExtractImageCubit, ExtractImageState>(
        buildWhen: (previous, current) =>
            current is Scanning || previous is Scanning,
        builder: (context, state) {
          final isScanning = state is Scanning;
          return CustomButton(
            isIcon: !isScanning,
            icon: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 22,
            ),
            text: isScanning ? '' : 'Capture Card',
            isLoading: isScanning,
            onPress: () => _captureImage(context),
          );
        },
      );

  Widget _buildFieldsCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: colorSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colorBorder, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: colorPrimary.withAlpha(10),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PIN
        Text(
          'Card PIN',
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: colorTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _pinController,
          hint: 'PIN number',
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.pin_outlined, size: 20),
          onChanged: (value) {
            context.read<ExtractImageCubit>().updatePin(value);
          },
        ),

        const SizedBox(height: 20),

        // SERIAL
        Text(
          'Serial Number',
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: colorTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _serialController,
          hint: 'Serial number',
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.tag_outlined, size: 20),
          onChanged: (value) {
            context.read<ExtractImageCubit>().updateSerial(value);
          },
        ),
      ],
    ),
  );

  Widget _buildSaveButton() =>
      BlocBuilder<ExtractImageCubit, ExtractImageState>(
        buildWhen: (previous, current) =>
            current is SubmitLoading || previous is SubmitLoading,
        builder: (context, state) {
          final isLoading = state is SubmitLoading;
          return CustomButton(
            text: isLoading ? '' : 'Save Record',
            isLoading: isLoading,
            isIcon: !isLoading,
            icon: const Icon(
              Icons.save_outlined,
              color: Colors.white,
              size: 20,
            ),
            onPress: () async {
              final cubit = context.read<ExtractImageCubit>();

              if (cubit.currentImage == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Please capture a card image first.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: colorWarning,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                return;
              }

              // Update cubit with current text field values
              cubit
                ..updatePin(_pinController.text)
                ..updateSerial(_serialController.text);

              // Validate PIN and Serial are not empty
              if (_pinController.text.trim().isEmpty ||
                  _serialController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'PIN and Serial number are required.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: colorWarning,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
                return;
              }

              final phoneType = Platform.isAndroid ? 'Samsung' : 'iPhone';
              await cubit.submitScan(
                categoryId: widget.categoryId,
                phoneType: phoneType,
              );
            },
          );
        },
      );

}

class _HistoryCountWidget extends StatelessWidget {
  const _HistoryCountWidget();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ExtractImageCubit, ExtractImageState>(
        buildWhen: (previous, current) =>
            current is HistoryCountLoaded ||
            current is ScanSuccess ||
            current is ExtractImageInitial,
        builder: (context, state) {
          final cubit = context.read<ExtractImageCubit>();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorPrimary.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorPrimary.withAlpha(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: colorPrimary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total saved cards: ${cubit.historyCount}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: colorPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      );
}
