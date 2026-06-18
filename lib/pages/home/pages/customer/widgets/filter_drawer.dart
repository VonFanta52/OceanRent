import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';

class FilterDrawer extends StatelessWidget {
  final List<String> selectedCategory;
  final List<String> selectedPorts;
  final RangeValues rangedPrice;
  final RangeValues rangedCapacity;
  final List<String> categories;
  final List<String> ports;
  final bool onlyAvailable;
  final String? selectedLicense;
  final VoidCallback onReset;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onPortChanged;
  final ValueChanged<RangeValues> onPriceChanged;
  final ValueChanged<RangeValues> onCapacityChanged;
  final ValueChanged<bool> onOnlyAvailableChanged;
  final ValueChanged<String?> onLicenseChanged;

  const FilterDrawer({
    super.key,
    required this.selectedCategory,
    required this.selectedPorts,
    required this.rangedPrice,
    required this.rangedCapacity,
    required this.categories,
    required this.ports,
    required this.onlyAvailable,
    required this.onReset,
    required this.onCategoryChanged,
    required this.onPortChanged,
    required this.onPriceChanged,
    required this.onCapacityChanged,
    required this.onOnlyAvailableChanged,
    required this.onLicenseChanged,
    this.selectedLicense,
  });

  String _formatCategory(String category) {
    if (category.isEmpty) return category;
    if (category == 'todos') return 'Todos';
    if (category == 'jetski') return 'Jet ski';
    return category[0].toUpperCase() + category.substring(1);
  }

