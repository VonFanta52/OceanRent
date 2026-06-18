import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';

Widget buildLabelTextFields(BuildContext context, String text) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: AppTheme.labelSmall.copyWith(
        color: AppTheme.black.withValues(alpha: AppTheme.alphaTextSecondary),
      ),
    ),
  );
}
