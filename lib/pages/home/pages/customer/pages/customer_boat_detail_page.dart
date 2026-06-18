import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/pages/checkout/checkout_page.dart';
import 'package:ocean_rent/pages/home/pages/customer/pages/customer_boat_reviews_page.dart';
import 'package:ocean_rent/pages/home/pages/customer/widgets/licence_comparer.dart';
import 'package:ocean_rent/pages/home/pages/customer/widgets/license_detail_section.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/providers/booking_providers.dart';
import 'package:ocean_rent/providers/review_providers.dart';
import 'package:ocean_rent/utils/boat_utils.dart';
import 'package:ocean_rent/widgets/app_navigator.dart';
import 'package:table_calendar/table_calendar.dart';

// Pantalla de detalle para el cliente.
// Recibe el barco seleccionado desde el listado y muestra su información completa.
class CustomerBoatDetailPage extends ConsumerStatefulWidget {
  final BoatModel boat;

  const CustomerBoatDetailPage({super.key, required this.boat});

  @override
  ConsumerState<CustomerBoatDetailPage> createState() =>
      _CustomerBoatDetailPageState();
}

class _CustomerBoatDetailPageState
    extends ConsumerState<CustomerBoatDetailPage> {
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  DateTime _focusedDay = DateTime.now();
  int _crewCount = 1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingNotifierProvider).loadUnavailableDates(widget.boat.id);
    });
  }

  Future<void> _handleBooking() async {
    final user = ref.read(authNotifierProvider).currentUser;
    if (!widget.boat.isAvailable) {
      _showSnackBar('Este barco no está disponible actualmente.');
      return;
    }

    if (user == null) {
      AppNavigator.goToLogin(context);
      return;
    }

    final startDate = _rangeStart;
    final endDate = _rangeEnd ?? _rangeStart;

    if (startDate == null || endDate == null) {
      _showSnackBar('Selecciona una fecha para reservar.');
      return;
    }

    final bookingNotifier = ref.read(bookingNotifierProvider);

    if (_rangeHasUnavailableDates(
      startDate,
      endDate,
      bookingNotifier.unavailableDates,
    )) {
      _showSnackBar('El rango contiene fechas no disponibles.');
      return;
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          boat: widget.boat,
          startDate: startDate,
          endDate: endDate,
          crewCount: _crewCount,
          totalAmount: _totalRentalAmount(),
          depositAmount: _depositAmount(),
          userId: user.uid,
        ),
      ),
    );
  }

  bool _isUnavailable(DateTime day, Set<DateTime> unavailableDates) {
    final normalizedDay = _startOfDay(day);

    return unavailableDates.any(
      (date) => isSameDay(_startOfDay(date), normalizedDay),
    );
  }

  bool _rangeHasUnavailableDates(
    DateTime start,
    DateTime end,
    Set<DateTime> unavailableDates,
  ) {
    DateTime current = _startOfDay(start);
    final normalizedEnd = _startOfDay(end);

    while (current.isBefore(normalizedEnd) ||
        isSameDay(current, normalizedEnd)) {
      if (_isUnavailable(current, unavailableDates)) {
        return true;
      }

      current = current.add(const Duration(days: 1));
    }

    return false;
  }

  int _selectedDaysCount() {
    final startDate = _rangeStart;
    final endDate = _rangeEnd ?? _rangeStart;

    if (startDate == null || endDate == null) {
      return 0;
    }

    return _startOfDay(endDate).difference(_startOfDay(startDate)).inDays + 1;
  }

  double _totalRentalAmount() {
    return _selectedDaysCount() * widget.boat.pricePerDay;
  }

  double _depositAmount() {
    return _totalRentalAmount() * 0.10;
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final boat = widget.boat;
    final bookingState = ref.watch(bookingNotifierProvider);
    final user = ref.watch(authNotifierProvider).currentUser;
    final isAnonymous = user == null;
    final maxCrew = boat.capacity <= 0 ? 1 : boat.capacity;
    final hasLicense = LicenseComparer.canDriveBoat(
      nauticalLicense: user?.nauticalLicense,
      requiredLicense: boat.requiredLicense,
    );
    final canReserve =
        !bookingState.isLoading &&
        boat.isAvailable &&
        (isAnonymous || (hasLicense && _rangeStart != null));
    final bookingButtonText = !boat.isAvailable
        ? 'Barco no disponible'
        : isAnonymous
        ? 'Inicia sesión para reservar'
        : !hasLicense
        ? 'Licencia insuficiente'
        : _rangeStart == null
        ? 'Selecciona fechas'
        : 'Ir al pago';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          boat.name.isEmpty ? 'Detalle del barco' : boat.name.toUpperCase(),
        ),
      ),
      bottomNavigationBar: _BookingBottomBar(
        isLoading: bookingState.isLoading,
        canReserve: canReserve,
        buttonText: bookingButtonText,
        pricePerDay: boat.pricePerDay,
        selectedDays: _selectedDaysCount(),
        totalAmount: _totalRentalAmount(),
        onPressed: _handleBooking,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            boat.imageUrl.isNotEmpty
                ? Image.network(
                    boat.imageUrl,
                    height: AppTheme.detailImageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _DetailImagePlaceholder(),
                  )
                : const _DetailImagePlaceholder(),

            Padding(
              padding: AppTheme.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    boat.name,
                    style: AppTheme.headlineMedium.copyWith(
                      color: AppTheme.deepNavy,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _BoatDetailInfoItem(
                    icon: Icons.directions_boat_outlined,
                    label: formatBoatCategory(boat.category),
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _BoatDetailInfoItem(
                    icon: Icons.payments_outlined,
                    label: '${boat.pricePerDay.toStringAsFixed(0)} €/día',
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _BoatDetailInfoItem(
                    icon: Icons.people_outline,
                    label: 'Capacidad: ${boat.capacity} personas',
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _BoatDetailInfoItem(
                    icon: Icons.anchor_outlined,
                    label: boat.portName.isEmpty
                        ? 'Puerto no indicado'
                        : boat.portName,
                  ),
                  if (boat.requiredLicense.toLowerCase() != 'none') ...[
                    const SizedBox(height: AppTheme.spacing16),
                    LicenseDetailSection(license: boat.requiredLicense),
                  ],

                  if (!boat.isAvailable) ...[
                    const SizedBox(height: AppTheme.spacing16),
                    const _BoatNoticeBanner(
                      icon: Icons.block_rounded,
                      title: 'Barco no disponible',
                      message:
                          'Este barco está desactivado actualmente y no permite nuevas reservas.',
                      color: AppTheme.alertRed,
                    ),
                  ] else if (!isAnonymous && !hasLicense) ...[
                    const SizedBox(height: AppTheme.spacing16),
                    const _BoatNoticeBanner(
                      icon: Icons.badge_outlined,
                      title: 'Licencia insuficiente',
                      message:
                          'Tu titulación actual no permite reservar este tipo de embarcación.',
                      color: AppTheme.sunsetGold,
                    ),
                  ] else if (isAnonymous) ...[
                    const SizedBox(height: AppTheme.spacing16),
                    const _BoatNoticeBanner(
                      icon: Icons.login_rounded,
                      title: 'Inicia sesión para reservar',
                      message:
                          'Puedes revisar la información del barco, pero necesitas iniciar sesión para completar la reserva.',
                      color: AppTheme.oceanBlue,
                    ),
                  ],

                  const SizedBox(height: AppTheme.spacing24),
                  Text(
                    'Descripción',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.deepNavy,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  Text(
                    boat.description.isEmpty
                        ? 'Sin descripción disponible.'
                        : boat.description,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textMuted,
                      height: AppTheme.lineHeightInfo,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),
                  Text(
                    'Disponibilidad',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.deepNavy,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing8),
                  if (bookingState.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacing12,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: AppTheme.loadingSize,
                            height: AppTheme.loadingSize,
                            child: CircularProgressIndicator(
                              strokeWidth: AppTheme.progressStrokeWidth,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacing10),
                          Text(
                            'Cargando disponibilidad...',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                  TableCalendar(
                    locale: 'es_ES',
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    rangeSelectionMode: RangeSelectionMode.toggledOn,
                    rangeStartDay: _rangeStart,
                    rangeEndDay: _rangeEnd,
                    enabledDayPredicate: (day) =>
                        !_isUnavailable(day, bookingState.unavailableDates),
                    onRangeSelected: (start, end, focusedDay) {
                      final selectedEnd = end ?? start;

                      if (start != null &&
                          selectedEnd != null &&
                          _rangeHasUnavailableDates(
                            start,
                            selectedEnd,
                            bookingState.unavailableDates,
                          )) {
                        _showSnackBar(
                          'El rango contiene fechas no disponibles.',
                        );
                        return;
                      }

                      setState(() {
                        _rangeStart = start;
                        _rangeEnd = end;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                    calendarBuilders: CalendarBuilders(
                      disabledBuilder: (context, day, focusedDay) {
                        if (_isUnavailable(
                          day,
                          bookingState.unavailableDates,
                        )) {
                          return Container(
                            margin: const EdgeInsets.all(6),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppTheme.alertRed,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(
                                color: AppTheme.pearlWhite,
                              ),
                            ),
                          );
                        }

                        return Container(
                          margin: const EdgeInsets.all(6),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppTheme.backgroundDim,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                    headerStyle: AppTheme.calendarHeaderStyle,
                    daysOfWeekStyle: AppTheme.calendarDaysOfWeekStyle,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppTheme.oceanBlue.withValues(
                          alpha: AppTheme.alphaOverlay,
                        ),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(color: AppTheme.deepNavy),
                      selectedDecoration: const BoxDecoration(
                        color: AppTheme.oceanBlue,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: const TextStyle(
                        color: AppTheme.pearlWhite,
                      ),
                      disabledDecoration: const BoxDecoration(
                        color: AppTheme.backgroundDim,
                        shape: BoxShape.circle,
                      ),
                      disabledTextStyle: const TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                      rangeStartDecoration: const BoxDecoration(
                        color: AppTheme.oceanBlue,
                        shape: BoxShape.circle,
                      ),
                      rangeEndDecoration: const BoxDecoration(
                        color: AppTheme.oceanBlue,
                        shape: BoxShape.circle,
                      ),
                      withinRangeDecoration: BoxDecoration(
                        color: AppTheme.sunsetGold.withValues(
                          alpha: AppTheme.alphaMedium,
                        ),
                        shape: BoxShape.circle,
                      ),
                      defaultDecoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: const TextStyle(
                        color: AppTheme.deepNavy,
                      ),
                      weekendDecoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      weekendTextStyle: const TextStyle(
                        color: AppTheme.oceanBlue,
                      ),
                      outsideDaysVisible: false,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing24),

                  _BoatReviewsPreview(boat: boat),

                  const SizedBox(height: AppTheme.spacing24),

                  _CrewSelector(
                    crewCount: _crewCount,
                    maxCrew: maxCrew,
                    onDecrease: _crewCount <= 1
                        ? null
                        : () {
                            setState(() {
                              _crewCount--;
                            });
                          },
                    onIncrease: _crewCount >= maxCrew
                        ? null
                        : () {
                            setState(() {
                              _crewCount++;
                            });
                          },
                  ),

                  if (_rangeStart != null) ...[
                    const SizedBox(height: AppTheme.spacing16),
                    _BookingSummaryCard(
                      startDate: _formatDate(_rangeStart!),
                      endDate: _formatDate(_rangeEnd ?? _rangeStart!),
                      daysCount: _selectedDaysCount(),
                      rentalAmount: _totalRentalAmount(),
                      depositAmount: _depositAmount(),
                    ),
                  ],

                  const SizedBox(height: AppTheme.spacing24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoatDetailInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BoatDetailInfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppTheme.iconSizeLarge, color: AppTheme.oceanBlue),
        const SizedBox(width: AppTheme.spacing8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textMuted),
          ),
        ),
      ],
    );
  }
}

class _CrewSelector extends StatelessWidget {
  final int crewCount;
  final int maxCrew;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _CrewSelector({
    required this.crewCount,
    required this.maxCrew,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.compactCardPadding,
      decoration: AppTheme.simpleCardDecoration(),
      child: Row(
        children: [
          const Icon(
            Icons.groups_2_outlined,
            color: AppTheme.oceanBlue,
            size: AppTheme.iconSizeLarge,
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tripulantes',
                  style: AppTheme.titleSmall.copyWith(color: AppTheme.deepNavy),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  'Máximo permitido: $maxCrew',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppTheme.deepNavy,
          ),
          Text(
            '$crewCount',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.deepNavy),
          ),
          IconButton(
            onPressed: onIncrease,
            icon: const Icon(Icons.add_circle_outline),
            color: AppTheme.oceanBlue,
          ),
        ],
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  final String startDate;
  final String endDate;
  final int daysCount;
  final double rentalAmount;
  final double depositAmount;

  const _BookingSummaryCard({
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    required this.rentalAmount,
    required this.depositAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.compactCardPadding,
      decoration: AppTheme.infoBannerDecoration(AppTheme.oceanBlue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de la reserva',
            style: AppTheme.titleSmall.copyWith(color: AppTheme.deepNavy),
          ),
          const SizedBox(height: AppTheme.spacing10),
          _SummaryRow(label: 'Inicio', value: startDate),
          _SummaryRow(label: 'Fin', value: endDate),
          _SummaryRow(label: 'Días', value: '$daysCount'),
          _SummaryRow(
            label: 'Alquiler',
            value: '${rentalAmount.toStringAsFixed(2)} €',
          ),
          _SummaryRow(
            label: 'Fianza',
            value: '${depositAmount.toStringAsFixed(2)} €',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

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

class _BoatReviewsPreview extends ConsumerWidget {
  final BoatModel boat;

  const _BoatReviewsPreview({required this.boat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsByBoatProvider(boat.id));
    final reviews = reviewsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final reviewCount = reviews?.length ?? boat.ratingCount;
    final ratingAvg = reviews == null
        ? boat.ratingAvg
        : reviews.isEmpty
        ? 0.0
        : reviews.fold<int>(0, (total, review) => total + review.rating) /
              reviews.length;
    final hasReviews = reviewCount > 0;
    final ratingText = hasReviews
        ? '${ratingAvg.toStringAsFixed(1)} - $reviewCount reseña${reviewCount == 1 ? '' : 's'}'
        : 'Sin reseñas todavía';

    return Container(
      padding: AppTheme.compactCardPadding,
      decoration: AppTheme.simpleCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resenas',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.deepNavy),
          ),
          const SizedBox(height: AppTheme.spacing10),
          Row(
            children: [
              const Icon(Icons.star, color: AppTheme.sunsetGold),
              const SizedBox(width: AppTheme.spacing6),
              Text(
                ratingText,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.deepNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            hasReviews
                ? 'Consulta las valoraciones reales de otros clientes.'
                : 'Este barco todavía no tiene valoraciones de clientes.',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerBoatReviewsPage(boat: boat),
                  ),
                );
              },
              child: Text(
                hasReviews ? 'Ver reseñas' : 'Ver sección de reseñas',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoatNoticeBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _BoatNoticeBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.compactCardPadding,
      decoration: AppTheme.infoBannerDecoration(color),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppTheme.iconSizeLarge),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.titleSmall.copyWith(color: AppTheme.deepNavy),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  message,
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

class _BookingBottomBar extends StatelessWidget {
  final bool isLoading;
  final bool canReserve;
  final String buttonText;
  final double pricePerDay;
  final int selectedDays;
  final double totalAmount;
  final VoidCallback onPressed;

  const _BookingBottomBar({
    required this.isLoading,
    required this.canReserve,
    required this.buttonText,
    required this.pricePerDay,
    required this.selectedDays,
    required this.totalAmount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelectedDays = selectedDays > 0;

    return SafeArea(
      child: Container(
        padding: AppTheme.detailBottomButtonPadding,
        decoration: BoxDecoration(
          color: AppTheme.white,
          boxShadow: AppTheme.softShadow(alpha: AppTheme.alphaSoft),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasSelectedDays
                        ? '${totalAmount.toStringAsFixed(2)} €'
                        : '${pricePerDay.toStringAsFixed(0)} €/día',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.deepNavy,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing2),
                  Text(
                    hasSelectedDays
                        ? '$selectedDays día${selectedDays == 1 ? '' : 's'} seleccionados'
                        : 'Selecciona fechas para calcular total',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            SizedBox(
              height: AppTheme.buttonHeight,
              child: ElevatedButton(
                onPressed: canReserve ? onPressed : null,
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
                        buttonText,
                        style: AppTheme.buttonTextStyle.copyWith(
                          color: AppTheme.pearlWhite,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder reutilizado cuando no existe imagen o la URL no carga correctamente.
class _DetailImagePlaceholder extends StatelessWidget {
  const _DetailImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.detailImageHeight,
      width: double.infinity,
      color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_boat_filled_outlined,
            size: AppTheme.detailPlaceholderIconSize,
            color: AppTheme.deepNavy,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Imagen no disponible',
            style: AppTheme.titleMedium.copyWith(color: AppTheme.deepNavy),
          ),
        ],
      ),
    );
  }
}