  TextStyle _sectionTitleStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppTheme.deepNavy,
          fontWeight: FontWeight.w700,
        ) ??
        AppTheme.titleSmall;
  }

  TextStyle _rangeValueStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.deepNavy,
          fontWeight: FontWeight.w600,
        ) ??
        AppTheme.bodySmall.copyWith(
          color: AppTheme.deepNavy,
          fontWeight: FontWeight.w600,
        );
  }

  Widget _sectionSpacing() {
    return const SizedBox(height: AppTheme.spacing24);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      backgroundColor: AppTheme.pearlWhite,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: AppTheme.compactCardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filtros',
                    style: textTheme.titleLarge?.copyWith(
                      color: AppTheme.deepNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Limpiar'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing8),
              const Divider(),
              const SizedBox(height: AppTheme.spacing16),
              Text('Categoria', style: _sectionTitleStyle(context)),
              const SizedBox(height: AppTheme.spacing8),
              Wrap(
                spacing: AppTheme.spacing8,
                runSpacing: AppTheme.spacing8,
                children: categories.map((category) {
                  final isSelected = selectedCategory.contains(category);

                  return FilterChip(
                    label: Text(_formatCategory(category)),
                    selected: isSelected,
                    onSelected: (_) => onCategoryChanged(category),
                    selectedColor: AppTheme.oceanBlue.withValues(
                      alpha: AppTheme.alphaOverlayLight,
                    ),
                    checkmarkColor: AppTheme.deepNavy,
                    labelStyle: AppTheme.labelMedium.copyWith(
                      color: isSelected
                          ? AppTheme.deepNavy
                          : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.deepNavy
                          : AppTheme.dividerStrong,
                    ),
                  );
                }).toList(),
              ),
              _sectionSpacing(),
              Text('Ubicacion', style: _sectionTitleStyle(context)),
              const SizedBox(height: AppTheme.spacing8),
              if (ports.isEmpty)
                Text(
                  'No hay ubicaciones disponibles',
                  style: AppTheme.bodySmall,
                )
              else
                Wrap(
                  spacing: AppTheme.spacing8,
                  runSpacing: AppTheme.spacing8,
                  children: ports.map((port) {
                    final isSelected = selectedPorts.contains(port);

                    return FilterChip(
                      avatar: Icon(
                        Icons.location_on_outlined,
                        size: AppTheme.iconSizeSmall,
                        color: isSelected
                            ? AppTheme.deepNavy
                            : AppTheme.textSecondary,
                      ),
                      label: Text(port),
                      selected: isSelected,
                      onSelected: (_) => onPortChanged(port),
                      selectedColor: AppTheme.oceanBlue.withValues(
                        alpha: AppTheme.alphaOverlayLight,
                      ),
                      checkmarkColor: AppTheme.deepNavy,
                      labelStyle: AppTheme.labelMedium.copyWith(
                        color: isSelected
                            ? AppTheme.deepNavy
                            : AppTheme.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.deepNavy
                            : AppTheme.dividerStrong,
                      ),
                    );
                  }).toList(),
                ),
              _sectionSpacing(),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Solo disponibles',
                  style: _sectionTitleStyle(context),
                ),
                subtitle: Text(
                  'Oculta barcos que no esten activos en el catalogo',
                  style: AppTheme.bodySmall,
                ),
                value: onlyAvailable,
                activeThumbColor: AppTheme.oceanBlue,
                activeTrackColor: AppTheme.oceanBlue.withValues(
                  alpha: AppTheme.alphaOverlayLight,
                ),
                onChanged: onOnlyAvailableChanged,
              ),
              _sectionSpacing(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Precio por día', style: _sectionTitleStyle(context)),
                  Text(
                    '${rangedPrice.start.toInt()} EUR - ${rangedPrice.end.toInt()} EUR',
                    style: _rangeValueStyle(context),
                  ),
                ],
              ),
              RangeSlider(
                values: rangedPrice,
                min: 0,
                max: 1000,
                divisions: 100,
                activeColor: AppTheme.deepNavy,
                inactiveColor: AppTheme.deepNavy.withValues(
                  alpha: AppTheme.alphaOverlayLight,
                ),
                labels: RangeLabels(
                  '${rangedPrice.start.toInt()} EUR',
                  '${rangedPrice.end.toInt()} EUR',
                ),
                onChanged: onPriceChanged,
              ),
              _sectionSpacing(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Capacidad', style: _sectionTitleStyle(context)),
                  Text(
                    '${rangedCapacity.start.toInt()} - ${rangedCapacity.end.toInt()} personas',
                    style: _rangeValueStyle(context),
                  ),
                ],
              ),
              RangeSlider(
                values: rangedCapacity,
                min: 1,
                max: 100,
                divisions: 25,
                activeColor: AppTheme.deepNavy,
                inactiveColor: AppTheme.deepNavy.withValues(
                  alpha: AppTheme.alphaOverlayLight,
                ),
                labels: RangeLabels(
                  '${rangedCapacity.start.toInt()}',
                  '${rangedCapacity.end.toInt()}',
                ),
                onChanged: onCapacityChanged,
              ),
              _sectionSpacing(),
              Text('Licencia requerida', style: _sectionTitleStyle(context)),
              const SizedBox(height: AppTheme.spacing8),
              DropdownButtonFormField<String?>(
                initialValue: selectedLicense,
                isExpanded: true,
                decoration: AppTheme.inputDecoration(
                  labelText: 'Tipo de licencia',
                  icon: Icons.badge_outlined,
                ),
                dropdownColor: AppTheme.white,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.deepNavy),
                selectedItemBuilder: (context) => const [
                  Text('Todas las licencias', overflow: TextOverflow.ellipsis),
                  Text('Sin licencia', overflow: TextOverflow.ellipsis),
                  Text('PNB', overflow: TextOverflow.ellipsis),
                  Text('PER', overflow: TextOverflow.ellipsis),
                ],
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text('Todas las licencias'),
                  ),
                  DropdownMenuItem(value: 'none', child: Text('Sin licencia')),
                  DropdownMenuItem(
                    value: 'pnb',
                    child: Text('PNB - Patron de Navegacion Basica'),
                  ),
                  DropdownMenuItem(
                    value: 'per',
                    child: Text('PER - Patron de Embarcaciones de Recreo'),
                  ),
                ],
                onChanged: onLicenseChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
