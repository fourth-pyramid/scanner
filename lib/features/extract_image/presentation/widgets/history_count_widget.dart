import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qrscanner/core/theme/app_colors.dart';
import 'package:qrscanner/core/theme/app_text_styles.dart';
import 'package:qrscanner/features/extract_image/presentation/cubit/extract_image_cubit.dart';
import 'package:qrscanner/features/extract_image/presentation/cubit/extract_image_state.dart';

class HistoryCountWidget extends StatelessWidget {
  const HistoryCountWidget({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<ExtractImageCubit, ExtractImageState, int>(
        selector: (state) => context.read<ExtractImageCubit>().historyCount,
        builder: (context, historyCount) => Container(
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
                'Total saved cards: $historyCount',
                style: AppTextStyles.labelMedium.copyWith(
                  color: colorPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}
