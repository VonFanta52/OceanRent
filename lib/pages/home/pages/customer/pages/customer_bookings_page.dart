import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/booking_model.dart';
import 'package:ocean_rent/pages/home/pages/customer/pages/customer_review_form_page.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/providers/boat_providers.dart';
import 'package:ocean_rent/providers/booking_providers.dart';
import 'package:ocean_rent/providers/review_providers.dart';

enum BookingStatusFilter { all, pending, confirmed, cancelled }

class CustomerBookingsPage extends ConsumerStatefulWidget {
  const CustomerBookingsPage({super.key});

  @override
  ConsumerState<CustomerBookingsPage> createState() =>
      _CustomerBookingsPageState();
}

class _CustomerBookingsPageState extends ConsumerState<CustomerBookingsPage> {
  BookingStatusFilter _selectedFilter = BookingStatusFilter.all;

  static const int _cancellationMinHours = 24;

  bool _canCancelBooking(BookingModel booking) {
    if (booking.status == BookingModel.statusCancelled) return false;

    final hoursUntilStart = booking.startDate
        .difference(DateTime.now())
        .inHours;

    return hoursUntilStart >= _cancellationMinHours;
  }

  bool _canReviewBooking(BookingModel booking) {
    final bookingFinished = booking.endDate.isBefore(DateTime.now());

    return booking.status == BookingModel.statusConfirmed && bookingFinished;
  }

  Future<void> _openReviewPage({
    required BookingModel booking,
    required String userId,
  }) async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CustomerReviewFormPage(booking: booking, userId: userId),
      ),
    );

    if (!mounted || created != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reseña publicada correctamente.')),
    );
  }

  Future<void> _cancelBooking(
    BuildContext context,
    WidgetRef ref,
    BookingModel booking,
  ) async {
    final user = ref.read(authNotifierProvider).currentUser;
    if (user == null) return;

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

    final success = await ref
        .read(bookingNotifierProvider)
        .cancelBooking(booking.id, user.uid);

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
      case BookingStatusFilter.pending:
        return bookings
            .where((booking) => booking.status == BookingModel.statusPending)
            .toList();
      case BookingStatusFilter.confirmed:
        return bookings
            .where((booking) => booking.status == BookingModel.statusConfirmed)
            .toList();
      case BookingStatusFilter.cancelled:
        return bookings
            .where((booking) => booking.status == BookingModel.statusCancelled)
            .toList();
      case BookingStatusFilter.all:
        return bookings;
    }
  }

  String _emptyMessageByFilter() {
    switch (_selectedFilter) {
      case BookingStatusFilter.pending:
        return 'No tienes reservas pendientes.';
      case BookingStatusFilter.confirmed:
        return 'No tienes reservas confirmadas.';
      case BookingStatusFilter.cancelled:
        return 'No tienes reservas canceladas.';
      case BookingStatusFilter.all:
        return 'Todavía no tienes reservas.';
    }
  }

  Widget _buildBookingList({
    required List<BookingModel> filteredBookings,
    required Map<String, String> boatNames,
    required String userId,
  }) {
    return SliverPadding(
      padding: AppTheme.listPadding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index.isOdd) {
            return const SizedBox(height: AppTheme.spacing12);
          }

          final bookingIndex = index ~/ 2;
          final booking = filteredBookings[bookingIndex];
          final boatName = boatNames[booking.boatId] ?? booking.boatId;
          final canCancel = _canCancelBooking(booking);
          final canReview = _canReviewBooking(booking);
          final isUpcoming = booking.startDate.isAfter(DateTime.now());
          final reviewAsync = ref.watch(reviewByBookingProvider(booking.id));
          final hasReview = reviewAsync.maybeWhen(
            data: (review) => review != null,
            orElse: () => false,
          );

          return _CustomerBookingCard(
            booking: booking,
            boatName: boatName,
            onCancel: canCancel
                ? () => _cancelBooking(context, ref, booking)
                : null,
            onReview: canReview && !hasReview
                ? () => _openReviewPage(booking: booking, userId: userId)
                : null,
            hasReview: hasReview,
            showCancellationNotice:
                booking.status != BookingModel.statusCancelled &&
                !canCancel &&
                isUpcoming,
          );
        }, childCount: filteredBookings.length * 2 - 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).currentUser;

    if (user == null) {
      return Center(
        child: Padding(
          padding: AppTheme.screenPadding,
          child: Text(
            'Inicia sesión para ver tus reservas.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.deepNavy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final bookingsAsync = ref.watch(userBookingsStreamProvider(user.uid));
    final boatsAsync = ref.watch(boatsStreamProvider);

    final boatNames = boatsAsync.maybeWhen(
      data: (boats) => {for (final boat in boats) boat.id: boat.name},
      orElse: () => <String, String>{},
    );

    return bookingsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.oceanBlue),
      ),
      error: (error, _) => const _CustomerBookingsErrorState(),
      data: (bookings) {
        final filteredBookings = _filterBookings(bookings);

        final pendingCount = bookings
            .where((booking) => booking.status == BookingModel.statusPending)
            .length;

        final confirmedCount = bookings
            .where((booking) => booking.status == BookingModel.statusConfirmed)
            .length;

        final cancelledCount = bookings
            .where((booking) => booking.status == BookingModel.statusCancelled)
            .length;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _BookingsFilterHeader(
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
            ),
            if (filteredBookings.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyCustomerBookingsState(
                  message: _emptyMessageByFilter(),
                ),
              )
            else
              _buildBookingList(
                filteredBookings: filteredBookings,
                boatNames: boatNames,
                userId: user.uid,
              ),
          ],
        );
      },
    );
  }
}

