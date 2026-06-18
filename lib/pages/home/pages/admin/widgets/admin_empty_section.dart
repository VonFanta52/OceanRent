import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';

class AdminEmptySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const AdminEmptySection({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppTheme.sectionPadding,
      decoration: AppTheme.cardDecoration(
        color: AppTheme.surface,
        border: Border.all(
          color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
        ),
        boxShadow: [],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: AppTheme.emptyStateIconSize,
            color: AppTheme.deepNavy.withValues(
              alpha: AppTheme.alphaTextOnDark,
            ),
          ),
          const SizedBox(height: AppTheme.spacing10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.deepNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spacing6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textMuted,
              height: AppTheme.lineHeightRegular,
            ),
          ),
          if (buttonText != null && onPressed != null) ...[
            const SizedBox(height: AppTheme.spacing14),
            ElevatedButton.icon(
              onPressed: onPressed,
              style: AppTheme.accentButtonStyle,
              icon: const Icon(Icons.add, size: AppTheme.iconSizeLg),
              label: Text(
                buttonText!,
                style: AppTheme.buttonTextStyle.copyWith(color: AppTheme.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
