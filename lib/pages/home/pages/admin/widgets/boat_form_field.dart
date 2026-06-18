import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';

class BoatFormField extends StatelessWidget {
  const BoatFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTheme.fieldTextStyle,
      decoration: AppTheme.inputDecoration(labelText: label, icon: icon),
      validator: validator,
    );
  }
}
