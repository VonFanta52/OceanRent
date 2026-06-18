import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';

class AdminQuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const AdminQuickActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppTheme.borderRadiusCard,
      onTap: onTap,
      child: Ink(
        padding: AppTheme.adminWidgetCardPadding,
        decoration: AppTheme.adminCardDecoration(),
        child: Row(
          children: [
            Container(
              width: AppTheme.quickActionIconBoxSize,
              height: AppTheme.quickActionIconBoxSize,
              decoration: AppTheme.adminIconBoxDecoration(color),
              child: Icon(icon, color: color, size: AppTheme.iconSizeLarge),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.deepNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textMuted,
                      height: AppTheme.lineHeightTight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaMuted),
              size: AppTheme.iconSizeLarge,
            ),
          ],
        ),
      ),
    );
  }
}
