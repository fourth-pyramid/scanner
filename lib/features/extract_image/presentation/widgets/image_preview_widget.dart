import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qrscanner/core/theme/app_colors.dart';
import 'package:qrscanner/core/theme/app_text_styles.dart';
import 'package:qrscanner/features/extract_image/presentation/cubit/extract_image_cubit.dart';
import 'package:qrscanner/features/extract_image/presentation/cubit/extract_image_state.dart';

class ImagePreviewWidget extends StatelessWidget {
  const ImagePreviewWidget({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<ExtractImageCubit, ExtractImageState, File?>(
        selector: (state) => context.read<ExtractImageCubit>().currentImage,
        builder: (context, previewFile) => Container(
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
        ),
      );
}
