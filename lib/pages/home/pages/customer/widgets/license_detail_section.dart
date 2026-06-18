import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';

class LicenseDetailSection extends StatelessWidget {
  final String license;

  const LicenseDetailSection({super.key, required this.license});

  String _licenseFullLabel(String license) {
    switch (license.toLowerCase()) {
      case 'pnb':
        return 'Patrón Navegación de Barcos (PNB)';
      case 'per':
        return 'Patrón de Embarcaciones de Recreo (PER)';
      default:
        return license.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.sunsetGold.withValues(alpha: AppTheme.alphaUltraSoft),
        borderRadius: AppTheme.borderRadiusInput,
        border: Border.all(
          color: AppTheme.sunsetGold.withValues(alpha: AppTheme.alphaBorder),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_outlined,
            size: AppTheme.iconSizeLarge,
            color: AppTheme.sunsetGold,
          ),
          const SizedBox(width: AppTheme.spacing10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Licencia requerida',
                  style: AppTheme.titleSmall.copyWith(
                    color: AppTheme.sunsetGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing2),
                Text(
                  _licenseFullLabel(license),
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.sunsetGold.withValues(
                      alpha: AppTheme.alphaTextOnDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
