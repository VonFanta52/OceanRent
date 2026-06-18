import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';

class BoatImagePlaceholder extends StatelessWidget {
  const BoatImagePlaceholder({
    super.key,
    required this.name,
    this.height = AppTheme.imageHeight,
    this.iconSize = AppTheme.placeholderIconSize,
  });

  final String name;
  final double height;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_boat_filled_outlined,
            size: iconSize,
            color: AppTheme.deepNavy,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.deepNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
