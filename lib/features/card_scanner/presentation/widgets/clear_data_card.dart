import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qrscanner/core/theme/app_colors.dart';
import 'package:qrscanner/core/theme/app_text_styles.dart';
import 'package:qrscanner/core/widgets/l10n_extension.dart';
import 'package:qrscanner/features/card_scanner/presentation/bloc/card_scanner_bloc.dart';

// ponytail: UI card that triggers clear all data dialog and event
class ClearDataCard extends StatelessWidget {
  const ClearDataCard({super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              title: Text(context.l10n.clearDataConfirmTitle),
              content: Text(context.l10n.clearDataConfirmDesc),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(context.l10n.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorError,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(context.l10n.clear),
                ),
              ],
            ),
          );
          if ((confirm ?? false) && context.mounted) {
            context.read<CardScannerBloc>().add(const ClearAllDataEvent());
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: colorSurface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: colorError.withAlpha(60), width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: colorError.withAlpha(15),
                blurRadius: 10.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: colorError.withAlpha(15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.delete_sweep_outlined,
                  color: colorError,
                  size: 22.r,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.clearAllData,
                      style: AppTextStyles.titleSmall.copyWith(color: colorError),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      context.l10n.clearAllDataDesc,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colorError, size: 20.r),
            ],
          ),
        ),
      );
}
