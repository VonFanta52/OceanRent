import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/booking_model.dart';
import 'package:ocean_rent/providers/boat_providers.dart';
import 'package:ocean_rent/providers/booking_providers.dart';

enum AdminBookingStatusFilter { all, pending, confirmed, cancelled }

class AdminBookingsPage extends ConsumerStatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  ConsumerState<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends ConsumerState<AdminBookingsPage> {
  AdminBookingStatusFilter _selectedFilter = AdminBookingStatusFilter.all;

  Future<void> _confirmBooking(
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
        title: Text('Confirmar reserva', style: AppTheme.titleMedium),
        content: Text(
          '¿Quieres confirmar esta reserva?',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final success = await ref
        .read(bookingNotifierProvider)
        .confirmBooking(booking.id);

    if (!context.mounted) return;

    final message = success
        ? 'Reserva confirmada correctamente.'
        : ref.read(bookingNotifierProvider).errorMessage ??
              'No se pudo confirmar la reserva.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _cancelBooking(
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
        title: Text('Cancelar reserva', style: AppTheme.titleMedium),
        content: Text(
          '¿Seguro que quieres cancelar esta reserva?',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Cancelar reserva',
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.alertRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    // El admin usa cancelBookingAsAdmin, sin límite de antelación.
    final success = await ref
        .read(bookingNotifierProvider)
        .cancelBookingAsAdmin(booking.id);

    if (!context.mounted) return;

    final message = success
        ? 'Reserva cancelada correctamente.'
        : ref.read(bookingNotifierProvider).errorMessage ??
              'No se pudo cancelar la reserva.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<BookingModel> _filterBookings(List<BookingModel> bookings) {
    switch (_selectedFilter) {
      case AdminBookingStatusFilter.pending:
        return bookings
            .where((booking) => booking.status == BookingModel.statusPending)
            .toList();
      case AdminBookingStatusFilter.confirmed:
        return bookings
            .where((booking) => booking.status == BookingModel.statusConfirmed)
            .toList();
      case AdminBookingStatusFilter.cancelled:
        return bookings
            .where((booking) => booking.status == BookingModel.statusCancelled)
            .toList();
      case AdminBookingStatusFilter.all:
        return bookings;
    }
  }

  String _emptyMessageByFilter() {
    switch (_selectedFilter) {
      case AdminBookingStatusFilter.pending:
        return 'No hay reservas pendientes.';
      case AdminBookingStatusFilter.confirmed:
        return 'No hay reservas confirmadas.';
      case AdminBookingStatusFilter.cancelled:
        return 'No hay reservas canceladas.';
      case AdminBookingStatusFilter.all:
        return 'Todavía no hay reservas registradas.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsStreamProvider);
    final boatsAsync = ref.watch(boatsStreamProvider);

    final boatNames = boatsAsync.maybeWhen(
      data: (boats) => {for (final boat in boats) boat.id: boat.name},
      orElse: () => <String, String>{},
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Reservas')),
      body: bookingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.oceanBlue),
        ),
        error: (error, _) => const _BookingsErrorState(),
        data: (bookings) {
          final filteredBookings = _filterBookings(bookings);

          final pendingCount = bookings
              .where((booking) => booking.status == BookingModel.statusPending)
              .length;

          final confirmedCount = bookings
              .where(
                (booking) => booking.status == BookingModel.statusConfirmed,
              )
              .length;

          final cancelledCount = bookings
              .where(
                (booking) => booking.status == BookingModel.statusCancelled,
              )
              .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AdminBookingsFilterHeader(
                selectedFilter: _selectedFilter,
                totalCount: bookings.length,
                pendingCount: pendingCount,
                confirmedCount: confirmedCount,
                cancelledCount: cancelledCount,
                onFilterSelected: (filter) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
              Expanded(
                child: filteredBookings.isEmpty
                    ? _EmptyBookingsState(message: _emptyMessageByFilter())
                    : ListView.separated(
                        padding: AppTheme.listPadding,
                        itemCount: filteredBookings.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppTheme.spacing12),
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          final boatName =
                              boatNames[booking.boatId] ?? booking.boatId;

                          return _AdminBookingCard(
                            booking: booking,
                            boatName: boatName,
                            onConfirm:
                                booking.status == BookingModel.statusPending
                                ? () => _confirmBooking(context, ref, booking)
                                : null,
                            onCancel:
                                booking.status == BookingModel.statusCancelled
                                ? null
                                : () => _cancelBooking(context, ref, booking),
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
}

class _BookingsErrorState extends StatelessWidget {
  const _BookingsErrorState();

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
                Icons.cloud_off_outlined,
                color: AppTheme.alertRed,
                size: AppTheme.emptyStateIconSize,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'No se pudieron cargar las reservas',
                textAlign: TextAlign.center,
                style: AppTheme.titleMedium.copyWith(color: AppTheme.deepNavy),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Revisa tu conexion o intenta de nuevo en unos minutos.',
                textAlign: TextAlign.center,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                  height: AppTheme.lineHeightRegular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBookingsState extends StatelessWidget {
  final String message;

  const _EmptyBookingsState({required this.message});

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
                Icons.event_busy_outlined,
                color: AppTheme.oceanBlue,
                size: AppTheme.emptyStateIconSize,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTheme.titleMedium.copyWith(color: AppTheme.deepNavy),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Cuando entren nuevas solicitudes aparecerán aquí.',
                textAlign: TextAlign.center,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                  height: AppTheme.lineHeightRegular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminBookingsFilterHeader extends StatelessWidget {
  final AdminBookingStatusFilter selectedFilter;
  final int totalCount;
  final int pendingCount;
  final int confirmedCount;
  final int cancelledCount;
  final ValueChanged<AdminBookingStatusFilter> onFilterSelected;

  const _AdminBookingsFilterHeader({
    required this.selectedFilter,
    required this.totalCount,
    required this.pendingCount,
    required this.confirmedCount,
    required this.cancelledCount,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing20,
        AppTheme.spacing18,
        AppTheme.spacing20,
        AppTheme.spacing8,
      ),
      color: AppTheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestión de reservas',
            style: AppTheme.headlineSmall.copyWith(
              color: AppTheme.deepNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _AdminBookingFilterChip(
                  label: 'Todas',
                  count: totalCount,
                  selected: selectedFilter == AdminBookingStatusFilter.all,
                  color: AppTheme.deepNavy,
                  onTap: () => onFilterSelected(AdminBookingStatusFilter.all),
                ),
                const SizedBox(width: AppTheme.spacing8),
                _AdminBookingFilterChip(
                  label: 'Pendientes',
                  count: pendingCount,
                  selected: selectedFilter == AdminBookingStatusFilter.pending,
                  color: AppTheme.sunsetGold,
                  onTap: () =>
                      onFilterSelected(AdminBookingStatusFilter.pending),
                ),
                const SizedBox(width: AppTheme.spacing8),
                _AdminBookingFilterChip(
                  label: 'Confirmadas',
                  count: confirmedCount,
                  selected:
                      selectedFilter == AdminBookingStatusFilter.confirmed,
                  color: AppTheme.oceanBlue,
                  onTap: () =>
                      onFilterSelected(AdminBookingStatusFilter.confirmed),
                ),
                const SizedBox(width: AppTheme.spacing8),
                _AdminBookingFilterChip(
                  label: 'Canceladas',
                  count: cancelledCount,
                  selected:
                      selectedFilter == AdminBookingStatusFilter.cancelled,
                  color: AppTheme.alertRed,
                  onTap: () =>
                      onFilterSelected(AdminBookingStatusFilter.cancelled),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBookingFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _AdminBookingFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? color.withValues(alpha: AppTheme.alphaLight)
        : AppTheme.surface;

    final borderColor = selected
        ? color
        : AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft);

    final textColor = selected ? color : AppTheme.textMuted;

    return InkWell(
      borderRadius: AppTheme.borderRadiusPill,
      onTap: onTap,
      child: Container(
        padding: AppTheme.chipPadding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppTheme.borderRadiusPill,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.labelMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: AppTheme.spacing6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing6,
                vertical: AppTheme.spacing4,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? color
                    : AppTheme.deepNavy.withValues(
                        alpha: AppTheme.alphaUltraSoft,
                      ),
                borderRadius: AppTheme.borderRadiusPill,
              ),
              child: Text(
                '$count',
                style: AppTheme.labelSmall.copyWith(
                  color: selected ? AppTheme.white : AppTheme.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminBookingCard extends StatelessWidget {
  final BookingModel booking;
  final String boatName;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _AdminBookingCard({
    required this.booking,
    required this.boatName,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);

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
                Icons.event_available_outlined,
                color: AppTheme.oceanBlue,
                size: AppTheme.iconSizeLarge,
              ),
              const SizedBox(width: AppTheme.spacing10),
              Expanded(
                child: Text(
                  boatName,
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.deepNavy,
                  ),
                ),
              ),
              _StatusBadge(status: booking.status, color: statusColor),
            ],
          ),
          const SizedBox(height: AppTheme.spacing14),
          _InfoRow(label: 'Inicio', value: _formatDate(booking.startDate)),
          _InfoRow(label: 'Fin', value: _formatDate(booking.endDate)),
          _InfoRow(label: 'Tripulantes', value: '${booking.crewCount}'),
          _InfoRow(
            label: 'Fianza',
            value: '${booking.depositAmount.toStringAsFixed(2)} €',
          ),
          _InfoRow(
            label: 'Estado fianza',
            value: _formatDepositStatus(booking.depositStatus),
          ),
          const SizedBox(height: AppTheme.spacing14),
          Row(
            children: [
              if (onConfirm != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    style: AppTheme.accentButtonStyle,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmar'),
                  ),
                ),
              if (onConfirm != null && onCancel != null)
                const SizedBox(width: AppTheme.spacing10),
              if (onCancel != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCancel,
                    style: AppTheme.destructiveButtonStyle,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancelar'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.licenseStatusBadgePadding,
      decoration: AppTheme.badgeDecoration(color: color),
      child: Text(
        _formatBookingStatus(status),
        style: AppTheme.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

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

Color _statusColor(String status) {
  switch (status) {
    case BookingModel.statusConfirmed:
      return AppTheme.oceanBlue;
    case BookingModel.statusCancelled:
      return AppTheme.alertRed;
    case BookingModel.statusPending:
    default:
      return AppTheme.sunsetGold;
  }
}

String _formatBookingStatus(String status) {
  switch (status) {
    case BookingModel.statusConfirmed:
      return 'confirmada';
    case BookingModel.statusCancelled:
      return 'cancelada';
    case BookingModel.statusPending:
      return 'pendiente';
    default:
      return status;
  }
}

String _formatDepositStatus(String status) {
  switch (status) {
    case BookingModel.depositStatusHeld:
      return 'retenida';
    case BookingModel.depositStatusReleased:
      return 'liberada';
    case BookingModel.depositStatusCaptured:
      return 'cobrada';
    default:
      return status;
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}
