import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qrscanner/common_component/custom_button.dart';
import 'package:qrscanner/common_component/custom_text_field.dart';
import 'package:qrscanner/constant.dart';
import 'package:qrscanner/features/extract_image/extact_image_states.dart';
import 'package:qrscanner/features/extract_image/extract_image_controller.dart';

class ExtractImageView extends StatefulWidget {
  final String? scanType;
  final int categoryId;

  const ExtractImageView({super.key, this.scanType, required this.categoryId});

  @override
  State<ExtractImageView> createState() => _ExtractImageViewState();
}

class _ExtractImageViewState extends State<ExtractImageView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExtractImageController>().loadHistoryCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Optimization: Outer BlocBuilder only rebuilds on specific states
    return BlocBuilder<ExtractImageController, ExtractImageStates>(
      buildWhen: (previous, current) => current is! ExtractInitial,
      builder: (context, state) {
        return Scaffold(
          // Optimization: Static AppBar doesn't need to rebuild
          appBar: _buildAppBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    // -------------------------------------------------------
                    // PREVIEW IMAGE
                    // -------------------------------------------------------
                    // Optimization: Only rebuild on ImagePickedSuccess
                    BlocBuilder<ExtractImageController, ExtractImageStates>(
                      buildWhen: (previous, current) =>
                          current is ImagePickedSuccess ||
                          current is ExtractInitial,
                      builder: (context, state) {
                        final controller = ExtractImageController.of(context);
                        final previewFile = controller.image;

                        return Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.28,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blueAccent),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: previewFile != null
                              // Optimization: RepaintBoundary prevents image redraws
                              ? RepaintBoundary(
                                  child: Image.file(
                                    previewFile,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : const SizedBox(
                                  height: 50,
                                  width: 40,
                                  child: Padding(
                                    padding: EdgeInsets.all(50),
                                    child: Image(
                                      image: AssetImage(
                                        'assets/images/screenshot.png',
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                        );
                      },
                    ),

                    const SizedBox(height: 16.0),

                    // -------------------------------------------------------
                    // CAMERA BUTTON
                    // -------------------------------------------------------
                    // Show loading during OCR scanning
                    BlocBuilder<ExtractImageController, ExtractImageStates>(
                      buildWhen: (previous, current) =>
                          current is Scanning || previous is Scanning,
                      builder: (context, state) {
                        final isScanning = state is Scanning;
                        return SizedBox(
                          height: 70,
                          child: CustomButton(
                            isIcon: !isScanning,
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            text: isScanning ? 'Processing...' : 'Open Camera',
                            isLoading: isScanning,
                            onPress: () {
                              ExtractImageController.of(
                                context,
                              ).getImage(context);
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16.0),

                    // -------------------------------------------------------
                    // PIN
                    // -------------------------------------------------------
                    BlocBuilder<ExtractImageController, ExtractImageStates>(
                      buildWhen: (previous, current) =>
                          current is ScanPinSuccess,
                      builder: (context, state) {
                        final controller = ExtractImageController.of(context);
                        return CustomTextField(
                          controller: controller.pin,
                          labelText: 'Pin',
                        );
                      },
                    ),

                    const SizedBox(height: 16.0),

                    // -------------------------------------------------------
                    // SERIAL (editable)
                    // -------------------------------------------------------
                    BlocBuilder<ExtractImageController, ExtractImageStates>(
                      buildWhen: (previous, current) =>
                          current is ScanPinSuccess,
                      builder: (context, state) {
                        final controller = ExtractImageController.of(context);
                        return CustomTextField(
                          controller: controller.serial,
                          labelText: 'Serial',
                        );
                      },
                    ),

                    const SizedBox(height: 18.0),

                    // -------------------------------------------------------
                    // SAVE BUTTON
                    // -------------------------------------------------------
                    // Show loading inside button during save
                    BlocBuilder<ExtractImageController, ExtractImageStates>(
                      buildWhen: (previous, current) =>
                          current is ScanLoading || previous is ScanLoading,
                      builder: (context, state) {
                        final isLoading = state is ScanLoading;
                        return CustomButton(
                          text: 'Save',
                          isLoading: isLoading,
                          onPress: () async {
                            final controller = context
                                .read<ExtractImageController>();
                            final messenger = ScaffoldMessenger.of(context);

                            if (controller.image == null) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please capture a card image first.',
                                  ),
                                ),
                              );
                              return;
                            }

                            final phoneType = Platform.isAndroid
                                ? 'Samsung'
                                : 'iPhone';

                            /// 🔥 Scan API call
                            await controller.scan(
                              categoryId: widget.categoryId,
                              phoneType: phoneType,
                            );
                            if (context.mounted) {
                              context
                                  .read<ExtractImageController>()
                                  .loadHistoryCount();
                            }
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 16.0),
                    // Optimization: Extract history count to separate widget
                    const _HistoryCountWidget(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Optimization: Static AppBar widget
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Scan Card'),
      foregroundColor: Colors.white,
      centerTitle: true,
      backgroundColor: colorPrimary,
    );
  }
}

// Optimization: Separate widget for history count to minimize rebuilds
class _HistoryCountWidget extends StatelessWidget {
  const _HistoryCountWidget();

  @override
  Widget build(BuildContext context) {
    // Only rebuild when scan completes or history loads
    return BlocBuilder<ExtractImageController, ExtractImageStates>(
      buildWhen: (previous, current) =>
          current is ScanSuccess ||
          current is ScanPinSuccess ||
          current is ExtractInitial,
      builder: (context, state) {
        final controller = ExtractImageController.of(context);
        return Center(
          child: Text(
            'Number of Card is ${controller.historyCount}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      },
    );
  }
}
