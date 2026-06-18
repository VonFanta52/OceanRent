import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/models/booking_model.dart';
import 'package:ocean_rent/pages/checkout/booking_confirmation_page.dart';
import 'package:ocean_rent/providers/booking_providers.dart';
import 'package:ocean_rent/services/stripe/stripe_service.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  final BoatModel boat;
  final DateTime startDate;
  final DateTime endDate;
  final int crewCount;
  final double totalAmount;
  final double depositAmount;
  final String userId;

  const CheckoutPage({
    super.key,
    required this.boat,
    required this.startDate,
    required this.endDate,
    required this.crewCount,
    required this.totalAmount,
    required this.depositAmount,
    required this.userId,
  });

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final CardFormEditController _cardController = CardFormEditController();

  bool _isLoading = false;
  bool _isCardComplete = false;
  String? _errorMessage;

  // Se guarda en el primer intento para no duplicar reservas en caso de reintento
  BookingModel? _createdBooking;

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  int get _selectedDays {
    final start = DateTime(
      widget.startDate.year,
      widget.startDate.month,
      widget.startDate.day,
    );
    final end = DateTime(
      widget.endDate.year,
      widget.endDate.month,
      widget.endDate.day,
    );
    return end.difference(start).inDays + 1;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _confirmPayment() async {
    if (!_isCardComplete) {
      setState(() => _errorMessage = 'Completa los datos de la tarjeta.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Crear la reserva sólo en el primer intento; los reintentos reutilizan la misma
      if (_createdBooking == null) {
        final bookingNotifier = ref.read(bookingNotifierProvider);
        final success = await bookingNotifier.createBooking(
          boatId: widget.boat.id,
          userId: widget.userId,
          startDate: widget.startDate,
          endDate: widget.endDate,
          crewCount: widget.crewCount,
          depositAmount: widget.depositAmount,
        );

        if (!success) {
          setState(
            () =>
                _errorMessage =
                    bookingNotifier.errorMessage ??
                    'No se pudo crear la reserva.',
          );
          return;
        }

        _createdBooking = bookingNotifier.currentBooking;
      }

      // El paymentIntentId devuelto debe guardarse en la reserva (campo rentalPaymentIntentId)
      // cuando el backend esté disponible — ver StripeService.processPayment()
      await StripeService.instance.processPayment(
        amount: widget.totalAmount,
        currency: 'eur',
        bookingId: _createdBooking!.id,
      );

      if (!mounted) return;

      final booking = _createdBooking!;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => BookingConfirmationPage(
                booking: booking,
                boatName: widget.boat.name,
              ),
        ),
      );
    } on StripeException catch (e) {
      setState(
        () =>
            _errorMessage =
                e.error.localizedMessage ??
                'El pago fue rechazado. Comprueba los datos de la tarjeta.',
      );
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Confirmar reserva')),
      body: SafeArea(
        child: ListView(
          padding: AppTheme.listPadding,
          children: [
            _BookingSummarySection(
              boatName: widget.boat.name,
              boatImageUrl: widget.boat.imageUrl,
              startDate: _formatDate(widget.startDate),
              endDate: _formatDate(widget.endDate),
              selectedDays: _selectedDays,
              totalAmount: widget.totalAmount,
              depositAmount: widget.depositAmount,
            ),
            const SizedBox(height: AppTheme.spacing24),
            _PaymentSection(
              cardController: _cardController,
              isCardComplete: _isCardComplete,
              onCardChanged: (details) {
                setState(() => _isCardComplete = details.complete);
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppTheme.spacing16),
              _ErrorBanner(message: _errorMessage!),
            ],
            const SizedBox(height: AppTheme.spacing24),
            _ConfirmButton(
              isLoading: _isLoading,
              isEnabled: _isCardComplete && !_isLoading,
              totalAmount: widget.totalAmount,
              onPressed: _confirmPayment,
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }
}

class _BookingSummarySection extends StatelessWidget {
  final String boatName;
  final String boatImageUrl;
  final String startDate;
  final String endDate;
  final int selectedDays;
  final double totalAmount;
  final double depositAmount;

  const _BookingSummarySection({
    required this.boatName,
    required this.boatImageUrl,
    required this.startDate,
    required this.endDate,
    required this.selectedDays,
    required this.totalAmount,
    required this.depositAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (boatImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMd),
              ),
              child: Image.network(
                boatImageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ImagePlaceholder(),
              ),
            )
          else
            const ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMd),
              ),
              child: _ImagePlaceholder(),
            ),
          Padding(
            padding: AppTheme.compactCardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de la reserva',
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.deepNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                _SummaryRow(
                  icon: Icons.directions_boat_outlined,
                  label: 'Embarcación',
                  value: boatName,
                ),
                const SizedBox(height: AppTheme.spacing8),
                _SummaryRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Llegada',
                  value: startDate,
                ),
                const SizedBox(height: AppTheme.spacing8),
                _SummaryRow(
                  icon: Icons.event_outlined,
                  label: 'Salida',
                  value: endDate,
                ),
                const SizedBox(height: AppTheme.spacing8),
                _SummaryRow(
                  icon: Icons.nights_stay_outlined,
                  label: 'Días',
                  value: '$selectedDays día${selectedDays == 1 ? '' : 's'}',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacing12),
                  child: Divider(color: AppTheme.divider),
                ),
                _SummaryRow(
                  icon: Icons.euro_outlined,
                  label: 'Total alquiler',
                  value: '${totalAmount.toStringAsFixed(2)} €',
                  valueBold: true,
                ),
                const SizedBox(height: AppTheme.spacing8),
                _SummaryRow(
                  icon: Icons.security_outlined,
                  label: 'Fianza (10 %)',
                  value: '${depositAmount.toStringAsFixed(2)} €',
                ),
                const SizedBox(height: AppTheme.spacing10),
                Container(
                  width: double.infinity,
                  padding: AppTheme.infoBannerPadding,
                  decoration: AppTheme.infoBannerDecoration(AppTheme.oceanBlue),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: AppTheme.iconSizeMedium,
                        color: AppTheme.oceanBlue,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Expanded(
                        child: Text(
                          'La fianza se libera al finalizar el alquiler.',
                          style: AppTheme.infoBannerTextStyle(
                            AppTheme.oceanBlue,
                          ),
                        ),
                      ),
                    ],
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

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool valueBold;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppTheme.iconSizeMedium, color: AppTheme.oceanBlue),
        const SizedBox(width: AppTheme.spacing8),
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
            fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PaymentSection extends StatelessWidget {
  final CardFormEditController cardController;
  final bool isCardComplete;
  final void Function(CardFieldInputDetails) onCardChanged;

  const _PaymentSection({
    required this.cardController,
    required this.isCardComplete,
    required this.onCardChanged,
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
          Row(
            children: [
              const Icon(
                Icons.lock_outline,
                color: AppTheme.oceanBlue,
                size: AppTheme.iconSizeMedium,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                'Datos de pago',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'Tus datos están protegidos con cifrado SSL de Stripe.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: AppTheme.spacing16),
          CardFormField(
            controller: cardController,
            onCardChanged: (details) => onCardChanged(details ?? const CardFieldInputDetails(complete: false)),
            style: CardFormStyle(
              backgroundColor: AppTheme.background,
              textColor: AppTheme.deepNavy,
              placeholderColor: AppTheme.textMuted,
              borderColor: AppTheme.deepNavy,
              borderRadius: AppTheme.radiusSm.toInt(),
              borderWidth: 1,
              fontSize: 16,
            ),
          ),
          if (isCardComplete) ...[
            const SizedBox(height: AppTheme.spacing10),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.success,
                  size: AppTheme.iconSizeMedium,
                ),
                const SizedBox(width: AppTheme.spacing6),
                Text(
                  'Tarjeta lista para el pago',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.success),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.infoBannerPadding,
      decoration: AppTheme.infoBannerDecoration(AppTheme.alertRed),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.alertRed,
            size: AppTheme.iconSizeMedium,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              message,
              style: AppTheme.infoBannerTextStyle(AppTheme.alertRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final bool isLoading;
  final bool isEnabled;
  final double totalAmount;
  final VoidCallback onPressed;

  const _ConfirmButton({
    required this.isLoading,
    required this.isEnabled,
    required this.totalAmount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppTheme.buttonHeight,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: AppTheme.accentButtonStyle,
        child: isLoading
            ? const SizedBox(
                width: AppTheme.loadingSize,
                height: AppTheme.loadingSize,
                child: CircularProgressIndicator(
                  strokeWidth: AppTheme.progressStrokeWidth,
                  color: AppTheme.pearlWhite,
                ),
              )
            : Text(
                'Pagar ${totalAmount.toStringAsFixed(2)} €',
                style: AppTheme.buttonTextStyle.copyWith(
                  color: AppTheme.pearlWhite,
                ),
              ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
      child: const Icon(
        Icons.directions_boat_filled_outlined,
        size: 48,
        color: AppTheme.deepNavy,
      ),
    );
  }
}
