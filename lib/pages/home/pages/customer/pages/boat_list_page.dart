import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/models/user_model.dart';
import 'package:ocean_rent/pages/home/pages/customer/widgets/customer_boat_card.dart';
import 'package:ocean_rent/pages/home/pages/customer/widgets/filter_drawer.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/providers/user_providers.dart';

class BoatListPage extends ConsumerStatefulWidget {
  final List<String> categoriasIniciales;

  const BoatListPage({super.key, this.categoriasIniciales = const []});

  @override
  ConsumerState<BoatListPage> createState() => _BoatListPageState();
}

class _BoatListPageState extends ConsumerState<BoatListPage> {
  List<String> selectedCategories = [];
  List<String> selectedPorts = [];
  RangeValues rangedPrice = const RangeValues(0, 1000);
  RangeValues rangedCapacity = const RangeValues(1, 100);
  bool onlyAvailable = false;
  String? selectedLicense;
  UserModel? currentUser;

  final List<String> categories = [
    'todos',
    'lancha',
    'semirigida',
    'velero',
    'yate',
    'catamaran',
    'jetski',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.categoriasIniciales.isNotEmpty) {
      selectedCategories = List.from(widget.categoriasIniciales);
    }
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    final uid = ref.read(authNotifierProvider).currentUser?.uid;
    if (uid == null) return;

    final user = await ref.read(userRepositoryProvider).getUser(uid);

