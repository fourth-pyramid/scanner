import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qrscanner/core/theme/app_colors.dart';
import 'package:qrscanner/core/theme/app_text_styles.dart';
import 'package:qrscanner/core/widgets/custom_text_field.dart';
import 'package:qrscanner/features/extract_image/presentation/cubit/extract_image_cubit.dart';

class FieldsCardWidget extends StatelessWidget {
  const FieldsCardWidget({
    required this.pinController,
    required this.serialController,
    super.key,
  });

  final TextEditingController pinController;
  final TextEditingController serialController;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: colorSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colorBorder, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: colorPrimary.withAlpha(10),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PIN
        Text(
          'Card PIN',
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: colorTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: pinController,
          hint: 'PIN number',
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.pin_outlined, size: 20),
          inputFormatters: [PinInputFormatter()],
          onChanged: (value) {
            context.read<ExtractImageCubit>().updatePin(value);
          },
        ),

        const SizedBox(height: 20),

        // SERIAL
        Text(
          'Serial Number',
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: colorTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: serialController,
          hint: 'Serial number',
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.tag_outlined, size: 20),
          onChanged: (value) {
            context.read<ExtractImageCubit>().updateSerial(value);
          },
        ),
      ],
    ),
  );
}

// ponytail: helper to format text in 4-3-4-3 layout
String formatPin4343(String pin) {
  final digits = pin.replaceAll(RegExp(r'\D'), '');
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);
    final nonZeroIndex = i + 1;
    if ((nonZeroIndex == 4 || nonZeroIndex == 7 || nonZeroIndex == 11) &&
        nonZeroIndex < digits.length) {
      buffer.write(' ');
    }
  }
  return buffer.toString();
}

// ponytail: TextInputFormatter to enforce 4-3-4-3 digit pattern (max 14 digits)
class PinInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final digits = text.replaceAll(RegExp(r'\D'), '');
    final truncatedDigits = digits.substring(0, digits.length > 14 ? 14 : digits.length);
    final formatted = formatPin4343(truncatedDigits);

    var selectionIndex = newValue.selection.end;
    if (selectionIndex >= text.length) {
      selectionIndex = formatted.length;
    } else {
      final prefixText = text.substring(0, selectionIndex);
      final digitsBeforeCursor = prefixText.replaceAll(RegExp(r'\D'), '').length;
      
      var formattedDigitsCount = 0;
      var newSelectionIndex = 0;
      for (var i = 0; i < formatted.length; i++) {
        if (formattedDigitsCount == digitsBeforeCursor) break;
        if (formatted[i] != ' ') formattedDigitsCount++;
        newSelectionIndex++;
      }
      selectionIndex = newSelectionIndex;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
