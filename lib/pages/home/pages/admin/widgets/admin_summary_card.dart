import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';

class AdminSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AdminSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: AppTheme.adminWidgetCardPadding,
      decoration: AppTheme.adminCardDecoration(),
      child: Row(
        children: [
          Container(
            width: AppTheme.summaryIconBoxSize,
            height: AppTheme.summaryIconBoxSize,
            decoration: AppTheme.adminIconBoxDecoration(color),
            child: Icon(icon, color: color, size: AppTheme.iconSize2xl),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.deepNavy,
                    fontSize: AppTheme.fontSize22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.deepNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                    fontSize: AppTheme.fontSize12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return InkWell(
      borderRadius: AppTheme.borderRadiusCard,
      onTap: onTap,
      child: card,
    );
  }
}