    if (!mounted) return;
    setState(() => currentUser = user);
  }

  List<BoatModel> filterBoats(List<BoatModel> boats) {
    return boats.where((boat) {
      if (onlyAvailable && !boat.isAvailable) {
        return false;
      }

      if (selectedCategories.isNotEmpty &&
          !selectedCategories.contains('todos') &&
          !selectedCategories.contains(boat.category)) {
        return false;
      }

      if (selectedPorts.isNotEmpty &&
          !selectedPorts.contains(boat.portName.trim())) {
        return false;
      }

      if (boat.pricePerDay < rangedPrice.start ||
          boat.pricePerDay > rangedPrice.end) {
        return false;
      }

      if (boat.capacity < rangedCapacity.start ||
          boat.capacity > rangedCapacity.end) {
        return false;
      }

      if (selectedLicense != null &&
          boat.requiredLicense.toLowerCase() != selectedLicense) {
        return false;
      }

      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      selectedCategories = [];
      selectedPorts = [];
      rangedPrice = const RangeValues(0, 1000);
      rangedCapacity = const RangeValues(1, 100);
      onlyAvailable = false;
      selectedLicense = null;
    });
  }

  List<Widget> _buildActiveFilterChips() {
    final chips = <Widget>[];

    for (final category in selectedCategories.where(
      (item) => item != 'todos',
    )) {
      chips.add(
        InputChip(
          avatar: const Icon(
            Icons.directions_boat_outlined,
            size: AppTheme.iconSizeSmall,
          ),
          label: Text(category),
          onDeleted: () => setState(() => selectedCategories.remove(category)),
        ),
      );
    }

    for (final port in selectedPorts) {
      chips.add(
        InputChip(
          avatar: const Icon(
            Icons.location_on_outlined,
            size: AppTheme.iconSizeSmall,
          ),
          label: Text(port),
          onDeleted: () => setState(() => selectedPorts.remove(port)),
        ),
      );
    }

    if (onlyAvailable) {
      chips.add(
        InputChip(
          avatar: const Icon(
            Icons.check_circle_outline,
            size: AppTheme.iconSizeSmall,
          ),
          label: const Text('Disponibles'),
          onDeleted: () => setState(() => onlyAvailable = false),
        ),
      );
    }

    if (selectedLicense != null) {
      chips.add(
        InputChip(
          avatar: const Icon(
            Icons.badge_outlined,
            size: AppTheme.iconSizeSmall,
          ),
          label: Text(selectedLicense!.toUpperCase()),
          onDeleted: () => setState(() => selectedLicense = null),
        ),
      );
    }

    if (rangedPrice.start != 0 || rangedPrice.end != 1000) {
      chips.add(
        InputChip(
          avatar: const Icon(
            Icons.payments_outlined,
            size: AppTheme.iconSizeSmall,
          ),
          label: Text(
            '${rangedPrice.start.toInt()} EUR - ${rangedPrice.end.toInt()} EUR',
          ),
          onDeleted: () => setState(() {
            rangedPrice = const RangeValues(0, 1000);
          }),
        ),
      );
    }

    if (rangedCapacity.start != 1 || rangedCapacity.end != 100) {
      chips.add(
        InputChip(
          avatar: const Icon(
            Icons.people_outline,
            size: AppTheme.iconSizeSmall,
          ),
          label: Text(
            '${rangedCapacity.start.toInt()} - ${rangedCapacity.end.toInt()} personas',
          ),
          onDeleted: () => setState(() {
            rangedCapacity = const RangeValues(1, 100);
          }),
        ),
      );
    }

    return chips;
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onReset,
  }) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPadding,
        child: Container(
          padding: AppTheme.cardPadding,
          decoration: AppTheme.cardDecoration(
            color: AppTheme.white,
            border: Border.all(
              color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
            ),
            boxShadow: AppTheme.softShadow(alpha: AppTheme.alphaUltraSoft),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppTheme.iconSize3xl, color: AppTheme.oceanBlue),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTheme.bodySmall,
              ),
              if (onReset != null) ...[
                const SizedBox(height: AppTheme.spacing20),
                OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Limpiar filtros'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFiltersCount =
        selectedCategories.length +
        selectedPorts.length +
        (rangedPrice.start != 0 || rangedPrice.end != 1000 ? 1 : 0) +
        (rangedCapacity.start != 1 || rangedCapacity.end != 100 ? 1 : 0) +
        (onlyAvailable ? 1 : 0) +
        (selectedLicense != null ? 1 : 0);

    return ValueListenableBuilder(
      valueListenable: Hive.box<BoatModel>('boats').listenable(),
      builder: (context, box, _) {
        final boats = box.values.toList();
        final filteredBoats = filterBoats(boats);
        final activeFilterChips = _buildActiveFilterChips();

        final ports =
            boats
                .map((boat) => boat.portName.trim())
                .where((port) => port.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        return Scaffold(
          drawer: FilterDrawer(
            selectedCategory: selectedCategories,
            selectedPorts: selectedPorts,
            rangedPrice: rangedPrice,
            rangedCapacity: rangedCapacity,
            categories: categories,
            ports: ports,
            onlyAvailable: onlyAvailable,
            onReset: _resetFilters,
            onCategoryChanged: (value) => setState(() {
              selectedCategories.contains(value)
                  ? selectedCategories.remove(value)
                  : selectedCategories.add(value);
            }),
            onPortChanged: (value) => setState(() {
              selectedPorts.contains(value)
                  ? selectedPorts.remove(value)
                  : selectedPorts.add(value);
            }),
            onPriceChanged: (values) => setState(() => rangedPrice = values),
            onCapacityChanged: (values) =>
                setState(() => rangedCapacity = values),
            onOnlyAvailableChanged: (value) =>
                setState(() => onlyAvailable = value),
            selectedLicense: selectedLicense,
            onLicenseChanged: (value) =>
                setState(() => selectedLicense = value),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Builder(
                          builder: (context) => OutlinedButton.icon(
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            icon: const Icon(Icons.tune),
                            label: Text(
                              activeFiltersCount == 0
                                  ? 'Filtros'
                                  : 'Filtros ($activeFiltersCount)',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.deepNavy,
                              side: const BorderSide(color: AppTheme.deepNavy),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing10),
                        Text(
                          '${filteredBoats.length} de ${boats.length} barcos',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const Spacer(),
                        if (activeFiltersCount > 0)
                          IconButton(
                            tooltip: 'Limpiar filtros',
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.restart_alt_rounded),
                          ),
                      ],
                    ),
                    if (activeFilterChips.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacing10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: activeFilterChips
                              .map(
                                (chip) => Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppTheme.spacing8,
                                  ),
                                  child: chip,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: boats.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.directions_boat_filled_outlined,
                        title: 'No hay barcos disponibles',
                        message:
                            'Todavia no se han cargado barcos en el catalogo de Ocean Rent.',
                      )
                    : filteredBoats.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.filter_alt_off_rounded,
                        title: 'No hay barcos con esos filtros',
                        message:
                            'Prueba a cambiar la categoria, el puerto, la licencia o el rango de precio.',
                        onReset: _resetFilters,
                      )
                    : ListView.builder(
                        padding: AppTheme.listPadding,
                        itemCount: filteredBoats.length,
                        itemBuilder: (context, index) {
                          return CustomerBoatCard(boat: filteredBoats[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
