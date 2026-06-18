import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';

// Widget personalizado para construir TextFields

class CustomTextField extends StatelessWidget {
  final String? hintText;
  final int maxLines;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;

  const CustomTextField({
    super.key,
    this.hintText,
    this.maxLines = 1,
    this.controller,
    this.keyboardType,
    this.suffixIcon,
    this.inputFormatters,
    this.obscureText = false,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppTheme.borderRadiusInput,
        boxShadow: AppTheme.softShadow(alpha: AppTheme.alphaBorder),
      ),
      child: TextField(
        controller: controller,
        maxLines: obscureText ? 1 : maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        textAlign: TextAlign.left,
        style: AppTheme.fieldTextStyle,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTheme.helperTextStyle,
          filled: true,
          fillColor: AppTheme.pearlWhite,
          suffixIcon: suffixIcon,
          contentPadding: AppTheme.inputContentPadding,
          enabledBorder: AppTheme.outlineBorder(
            AppTheme.deepNavy,
            width: AppTheme.borderWidthInput,
          ),
          focusedBorder: AppTheme.outlineBorder(
            AppTheme.oceanBlue,
            width: AppTheme.borderWidthInput,
          ),
        ),
      ),
    );
  }
}
