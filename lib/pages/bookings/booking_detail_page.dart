import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/booking_model.dart';

class BookingDetailPage extends StatelessWidget {
  final BookingModel booking;
  final String boatName;
  final bool isAdmin;

  const BookingDetailPage({
    super.key,
    required this.booking,
    required this.boatName,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Detalle de reserva')),
      body: ListView(
        padding: AppTheme.listPadding,
        children: [
          Container(
            padding: AppTheme.compactCardPadding,
            decoration: AppTheme.cardDecoration(
              color: AppTheme.surface,
              border: Border.all(
                color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
              ),
              boxShadow: AppTheme.softShadow(alpha: AppTheme.alphaUltraSoft),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: AppTheme.summaryIconBoxSize,
                      height: AppTheme.summaryIconBoxSize,
                      decoration: AppTheme.adminIconBoxDecoration(
                        AppTheme.oceanBlue,
                      ),
                      child: const Icon(
                        Icons.event_available_outlined,
                        color: AppTheme.oceanBlue,
                        size: AppTheme.iconSize2xl,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            boatName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.deepNavy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          Text(
                            isAdmin
                                ? 'Vista de administración'
                                : 'Tu reserva vinculada',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(
                      label: _bookingStatusLabel(booking.status),
                      color: _bookingStatusColor(booking.status),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing18),
                _DetailRow(
                  label: 'Inicio',
                  value: _formatDate(booking.startDate),
                ),
                _DetailRow(label: 'Fin', value: _formatDate(booking.endDate)),
                _DetailRow(label: 'Tripulantes', value: '${booking.crewCount}'),
                _DetailRow(
                  label: 'Fianza',
                  value: '${booking.depositAmount.toStringAsFixed(2)} EUR',
                ),
                _DetailRow(
                  label: 'Estado fianza',
                  value: _depositStatusLabel(booking.depositStatus),
                ),
                _DetailRow(label: 'Reserva', value: booking.id),
                if (booking.isChatClosed)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spacing12),
                    child: Container(
                      padding: AppTheme.infoBannerPadding,
                      decoration: AppTheme.infoBannerDecoration(
                        AppTheme.textMuted,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            color: AppTheme.textMuted,
                            size: AppTheme.iconSizeMedium,
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Expanded(
                            child: Text(
                              'Chat finalizado',
                              style: AppTheme.infoBannerTextStyle(
                                AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.deepNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.licenseStatusBadgePadding,
      decoration: AppTheme.badgeDecoration(color: color),
      child: Text(
        label,
        style: AppTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String _bookingStatusLabel(String status) {
  return switch (status) {
    BookingModel.statusConfirmed => 'confirmada',
    BookingModel.statusCancelled => 'cancelada',
    BookingModel.statusPending => 'pendiente',
    _ => status,
  };
}

String _depositStatusLabel(String status) {
  return switch (status) {
    BookingModel.depositStatusHeld => 'retenida',
    BookingModel.depositStatusReleased => 'liberada',
    BookingModel.depositStatusCaptured => 'cobrada',
    _ => status,
  };
}

Color _bookingStatusColor(String status) {
  return switch (status) {
    BookingModel.statusConfirmed => AppTheme.oceanBlue,
    BookingModel.statusCancelled => AppTheme.alertRed,
    BookingModel.statusPending => AppTheme.sunsetGold,
    _ => AppTheme.textMuted,
  };
}
