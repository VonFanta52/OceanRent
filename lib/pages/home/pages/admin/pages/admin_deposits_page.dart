import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/booking_model.dart';
import 'package:ocean_rent/providers/boat_providers.dart';
import 'package:ocean_rent/providers/booking_providers.dart';
import 'package:ocean_rent/providers/user_providers.dart';

class AdminDepositsPage extends ConsumerWidget {
  const AdminDepositsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsStreamProvider);
    final boatsAsync = ref.watch(boatsStreamProvider);

    final boatNames = boatsAsync.maybeWhen(
      data: (boats) => {for (final boat in boats) boat.id: boat.name},
      orElse: () => <String, String>{},
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Fianzas retenidas')),
      body: bookingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.oceanBlue),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: AppTheme.screenPadding,
            child: Text(
              'No se pudieron cargar las fianzas retenidas.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.alertRed),
            ),
          ),
        ),
        data: (bookings) {
          final heldBookings = bookings
              .where(
                (booking) =>
                    booking.depositStatus == BookingModel.depositStatusHeld &&
                    booking.status != BookingModel.statusCancelled,
              )
              .toList();

          final totalHeld = heldBookings.fold<double>(
            0,
            (total, booking) => total + booking.depositAmount,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacing16,
                  AppTheme.spacing18,
                  AppTheme.spacing16,
                  AppTheme.spacing12,
                ),
                child: _DepositsHeader(
                  count: heldBookings.length,
                  totalAmount: totalHeld,
                ),
              ),
              Expanded(
                child: heldBookings.isEmpty
                    ? const _EmptyDepositsState()
                    : ListView.separated(
                        padding: AppTheme.listPadding,
                        itemCount: heldBookings.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppTheme.spacing12),
                        itemBuilder: (context, index) {
                          final booking = heldBookings[index];
                          return _DepositBookingCard(
                            booking: booking,
                            boatName:
                                boatNames[booking.boatId] ?? booking.boatId,
                            onRelease: () =>
                                _releaseDeposit(context, ref, booking),
                            onCapture: () =>
                                _captureDeposit(context, ref, booking),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _releaseDeposit(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusCard,
        ),
        title: Text('Devolver fianza', style: AppTheme.titleMedium),
        content: Text(
          'Marcar esta fianza como devuelta?',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: AppTheme.accentButtonStyle,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final success = await ref
        .read(bookingNotifierProvider)
        .releaseDeposit(booking.id);

    if (!context.mounted) return;

    final message = success
        ? 'Fianza marcada como devuelta.'
        : ref.read(bookingNotifierProvider).errorMessage ??
              'No se pudo actualizar la fianza.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppTheme.oceanBlue : AppTheme.alertRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _captureDeposit(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusCard,
        ),
        title: Text('Cobrar fianza', style: AppTheme.titleMedium),
        content: Text(
          '¿Marcar esta fianza como cobrada? Esta acción solo actualiza el estado en Ocean Rent.',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: AppTheme.destructiveButtonStyle,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cobrar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final success = await ref
        .read(bookingNotifierProvider)
        .captureDeposit(booking.id);

    if (!context.mounted) return;

    final message = success
        ? 'Fianza marcada como cobrada.'
        : ref.read(bookingNotifierProvider).errorMessage ??
              'No se pudo actualizar la fianza.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppTheme.oceanBlue : AppTheme.alertRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _DepositsHeader extends StatelessWidget {
  final int count;
  final double totalAmount;

  const _DepositsHeader({required this.count, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.compactCardPadding,
      decoration: AppTheme.adminCardDecoration(),
      child: Row(
        children: [
          Container(
            width: AppTheme.summaryIconBoxSize,
            height: AppTheme.summaryIconBoxSize,
            decoration: AppTheme.adminIconBoxDecoration(AppTheme.sunsetGold),
            child: const Icon(
              Icons.payments_outlined,
              color: AppTheme.sunsetGold,
              size: AppTheme.iconSize2xl,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${totalAmount.toStringAsFixed(2)} EUR',
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.deepNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  '$count fianza${count == 1 ? '' : 's'} retenida${count == 1 ? '' : 's'}',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DepositBookingCard extends ConsumerWidget {
  final BookingModel booking;
  final String boatName;
  final VoidCallback onRelease;
  final VoidCallback onCapture;

  const _DepositBookingCard({
    required this.booking,
    required this.boatName,
    required this.onRelease,
    required this.onCapture,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(booking.userId));
    final customerName = userAsync.maybeWhen(
      data: (user) {
        final fullName = '${user?.name ?? ''} ${user?.surname ?? ''}'.trim();
        return fullName.isEmpty ? 'Cliente' : fullName;
      },
      loading: () => 'Cargando cliente...',
      orElse: () => 'Cliente',
    );
    final customerEmail = userAsync.maybeWhen(
      data: (user) => user?.email ?? '',
      orElse: () => '',
    );

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
                color: AppTheme.sunsetGold,
                size: AppTheme.iconSizeLarge,
              ),
              const SizedBox(width: AppTheme.spacing10),
              Expanded(
                child: Text(
                  boatName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.deepNavy,
                  ),
                ),
              ),
              Container(
                padding: AppTheme.licenseStatusBadgePadding,
                decoration: AppTheme.badgeDecoration(
                  color: AppTheme.sunsetGold,
                ),
                child: Text(
                  _formatDepositStatus(booking.depositStatus),
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.sunsetGold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing14),
          _DepositInfoRow(label: 'Cliente', value: customerName),
          if (customerEmail.isNotEmpty)
            _DepositInfoRow(label: 'Email', value: customerEmail),
          _DepositInfoRow(label: 'Reserva', value: booking.id),
          _DepositInfoRow(
            label: 'Inicio',
            value: _formatDate(booking.startDate),
          ),
          _DepositInfoRow(label: 'Fin', value: _formatDate(booking.endDate)),
          _DepositInfoRow(
            label: 'Importe retenido',
            value: '${booking.depositAmount.toStringAsFixed(2)} EUR',
          ),
          _DepositInfoRow(
            label: 'Estado reserva',
            value: _formatBookingStatus(booking.status),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRelease,
                  style: AppTheme.accentButtonStyle,
                  icon: const Icon(Icons.lock_open_outlined),
                  label: const Text('Devolver'),
                ),
              ),
              const SizedBox(width: AppTheme.spacing10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCapture,
                  style: AppTheme.destructiveButtonStyle,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Cobrar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DepositInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DepositInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing6),
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

class _EmptyDepositsState extends StatelessWidget {
  const _EmptyDepositsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Container(
          padding: AppTheme.cardPadding,
          decoration: AppTheme.adminCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_open_outlined,
                color: AppTheme.oceanBlue,
                size: AppTheme.emptyStateIconSize,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'No hay fianzas retenidas',
                style: AppTheme.titleMedium.copyWith(color: AppTheme.deepNavy),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Las reservas con deposit_status held aparecerán aquí.',
                textAlign: TextAlign.center,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
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

String _formatBookingStatus(String status) {
  return switch (status) {
    BookingModel.statusConfirmed => 'confirmada',
    BookingModel.statusCancelled => 'cancelada',
    BookingModel.statusPending => 'pendiente',
    _ => status,
  };
}

String _formatDepositStatus(String status) {
  return switch (status) {
    BookingModel.depositStatusHeld => 'retenida',
    BookingModel.depositStatusReleased => 'devuelta',
    BookingModel.depositStatusCaptured => 'cobrada',
    _ => status,
  };
}
