import 'dart:async';
import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qrscanner/core/theme/app_colors.dart';
import 'package:qrscanner/core/theme/app_text_styles.dart';
import 'package:qrscanner/core/widgets/snack_bar.dart';
import 'package:qrscanner/features/extract_image/presentation/bloc/extract_image_bloc.dart';

// Import refactored smaller widgets
import 'package:qrscanner/features/extract_image/presentation/widgets/camera_button_widget.dart';
import 'package:qrscanner/features/extract_image/presentation/widgets/fields_card_widget.dart';
import 'package:qrscanner/features/extract_image/presentation/widgets/history_count_widget.dart';
import 'package:qrscanner/features/extract_image/presentation/widgets/image_preview_widget.dart';
import 'package:qrscanner/features/extract_image/presentation/widgets/save_button_widget.dart';

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
    // ponytail: use cunning_document_scanner for automatic edge detection and cropping
    try {
      final images = await CunningDocumentScanner.getPictures();
      if (images == null || images.isEmpty) return;

      final sourceFile = File(images.first);
      if (!sourceFile.existsSync()) {
        if (context.mounted) {
          showSnackBar('Failed to save image', color: Colors.red);
        }
        return;
      }

      if (context.mounted) {
        context.read<ExtractImageBloc>().add(SetImageEvent(sourceFile));
        context.read<ExtractImageBloc>().add(const ProcessImageEvent());
      }
    } on Object catch (e) {
      if (context.mounted) {
        showSnackBar('Failed to scan card: $e', color: Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<ExtractImageBloc, ExtractImageState>(
      listener: (context, state) {
        if (state is ScanResultLoaded) {
          _pinController.text = formatPin4343(state.pin ?? '');
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
          context.read<ExtractImageBloc>().add(const ResetEvent());
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
                const ImagePreviewWidget(),
                const SizedBox(height: 20),
                CameraButtonWidget(onPress: () => _captureImage(context)),
                const SizedBox(height: 24),
                FieldsCardWidget(
                  pinController: _pinController,
                  serialController: _serialController,
                ),
                const SizedBox(height: 24),
                SaveButtonWidget(
                  pinController: _pinController,
                  serialController: _serialController,
                  categoryId: widget.categoryId,
                ),
                const SizedBox(height: 20),
                const HistoryCountWidget(),
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
}
