import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:qrscanner/core/theme/app_colors.dart';
import 'package:qrscanner/core/theme/app_text_styles.dart';

enum ButtonVariant { primary, secondary, outline }

class CustomButton extends StatefulWidget {
  const CustomButton({
    super.key,
    this.text = '',
    this.fontSize = 16,
    this.onPress,
    this.widthButton,
    this.heightButton,
    this.isBold = true,
    this.isIcon = false,
    this.icon,
    this.bgColor,
    this.borderColor,
    this.fontColor,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
  });

  final String text;
  final double fontSize;
  final bool isBold;
  final VoidCallback? onPress;
  final double? widthButton;
  final double? heightButton;
  final bool isIcon;
  final Widget? icon;
  final Color? bgColor;
  final Color? borderColor;
  final Color? fontColor;
  final bool isLoading;
  final ButtonVariant variant;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.heightButton ?? 52.h;
    final w = widget.widthButton ?? double.infinity;

    final isDisabled = widget.onPress == null && !widget.isLoading;

    final bg =
        widget.bgColor ??
        (widget.variant == ButtonVariant.outline
            ? Colors.transparent
            : widget.variant == ButtonVariant.secondary
            ? colorSurfaceVariant
            : colorPrimary);
    final fg =
        widget.fontColor ??
        (widget.variant == ButtonVariant.outline
            ? colorPrimary
            : widget.variant == ButtonVariant.secondary
            ? colorTextPrimary
            : colorSurface);
    final border =
        widget.borderColor ??
        (widget.variant == ButtonVariant.outline ? colorPrimary : Colors.transparent);

    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        key: const ValueKey('loading'),
        width: 22.w,
        height: 22.h,
        child: CircularProgressIndicator(
          strokeWidth: 2.5.w,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else {
      content = Row(
        key: const ValueKey('content'),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.isIcon && widget.icon != null) ...[widget.icon!, SizedBox(width: 8.w)],
          if (widget.text.isNotEmpty)
            Text(
              widget.text,
              style: AppTextStyles.button.copyWith(
                color: fg,
                fontSize: widget.fontSize.sp,
                fontWeight: widget.isBold ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
        ],
      );
    }

    final buttonBody = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: border, width: 1.5.w),
        boxShadow: (widget.variant == ButtonVariant.primary && !widget.isLoading && !isDisabled)
            ? [
                BoxShadow(
                  color: colorPrimary.withAlpha(36),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPress,
          onHighlightChanged: (isHighlighted) {
            if (widget.onPress != null && !widget.isLoading) {
              setState(() => _isPressed = isHighlighted);
            }
          },
          borderRadius: BorderRadius.circular(14.r),
          splashColor: Colors.white.withAlpha(30),
          highlightColor: Colors.white.withAlpha(15),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: content,
            ),
          ),
        ),
      ),
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: isDisabled ? 0.6 : 1.0,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: buttonBody,
      ),
    );
  }
}
