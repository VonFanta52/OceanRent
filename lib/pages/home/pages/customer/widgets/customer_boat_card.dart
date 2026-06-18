import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/pages/home/pages/customer/pages/customer_boat_detail_page.dart';
import 'package:ocean_rent/utils/boat_utils.dart';
import 'package:ocean_rent/widgets/boat_image_placeholder.dart';

class CustomerBoatCard extends StatelessWidget {
  final BoatModel boat;

  const CustomerBoatCard({super.key, required this.boat});

  @override
  Widget build(BuildContext context) {
    void openDetail() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CustomerBoatDetailPage(boat: boat)),
      );
    }

    return Semantics(
      button: true,
      label: 'Ver detalles de ${boat.name}',
      child: InkWell(
        borderRadius: AppTheme.borderRadiusCard,
        onTap: openDetail,
        child: Container(
          margin: AppTheme.cardBottomMargin,
          decoration: AppTheme.cardDecoration(
            color: AppTheme.surface,
            radius: AppTheme.radiusCard,
            border: Border.all(
              color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
            ),
            boxShadow: AppTheme.softShadow(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: AppTheme.borderRadiusCardTop,
                    child: boat.imageUrl.isNotEmpty
                        ? Image.network(
                            boat.imageUrl,
                            height: AppTheme.customerBoatImageHeight,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => BoatImagePlaceholder(
                              name: boat.name,
                              height: AppTheme.customerBoatImageHeight,
                              iconSize: AppTheme.emptyStateIconSize,
                            ),
                          )
                        : BoatImagePlaceholder(
                            name: boat.name,
                            height: AppTheme.customerBoatImageHeight,
                            iconSize: AppTheme.emptyStateIconSize,
                          ),
                  ),
                  Positioned(
                    top: AppTheme.spacing10,
                    right: AppTheme.spacing10,
                    child: _AvailabilityBadge(isAvailable: boat.isAvailable),
                  ),
                  if (boat.ratingCount > 0)
                    Positioned(
                      left: AppTheme.spacing10,
                      bottom: AppTheme.spacing10,
                      child: _RatingBadge(
                        ratingAvg: boat.ratingAvg,
                        ratingCount: boat.ratingCount,
                      ),
                    ),
                ],
              ),
              Padding(
                padding: AppTheme.compactCardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      boat.name.isEmpty
                          ? 'BARCO SIN NOMBRE'
                          : boat.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.titleLarge.copyWith(
                        color: AppTheme.deepNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _BoatInfoItem(
                                icon: Icons.directions_boat_outlined,
                                label: formatBoatCategory(boat.category),
                              ),
                              const SizedBox(height: AppTheme.spacing6),
                              _BoatInfoItem(
                                icon: Icons.location_on_outlined,
                                label: boat.portName.trim().isEmpty
                                    ? 'Sin ubicacion'
                                    : boat.portName.trim(),
                              ),
                              const SizedBox(height: AppTheme.spacing6),
                              _BoatInfoItem(
                                icon: Icons.people_outline,
                                label: boat.capacity <= 0
                                    ? 'Sin capacidad'
                                    : boat.capacity == 1
                                    ? '1 persona'
                                    : '${boat.capacity} personas',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing10),
                        Flexible(
                          child: Transform.translate(
                            offset: const Offset(AppTheme.spacing4, 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing10,
                                vertical: AppTheme.spacing6,
                              ),
                              decoration: AppTheme.badgeDecoration(
                                color: AppTheme.sunsetGold,
                                alpha: AppTheme.alphaLight,
                              ),
                              child: Text(
                                '${boat.pricePerDay.toStringAsFixed(0)} EUR/día',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.labelMedium.copyWith(
                                  color: AppTheme.deepNavy,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (boat.requiredLicense.toLowerCase() != 'none') ...[
                      const SizedBox(height: AppTheme.spacing8),
                      _LicenseBadge(license: boat.requiredLicense),
                    ],
                    const SizedBox(height: AppTheme.spacing12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: openDetail,
                        style: AppTheme.compactTextButtonStyle,
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: AppTheme.iconSizeLarge,
                        ),
                        label: const Text('Ver detalles'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoatInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BoatInfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppTheme.iconSizeMedium, color: AppTheme.oceanBlue),
        const SizedBox(width: AppTheme.spacing6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
        ),
      ],
    );
  }
}

class _LicenseBadge extends StatelessWidget {
  final String license;

  const _LicenseBadge({required this.license});

  String _licenseLabel(String license) {
    switch (license.toLowerCase()) {
      case 'pnb':
        return 'Requiere PNB';
      case 'per':
        return 'Requiere PER';
      default:
        return 'Requiere licencia';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.sunsetGold.withValues(alpha: AppTheme.alphaLight),
        borderRadius: BorderRadius.circular(AppTheme.spacing6),
        border: Border.all(
          color: AppTheme.sunsetGold.withValues(alpha: AppTheme.alphaOverlay),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_outlined,
            size: AppTheme.iconSizeMedium,
            color: AppTheme.sunsetGold,
          ),
          const SizedBox(width: AppTheme.spacing4),
          Flexible(
            child: Text(
              _licenseLabel(license),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.sunsetGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool isAvailable;

  const _AvailabilityBadge({required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? AppTheme.oceanBlue : AppTheme.alertRed;
    final icon = isAvailable ? Icons.check_circle_outline : Icons.block_rounded;
    final label = isAvailable ? 'Disponible' : 'No disponible';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing10,
        vertical: AppTheme.spacing6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.white.withValues(alpha: AppTheme.alphaTextOnDark),
        borderRadius: AppTheme.borderRadiusPill,
        border: Border.all(
          color: color.withValues(alpha: AppTheme.alphaBorderStrong),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppTheme.iconSizeMedium, color: color),
          const SizedBox(width: AppTheme.spacing4),
          Text(
            label,
            style: AppTheme.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double ratingAvg;
  final int ratingCount;

  const _RatingBadge({required this.ratingAvg, required this.ratingCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing10,
        vertical: AppTheme.spacing6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaTextMuted),
        borderRadius: AppTheme.borderRadiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: AppTheme.iconSizeMedium,
            color: AppTheme.sunsetGold,
          ),
          const SizedBox(width: AppTheme.spacing4),
          Text(
            '${ratingAvg.toStringAsFixed(1)} ($ratingCount)',
            style: AppTheme.labelSmall.copyWith(
              color: AppTheme.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