class _CustomerBookingsErrorState extends StatelessWidget {
  const _CustomerBookingsErrorState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Container(
          padding: AppTheme.cardPadding,
          decoration: AppTheme.simpleCardDecoration(),
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
                'No se pudieron cargar tus reservas',
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

class _EmptyCustomerBookingsState extends StatelessWidget {
  final String message;

  const _EmptyCustomerBookingsState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Container(
          padding: AppTheme.cardPadding,
          decoration: AppTheme.simpleCardDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.event_available_outlined,
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
                'Cuando reserves un barco podrás consultar aquí el estado.',
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

class _BookingsFilterHeader extends StatelessWidget {
  final BookingStatusFilter selectedFilter;
  final int totalCount;
  final int pendingCount;
  final int confirmedCount;
  final int cancelledCount;
  final ValueChanged<BookingStatusFilter> onFilterSelected;

  const _BookingsFilterHeader({
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
            'Mis reservas',
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
                _BookingFilterChip(
                  label: 'Todas',
                  count: totalCount,
                  selected: selectedFilter == BookingStatusFilter.all,
                  color: AppTheme.deepNavy,
                  onTap: () => onFilterSelected(BookingStatusFilter.all),
                ),
                const SizedBox(width: AppTheme.spacing8),
                _BookingFilterChip(
                  label: 'Pendientes',
                  count: pendingCount,
                  selected: selectedFilter == BookingStatusFilter.pending,
                  color: AppTheme.sunsetGold,
                  onTap: () => onFilterSelected(BookingStatusFilter.pending),
                ),
                const SizedBox(width: AppTheme.spacing8),
                _BookingFilterChip(
                  label: 'Confirmadas',
                  count: confirmedCount,
                  selected: selectedFilter == BookingStatusFilter.confirmed,
                  color: AppTheme.oceanBlue,
                  onTap: () => onFilterSelected(BookingStatusFilter.confirmed),
                ),
                const SizedBox(width: AppTheme.spacing8),
                _BookingFilterChip(
                  label: 'Canceladas',
                  count: cancelledCount,
                  selected: selectedFilter == BookingStatusFilter.cancelled,
                  color: AppTheme.alertRed,
                  onTap: () => onFilterSelected(BookingStatusFilter.cancelled),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _BookingFilterChip({
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

class _CustomerBookingCard extends StatelessWidget {
  final BookingModel booking;
  final String boatName;
  final VoidCallback? onCancel;
  final VoidCallback? onReview;
  final bool showCancellationNotice;
  final bool hasReview;

  const _CustomerBookingCard({
    required this.booking,
    required this.boatName,
    required this.onCancel,
    required this.onReview,
    required this.showCancellationNotice,
    required this.hasReview,
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
                Icons.directions_boat_outlined,
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
            label: 'Estado fianza',
            value: _formatDepositStatus(booking.depositStatus),
          ),
          if (onCancel != null) ...[
            const SizedBox(height: AppTheme.spacing14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCancel,
                style: AppTheme.destructiveButtonStyle,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar reserva'),
              ),
            ),
          ],
          if (onReview != null) ...[
            const SizedBox(height: AppTheme.spacing14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onReview,
                style: AppTheme.fullWidthPrimaryButtonStyle,
                icon: const Icon(Icons.star_rounded),
                label: const Text('Valorar experiencia'),
              ),
            ),
          ],
          if (hasReview) ...[
            const SizedBox(height: AppTheme.spacing12),
            Container(
              padding: AppTheme.infoBannerPadding,
              decoration: AppTheme.infoBannerDecoration(AppTheme.oceanBlue),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: AppTheme.iconSizeMedium,
                    color: AppTheme.oceanBlue,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      'Reseña enviada para esta reserva.',
                      style: AppTheme.infoBannerTextStyle(AppTheme.oceanBlue),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (showCancellationNotice) ...[
            const SizedBox(height: AppTheme.spacing12),
            Container(
              padding: AppTheme.infoBannerPadding,
              decoration: AppTheme.infoBannerDecoration(AppTheme.sunsetGold),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: AppTheme.iconSizeMedium,
                    color: AppTheme.sunsetGold,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      'Esta reserva ya no se puede cancelar (menos de 24h para el inicio).',
                      style: AppTheme.infoBannerTextStyle(AppTheme.sunsetGold),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
