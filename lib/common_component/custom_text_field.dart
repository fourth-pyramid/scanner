import 'package:flutter/material.dart';
import 'package:qrscanner/constant.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    this.hint,
    this.labelText,
    this.controller,
    this.validator,
    this.onChanged,
    this.onTap,
    this.secure = false,
    this.isReadOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.fillColor = Colors.white,
    this.textColor,
    this.radius = 10,
    this.height = 16,
  });

  final String? hint;
  final String? labelText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final VoidCallback? onTap;

  final bool secure;
  final bool isReadOnly;
  final int maxLines;
  final int? maxLength;

  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final Color fillColor;
  final Color? textColor;
  final double radius;
  final double height;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.secure;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: widget.isReadOnly,
      obscureText: _obscure,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      cursorColor: colorPrimary,
      style: TextStyle(color: widget.textColor, fontSize: 20),
      validator: widget.validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: widget.fillColor,
        hintText: widget.hint,
        labelText: widget.labelText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.secure
            ? IconButton(
                iconSize: 18,
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.suffixIcon,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: widget.height,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.radius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.radius),
          borderSide: BorderSide(color: colorLightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.radius),
          borderSide: const BorderSide(color: Colors.green),
        ),
      ),
    );
  }
}
