import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qrscanner/core/theme/app_colors.dart';
import 'package:qrscanner/core/theme/app_text_styles.dart';

// ponytail: Minimal component for quick action buttons
class ActionCard extends StatelessWidget {
  const ActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String description;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: colorSurface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: colorBorder, width: 1.2.w),
            boxShadow: [
              BoxShadow(
                color: colorPrimary.withAlpha(12),
                blurRadius: 14.r,
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: iconColor, size: 24.r),
              ),
              const Spacer(),
              Text(label, style: AppTextStyles.titleSmall),
              SizedBox(height: 2.h),
              Text(description, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      );
}
