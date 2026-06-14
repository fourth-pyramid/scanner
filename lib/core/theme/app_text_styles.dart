import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:qrscanner/core/theme/app_colors.dart';

final _baseTextStyle = GoogleFonts.cairo();

class AppTextStyles {
  AppTextStyles._();

  // ─── Display ───
  static final TextStyle displayLarge = _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: colorTextPrimary,
    height: 1.3,
  );

  // ─── Titles ───
  static final TextStyle titleLarge = _baseTextStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: colorTextPrimary,
    height: 1.35,
  );

  static final TextStyle titleMedium = _baseTextStyle.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: colorTextPrimary,
    height: 1.4,
  );

  static final TextStyle titleSmall = _baseTextStyle.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: colorTextPrimary,
    height: 1.4,
  );

  // ─── Body ───
  static final TextStyle bodyLarge = _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: colorTextPrimary,
    height: 1.5,
  );

  static final TextStyle bodyMedium = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: colorTextSecondary,
    height: 1.5,
  );

  static final TextStyle bodySmall = _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: colorTextSecondary,
    height: 1.4,
  );

  // ─── Labels / UI ───
  static final TextStyle labelLarge = _baseTextStyle.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: colorSurface,
    letterSpacing: 0.3,
  );

  static final TextStyle labelMedium = _baseTextStyle.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: colorTextSecondary,
  );

  static final TextStyle labelSmall = _baseTextStyle.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: colorTextHint,
    letterSpacing: 0.2,
  );

  // ─── Button ───
  static final TextStyle button = _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: colorSurface,
    letterSpacing: 0.2,
  );

  // ─── Input ───
  static final TextStyle inputText = _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: colorTextPrimary,
  );

  static final TextStyle inputHint = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: colorTextHint,
  );
}
