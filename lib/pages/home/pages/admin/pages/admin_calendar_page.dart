import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/maintenance_block_model.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/providers/boat_providers.dart';
import 'package:ocean_rent/providers/booking_providers.dart';
import 'package:table_calendar/table_calendar.dart';

class AdminCalendarPage extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const AdminCalendarPage({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<AdminCalendarPage> createState() => _AdminCalendarPageState();
}

class _AdminCalendarPageState extends ConsumerState<AdminCalendarPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _reasonController = TextEditingController();

  late final TabController _tabController;

  String? _selectedBoatId;
  String? _lastLoadedBoatId;
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1).toInt(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
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

  void _loadUnavailableDates(String boatId) {
    if (_lastLoadedBoatId == boatId) return;

    _lastLoadedBoatId = boatId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(bookingNotifierProvider).loadUnavailableDates(boatId);
    });
  }

  void _changeSelectedBoat(String? boatId) {
    if (boatId == null) return;

    setState(() {
      _selectedBoatId = boatId;
      _rangeStart = null;
      _rangeEnd = null;
      _reasonController.clear();
      _lastLoadedBoatId = null;
    });

    _loadUnavailableDates(boatId);
  }

  Future<void> _saveSelectedRange() async {
    final selectedBoatId = _selectedBoatId;
    final startDate = _rangeStart;
    final endDate = _rangeEnd ?? _rangeStart;
    final admin = ref.read(authNotifierProvider).currentUser;

    if (selectedBoatId == null || startDate == null || endDate == null) {
      _showSnackBar('Selecciona un barco y un rango de fechas.');
      return;
    }

    if (admin == null) {
      _showSnackBar('No se pudo identificar al administrador.');
      return;
    }

    final bookingNotifier = ref.read(bookingNotifierProvider);

    if (_rangeHasUnavailableDates(
      startDate,
      endDate,
      bookingNotifier.unavailableDates,
    )) {
      _showSnackBar('El rango contiene fechas ya ocupadas o bloqueadas.');
      return;
    }

    final success = await bookingNotifier.createMaintenanceBlock(
      boatId: selectedBoatId,
      createdBy: admin.uid,
      startDate: startDate,
      endDate: endDate,
      reason: _reasonController.text,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _rangeStart = null;
        _rangeEnd = null;
        _reasonController.clear();
      });

      _showSnackBar('Bloqueo de mantenimiento guardado correctamente.');
      return;
    }

    _showSnackBar(
      bookingNotifier.errorMessage ??
          'No se pudo guardar el bloqueo de mantenimiento.',
    );
  }

  Future<void> _deleteMaintenanceBlock(MaintenanceBlockModel block) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar bloqueo'),
          content: Text(
            '¿Quieres eliminar el bloqueo del ${_formatDate(block.startDate)} '
            'al ${_formatDate(block.endDate)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final bookingNotifier = ref.read(bookingNotifierProvider);

    final success = await bookingNotifier.deleteMaintenanceBlock(
      blockId: block.id,
      boatId: block.boatId,
    );

    if (!mounted) return;

    if (success) {
      _showSnackBar('Bloqueo eliminado correctamente.');
      return;
    }

    _showSnackBar(
      bookingNotifier.errorMessage ?? 'No se pudo eliminar el bloqueo.',
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildBoatDropdown({
    required List<dynamic> boats,
    required String selectedBoatId,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: selectedBoatId,
      decoration: AppTheme.inputDecoration(
        labelText: 'Barco',
        icon: Icons.directions_boat_outlined,
      ),
      dropdownColor: AppTheme.surface,
      borderRadius: AppTheme.borderRadiusInput,
      style: AppTheme.fieldTextStyle.copyWith(color: AppTheme.deepNavy),
      items: boats.map((boat) {
        return DropdownMenuItem<String>(
          value: boat.id,
          child: Text(
            boat.name,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.deepNavy),
          ),
        );
      }).toList(),
      onChanged: _changeSelectedBoat,
    );
  }

  Widget _buildAvailabilityCalendar({
    required String boatName,
    required bool isLoading,
    required Set<DateTime> unavailableDates,
  }) {
    return Container(
      padding: AppTheme.compactCardPadding,
      decoration: AppTheme.cardDecoration(
        color: AppTheme.surface,
        border: Border.all(
          color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
        ),
        boxShadow: AppTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            boatName,
            style: AppTheme.headlineMedium.copyWith(
              color: AppTheme.deepNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'Consulta las fechas ocupadas por reservas o bloqueos de mantenimiento.',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textMuted,
              height: AppTheme.lineHeightRegular,
            ),
          ),
          if (isLoading) ...[
            const SizedBox(height: AppTheme.spacing12),
            Row(
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
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppTheme.spacing16),
          TableCalendar(
            locale: 'es_ES',
            startingDayOfWeek: StartingDayOfWeek.monday,
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => false,
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                if (_isUnavailable(day, unavailableDates)) {
                  return Container(
                    margin: const EdgeInsets.all(6),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppTheme.alertRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: AppTheme.pearlWhite),
                    ),
                  );
                }

                return null;
              },
              todayBuilder: (context, day, focusedDay) {
                if (_isUnavailable(day, unavailableDates)) {
                  return Container(
                    margin: const EdgeInsets.all(6),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppTheme.alertRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: AppTheme.pearlWhite),
                    ),
                  );
                }

                return Container(
                  margin: const EdgeInsets.all(6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.oceanBlue.withValues(
                      alpha: AppTheme.alphaOverlay,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(color: AppTheme.deepNavy),
                  ),
                );
              },
            ),
            headerStyle: AppTheme.calendarHeaderStyle,
            daysOfWeekStyle: AppTheme.calendarDaysOfWeekStyle,
            calendarStyle: AppTheme.calendarStyle,
          ),
          const SizedBox(height: AppTheme.spacing12),
          Container(
            padding: AppTheme.infoBannerPadding,
            decoration: AppTheme.infoBannerDecoration(AppTheme.alertRed),
            child: Row(
              children: [
                const Icon(
                  Icons.circle,
                  color: AppTheme.alertRed,
                  size: AppTheme.iconSizeSmall,
                ),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Text(
                    'Los días en rojo no están disponibles para reserva.',
                    style: AppTheme.infoBannerTextStyle(AppTheme.alertRed),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceCalendar({
    required String boatName,
    required bool isLoading,
    required Set<DateTime> unavailableDates,
  }) {
    return Container(
      padding: AppTheme.compactCardPadding,
      decoration: AppTheme.cardDecoration(
        color: AppTheme.surface,
        border: Border.all(
          color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
        ),
        boxShadow: AppTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            boatName,
            style: AppTheme.headlineMedium.copyWith(
              color: AppTheme.deepNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'Selecciona fechas para bloquear el barco por mantenimiento o avería.',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textMuted,
              height: AppTheme.lineHeightRegular,
            ),
          ),
          if (isLoading) ...[
            const SizedBox(height: AppTheme.spacing12),
            Row(
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
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppTheme.spacing16),
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
                !_isUnavailable(day, unavailableDates),
            onRangeSelected: (start, end, focusedDay) {
              final selectedEnd = end ?? start;

              if (start != null &&
                  selectedEnd != null &&
                  _rangeHasUnavailableDates(
                    start,
                    selectedEnd,
                    unavailableDates,
                  )) {
                _showSnackBar(
                  'El rango contiene fechas ya ocupadas o bloqueadas.',
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
                if (_isUnavailable(day, unavailableDates)) {
                  return Container(
                    margin: const EdgeInsets.all(6),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppTheme.alertRed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: AppTheme.pearlWhite),
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
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              },
            ),
            headerStyle: AppTheme.calendarHeaderStyle,
            daysOfWeekStyle: AppTheme.calendarDaysOfWeekStyle,
            calendarStyle: AppTheme.calendarStyle,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boatsAsync = ref.watch(boatsStreamProvider);
    final bookingState = ref.watch(bookingNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Calendario de flota'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.pearlWhite,
          unselectedLabelColor: AppTheme.pearlWhite.withValues(
            alpha: AppTheme.alphaTextMuted,
          ),
          indicatorColor: AppTheme.oceanBlue,
          tabs: const [
            Tab(
              icon: Icon(Icons.calendar_month_outlined),
              text: 'Disponibilidad',
            ),
            Tab(icon: Icon(Icons.build_outlined), text: 'Mantenimiento'),
          ],
        ),
      ),
      body: boatsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppTheme.oceanBlue,
            strokeWidth: AppTheme.borderWidthMedium,
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: AppTheme.screenPadding,
            child: Text(
              'Error cargando barcos:\n$error',
              textAlign: TextAlign.center,
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.alertRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        data: (boats) {
          if (boats.isEmpty) {
            return Center(
              child: Padding(
                padding: AppTheme.screenPadding,
                child: Text(
                  'No hay barcos registrados para mostrar en el calendario.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.deepNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          final selectedBoatId = _selectedBoatId ?? boats.first.id;
          final selectedBoat = boats.firstWhere(
            (boat) => boat.id == selectedBoatId,
            orElse: () => boats.first,
          );

          _selectedBoatId ??= selectedBoat.id;
          _loadUnavailableDates(selectedBoat.id);

          final maintenanceBlocksAsync = ref.watch(
            maintenanceBlocksByBoatProvider(selectedBoat.id),
          );

          final availabilityTab = ListView(
            padding: AppTheme.listPadding,
            children: [
              Text(
                'Disponibilidad del barco',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              _buildBoatDropdown(boats: boats, selectedBoatId: selectedBoat.id),
              const SizedBox(height: AppTheme.spacing20),
              _buildAvailabilityCalendar(
                boatName: selectedBoat.name,
                isLoading: bookingState.isLoading,
                unavailableDates: bookingState.unavailableDates,
              ),
            ],
          );

          final maintenanceTab = ListView(
            padding: AppTheme.listPadding,
            children: [
              Text(
                'Mantenimiento de flota',
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              _buildBoatDropdown(boats: boats, selectedBoatId: selectedBoat.id),
              const SizedBox(height: AppTheme.spacing20),
              _buildMaintenanceCalendar(
                boatName: selectedBoat.name,
                isLoading: bookingState.isLoading,
                unavailableDates: bookingState.unavailableDates,
              ),
              if (_rangeStart != null) ...[
                const SizedBox(height: AppTheme.spacing18),
                Container(
                  padding: AppTheme.compactCardPadding,
                  decoration: AppTheme.infoBannerDecoration(AppTheme.deepNavy),
                  child: Text(
                    _rangeEnd == null
                        ? 'Fecha seleccionada: ${_formatDate(_rangeStart!)}'
                        : 'Rango seleccionado: del ${_formatDate(_rangeStart!)} al ${_formatDate(_rangeEnd!)}',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.deepNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacing18),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration:
                    AppTheme.inputDecoration(
                      labelText: 'Motivo del bloqueo',
                      icon: Icons.build_outlined,
                    ).copyWith(
                      hintText: 'Ejemplo: Revisión del motor anual',
                      alignLabelWithHint: true,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing18),
              ElevatedButton.icon(
                onPressed: bookingState.isLoading ? null : _saveSelectedRange,
                style: AppTheme.fullWidthPrimaryButtonStyle,
                icon: bookingState.isLoading
                    ? const SizedBox(
                        width: AppTheme.loadingSize,
                        height: AppTheme.loadingSize,
                        child: CircularProgressIndicator(
                          strokeWidth: AppTheme.progressStrokeWidth,
                          color: AppTheme.pearlWhite,
                        ),
                      )
                    : const Icon(
                        Icons.save_outlined,
                        size: AppTheme.iconSizeLarge,
                      ),
                label: Text(
                  bookingState.isLoading
                      ? 'Guardando bloqueo...'
                      : 'Guardar bloqueo',
                  style: AppTheme.buttonTextStyle.copyWith(
                    color: AppTheme.pearlWhite,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'Las fechas bloqueadas se guardarán en maintenance_blocks y se excluirán del calendario de reservas del cliente.',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                  height: AppTheme.lineHeightRegular,
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),
              _MaintenanceBlocksSection(
                blocksAsync: maintenanceBlocksAsync,
                isLoading: bookingState.isLoading,
                formatDate: _formatDate,
                onDelete: _deleteMaintenanceBlock,
              ),
            ],
          );

          return TabBarView(
            controller: _tabController,
            children: [availabilityTab, maintenanceTab],
          );
        },
      ),
    );
  }
}

class _MaintenanceBlocksSection extends StatelessWidget {
  final AsyncValue<List<MaintenanceBlockModel>> blocksAsync;
  final bool isLoading;
  final String Function(DateTime date) formatDate;
  final Future<void> Function(MaintenanceBlockModel block) onDelete;

  const _MaintenanceBlocksSection({
    required this.blocksAsync,
    required this.isLoading,
    required this.formatDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.compactCardPadding,
      decoration: AppTheme.simpleCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bloqueos de mantenimiento',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.deepNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppTheme.spacing6),
          Text(
            'Aquí puedes consultar y eliminar los bloqueos creados para este barco.',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textMuted,
              height: AppTheme.lineHeightRegular,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          blocksAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing16),
                child: CircularProgressIndicator(
                  color: AppTheme.oceanBlue,
                  strokeWidth: AppTheme.progressStrokeWidth,
                ),
              ),
            ),
            error: (error, _) => Text(
              'No se pudieron cargar los bloqueos.',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.alertRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            data: (blocks) {
              if (blocks.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: AppTheme.compactCardPadding,
                  decoration: AppTheme.infoBannerDecoration(AppTheme.oceanBlue),
                  child: Text(
                    'Este barco no tiene bloqueos de mantenimiento.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.deepNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              return Column(
                children: blocks.map((block) {
                  return _MaintenanceBlockTile(
                    block: block,
                    isLoading: isLoading,
                    formatDate: formatDate,
                    onDelete: () => onDelete(block),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MaintenanceBlockTile extends StatelessWidget {
  final MaintenanceBlockModel block;
  final bool isLoading;
  final String Function(DateTime date) formatDate;
  final VoidCallback onDelete;

  const _MaintenanceBlockTile({
    required this.block,
    required this.isLoading,
    required this.formatDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing10),
      padding: AppTheme.compactCardPadding,
      decoration: BoxDecoration(
        color: AppTheme.pearlWhite,
        borderRadius: BorderRadius.circular(AppTheme.spacing12),
        border: Border.all(
          color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.build_circle_outlined,
            color: AppTheme.oceanBlue,
            size: AppTheme.iconSizeLarge,
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${formatDate(block.startDate)} - ${formatDate(block.endDate)}',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.deepNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  block.reason.trim().isEmpty
                      ? 'Mantenimiento'
                      : block.reason.trim(),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textMuted,
                    height: AppTheme.lineHeightRegular,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Eliminar bloqueo',
            onPressed: isLoading ? null : onDelete,
            icon: const Icon(Icons.delete_outline),
            color: AppTheme.alertRed,
          ),
        ],
      ),
    );
  }
}
