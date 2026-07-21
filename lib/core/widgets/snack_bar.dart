import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:qrscanner/core/router/router.dart';
import 'package:qrscanner/core/theme/app_colors.dart';
import 'package:qrscanner/core/theme/app_text_styles.dart';

void showSnackBar(
  String message, {
  bool upperSnackBar = false,
  bool popPage = false,
  int duration = 3,
  Color color = colorPrimary,
  bool isError = false,
  bool isSuccess = false,
  VoidCallback? action,
  String? actionLabel,
}) {
  final context = MagicRouter.currentContext;
  if (!context.mounted) return;

  final bg = isError
      ? colorError
      : isSuccess
      ? colorSuccess
      : color;

  final icon = isError
      ? Icons.error_outline_rounded
      : isSuccess
      ? Icons.check_circle_outline_rounded
      : Icons.info_outline_rounded;

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: upperSnackBar
          ? EdgeInsets.only(bottom: 600.h)
          : EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      padding: EdgeInsets.zero,
      content: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: LinearGradient(
            colors: [
              bg,
              Color.lerp(bg, Colors.black, 0.15) ?? bg,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20.w),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
              if (actionLabel != null && action != null) ...[
                SizedBox(width: 8.w),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    action();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                    child: Text(
                      actionLabel,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Icon(Icons.close_rounded, color: Colors.white70, size: 20.w),
                ),
              ),
            ],
          ),
        ),
      ),
      duration: Duration(seconds: duration),
    ),
  );
  if (popPage) Timer(Duration(seconds: duration), MagicRouter.pop);
}
