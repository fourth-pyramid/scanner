import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:qrscanner/core/theme/app_colors.dart';
import 'package:qrscanner/core/theme/app_text_styles.dart';

class ServerTypeIndicator extends StatelessWidget {
  const ServerTypeIndicator({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final isIP = RegExp(r'^(\d{1,3}\.){3}\d{1,3}(:\d+)?$').hasMatch(text);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _ServerTypeBody(
        key: ValueKey<bool>(isIP),
        text: text,
        isIP: isIP,
      ),
    );
  }
}

class _ServerTypeBody extends StatelessWidget {
  const _ServerTypeBody({
    required this.text,
    required this.isIP,
    super.key,
  });

  final String text;
  final bool isIP;

  @override
  Widget build(BuildContext context) {
    final borderColor = isIP ? colorSuccess : colorAccent;
    final bgColor = isIP
        ? colorSuccess.withAlpha(18)
        : colorAccent.withAlpha(18);
    final icon = isIP ? Icons.router_outlined : Icons.cloud_outlined;
    final label = isIP ? 'Local Server' : 'Production Server';
    final address = isIP ? 'http://$text' : 'https://$text';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor.withAlpha(120), width: 1.2.w),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: borderColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: borderColor, size: 18.w),
              ),
              Positioned(
                right: -2.w,
                top: -2.h,
                child: _PulsingDot(color: borderColor),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: borderColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  address,
                  style: AppTextStyles.bodySmall.copyWith(color: borderColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    unawaited(_controller.repeat(reverse: true));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _controller,
    child: Container(
      width: 6.w,
      height: 6.w,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
      ),
    ),
  );
}
