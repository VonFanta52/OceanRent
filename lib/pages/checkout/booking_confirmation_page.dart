import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/booking_model.dart';
import 'package:ocean_rent/pages/home/pages/customer/customer_home_page.dart';
import 'package:ocean_rent/pages/home/pages/customer/pages/customer_bookings_page.dart';

class BookingConfirmationPage extends StatelessWidget {
  final BookingModel booking;
  final String boatName;

  const BookingConfirmationPage({
    super.key,
    required this.booking,
    required this.boatName,
  });

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: ListView(
            padding: AppTheme.screenPadding,
            children: [
              const SizedBox(height: AppTheme.spacing48),
              _SuccessIcon(),
              const SizedBox(height: AppTheme.spacing24),
              Text(
                '¡Reserva confirmada!',
                textAlign: TextAlign.center,
                style: AppTheme.headlineMedium.copyWith(
                  color: AppTheme.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Tu reserva ha sido procesada correctamente.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: AppTheme.spacing32),
              _BookingDetailsCard(
                booking: booking,
                boatName: boatName,
                formatDate: _formatDate,
              ),
              const SizedBox(height: AppTheme.spacing32),
              SizedBox(
                width: double.infinity,
                height: AppTheme.buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerHomePage(),
                      ),
                      (route) => false,
                    );
                  },
                  style: AppTheme.accentButtonStyle,
                  child: Text(
                    'Volver al inicio',
                    style: AppTheme.buttonTextStyle.copyWith(
                      color: AppTheme.pearlWhite,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              SizedBox(
                width: double.infinity,
                height: AppTheme.buttonHeight,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerBookingsPage(),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.deepNavy),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Ver mis reservas',
                    style: AppTheme.buttonTextStyle.copyWith(
                      color: AppTheme.deepNavy,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: AppTheme.alphaLight),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle_outline_rounded,
          color: AppTheme.success,
          size: 56,
        ),
      ),
    );
  }
}

class _BookingDetailsCard extends StatelessWidget {
  final BookingModel booking;
  final String boatName;
  final String Function(DateTime) formatDate;

  const _BookingDetailsCard({
    required this.booking,
    required this.boatName,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            'Detalles de la reserva',
            style: AppTheme.titleSmall.copyWith(
              color: AppTheme.deepNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          _DetailRow(label: 'Embarcación', value: boatName),
          _DetailRow(
            label: 'Entrada',
            value: formatDate(booking.startDate),
          ),
          _DetailRow(label: 'Salida', value: formatDate(booking.endDate)),
          _DetailRow(
            label: 'Tripulantes',
            value: '${booking.crewCount}',
          ),
          _DetailRow(
            label: 'Fianza retenida',
            value: '${booking.depositAmount.toStringAsFixed(2)} €',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.spacing10),
            child: Divider(color: AppTheme.divider),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Nº de reserva',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
                ),
              ),
              Flexible(
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: booking.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Número de reserva copiado.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          booking.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.oceanBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing4),
                      const Icon(
                        Icons.copy_outlined,
                        size: 14,
                        color: AppTheme.oceanBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
          Text(
            value,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.deepNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
