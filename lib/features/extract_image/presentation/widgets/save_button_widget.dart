import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qrscanner/core/theme/app_colors.dart';
import 'package:qrscanner/core/theme/app_text_styles.dart';
import 'package:qrscanner/core/widgets/custom_button.dart';
import 'package:qrscanner/features/extract_image/presentation/bloc/extract_image_bloc.dart';

class SaveButtonWidget extends StatelessWidget {
  const SaveButtonWidget({
    required this.pinController,
    required this.serialController,
    required this.categoryId,
    super.key,
  });

  final TextEditingController pinController;
  final TextEditingController serialController;
  final int categoryId;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<ExtractImageBloc, ExtractImageState, bool>(
        selector: (state) => state is SubmitLoading,
        builder: (context, isLoading) => CustomButton(
          text: isLoading ? '' : 'Save Record',
          isLoading: isLoading,
          isIcon: !isLoading,
          icon: const Icon(
            Icons.save_outlined,
            color: Colors.white,
            size: 20,
          ),
          onPress: () async {
            final bloc = context.read<ExtractImageBloc>();

            if (bloc.currentImage == null) {
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

            // Validate PIN and Serial are not empty
            if (pinController.text.trim().isEmpty ||
                serialController.text.trim().isEmpty) {
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

            // Update bloc with current text field values
            bloc
              ..add(UpdatePinEvent(pinController.text))
              ..add(UpdateSerialEvent(serialController.text));

            final phoneType = Platform.isAndroid ? 'Samsung' : 'iPhone';
            bloc.add(SubmitScanEvent(
              categoryId: categoryId,
              phoneType: phoneType,
            ));
          },
        ),
      );
}
