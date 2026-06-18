import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/pages/home/pages/customer/pages/customer_boat_detail_page.dart';
import 'package:ocean_rent/providers/boat_providers.dart';

// Utilidades de categoría

/// Normaliza la categoría eliminando tildes, espacios y mayúsculas
/// para comparar de forma robusta con los valores de Firestore.
String _normalizeCategory(String category) {
  return category
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll(' ', '');
}

// Devuelve el color del pin según la categoría del barco
// (especificación: sección 4.2 Categorías de Barcos y Filtros)
Color _pinColor(String category) {
  switch (_normalizeCategory(category)) {
    case 'lancha':
    case 'semirigida':
    case 'semirrigida':
      return const Color(0xFF64B5F6); // azul claro
    case 'velero':
      return Colors.white;
    case 'yate':
    case 'yateamotor':
      return AppTheme.sunsetGold; // dorado
    case 'catamaran':
      return AppTheme.oceanBlue; // verde agua / teal
    case 'jetski':
    case 'jetsky':
      return Colors.orange;
    default:
      return AppTheme.deepNavy;
  }
}

// Devuelve el color del borde/icono del pin
Color _pinBorderColor(String category) {
  switch (_normalizeCategory(category)) {
    case 'velero':
      return AppTheme.deepNavy;
    default:
      return Colors.white;
  }
}
// Página principal

class CustomerMapPage extends ConsumerStatefulWidget {
  const CustomerMapPage({super.key});

  @override
  ConsumerState<CustomerMapPage> createState() => _CustomerMapPageState();
}

class _CustomerMapPageState extends ConsumerState<CustomerMapPage> {
  final MapController _mapController = MapController();
  BoatModel? _selectedBoat;

  static const LatLng _initialCenter = LatLng(36.52, -4.88);
  static const double _initialZoom = 9.5;

  /// Precisión de decimales para agrupar coordenadas como "mismo puerto".
  /// 4 decimales ≈ ~11 m de precisión.
  static const int _groupPrecision = 4;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Agrupación de barcos por coordenadas

  /// Devuelve un mapa clave→lista donde la clave es "lat,lng" redondeada
  /// a [_groupPrecision] decimales. Cada lista contiene todos los barcos
  /// que comparten (aproximadamente) la misma ubicación.
  Map<String, List<BoatModel>> _groupBoatsByLocation(List<BoatModel> boats) {
    final Map<String, List<BoatModel>> groups = {};
    for (final boat in boats) {
      final lat = boat.location!.latitude.toStringAsFixed(_groupPrecision);
      final lng = boat.location!.longitude.toStringAsFixed(_groupPrecision);
      final key = '$lat,$lng';
      groups.putIfAbsent(key, () => []).add(boat);
    }
    return groups;
  }

  // Construcción de marcadores con offset

  // Genera la lista de [Marker] desplazando en abanico los barcos que
  // comparten la misma ubicación para que todos sus pines sean visibles.

  // El radio de dispersión (~0.0002° ≈ 20 m) es lo suficientemente pequeño
  // para parecer "en el mismo puerto" pero lo suficientemente grande para
  // que los círculos de 34 px no se solapen a zoom 9-12.
  List<Marker> _buildMarkers(List<BoatModel> boats) {
    const double spreadRadius = 0.0002;
    final groups = _groupBoatsByLocation(boats);
    final markers = <Marker>[];

    for (final group in groups.values) {
      final total = group.length;

      for (int i = 0; i < total; i++) {
        final boat = group[i];
        double offsetLat = boat.location!.latitude;
        double offsetLng = boat.location!.longitude;

        if (total > 1) {
          // Distribuye los pines uniformemente en una circunferencia
          final angle = (i * 2 * pi) / total;
          offsetLat += spreadRadius * cos(angle);
          offsetLng += spreadRadius * sin(angle);
        }

        final isSelected = _selectedBoat?.id == boat.id;

        markers.add(
          Marker(
            point: LatLng(offsetLat, offsetLng),
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => _onPinTapped(boat, group),
              child: _BoatPin(category: boat.category, isSelected: isSelected),
            ),
          ),
        );
      }
    }

    return markers;
  }

  // Handlers de interacción

  // Toque sobre un pin:
  // - Si es el único barco en esa ubicación → muestra el popup individual.
  // - Si hay varios → muestra el bottom sheet con la lista del grupo.
  void _onPinTapped(BoatModel boat, List<BoatModel> groupAtLocation) {
    if (groupAtLocation.length == 1) {
      _showSingleBoat(boat);
    } else {
      _showBoatGroup(boat, groupAtLocation);
    }
  }

  void _showSingleBoat(BoatModel boat) {
    setState(() => _selectedBoat = boat);

    if (boat.location != null) {
      _mapController.move(
        LatLng(boat.location!.latitude + 0.01, boat.location!.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  void _showBoatGroup(BoatModel tappedBoat, List<BoatModel> group) {
    // Resalta el pin tocado mientras el sheet está abierto
    setState(() => _selectedBoat = tappedBoat);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BoatGroupSheet(
        boats: group,
        selectedBoatId: tappedBoat.id,
        onSelect: (selected) {
          Navigator.of(context).pop();
          _showSingleBoat(selected);
        },
      ),
    );
  }

  void _dismissPopup() => setState(() => _selectedBoat = null);

  void _openBoatDetail(BoatModel boat) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CustomerBoatDetailPage(boat: boat)),
    );
  }

  // Build que integra todo: mapa, pins, popups, controles y leyenda

  @override
  Widget build(BuildContext context) {
    final boatsAsync = ref.watch(boatsStreamProvider);

    return GestureDetector(
      onTap: _dismissPopup,
      child: Stack(
        children: [
          // Mapa con pins de barcos
          boatsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Error cargando barcos: $e',
                style: AppTheme.bodySmall,
              ),
            ),
            data: (boats) {
              final boatsWithLocation = boats
                  .where((b) => b.location != null)
                  .toList();

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: _initialZoom,
                  minZoom: 5,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onTap: (_, _) => _dismissPopup(),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.oceanrent.app',
                    maxZoom: 18,
                  ),
                  MarkerLayer(markers: _buildMarkers(boatsWithLocation)),
                ],
              );
            },
          ),

          // Popup del barco seleccionado
          if (_selectedBoat != null)
            Positioned(
              top: AppTheme.spacing16,
              left: AppTheme.spacing16,
              right: AppTheme.spacing16,
              child: GestureDetector(
                onTap: () {}, // Evita que el tap cierre el popup
                child: _BoatPopup(
                  boat: _selectedBoat!,
                  onClose: _dismissPopup,
                  onViewDetail: () => _openBoatDetail(_selectedBoat!),
                ),
              ),
            ),

          // Controles de zoom
          Positioned(
            bottom: 80,
            right: AppTheme.spacing16,
            child: _ZoomControls(mapController: _mapController),
          ),

          //  Leyenda de categorías
          Positioned(
            bottom: AppTheme.spacing16,
            right: AppTheme.spacing16,
            child: const _CategoryLegend(),
          ),
        ],
      ),
    );
  }
}

// Controles de zoom

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({required this.mapController});

  final MapController mapController;

  void _zoom(double delta) {
    final current = mapController.camera.zoom;
    mapController.move(mapController.camera.center, current + delta);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ZoomButton(icon: Icons.add, onTap: () => _zoom(1)),
        const SizedBox(height: AppTheme.spacing4),
        _ZoomButton(icon: Icons.remove, onTap: () => _zoom(-1)),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: AppTheme.cardDecoration(
          color: AppTheme.surface,
          radius: AppTheme.radiusSm,
        ),
        child: Icon(icon, size: AppTheme.iconSizeLg, color: AppTheme.deepNavy),
      ),
    );
  }
}

// Pin del barco

class _BoatPin extends StatelessWidget {
  const _BoatPin({required this.category, required this.isSelected});

  final String category;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = _pinColor(category);
    final borderColor = _pinBorderColor(category);
    final size = isSelected ? 44.0 : 34.0;

    return AnimatedContainer(
      duration: AppTheme.animationFast,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: AppTheme.borderWidthStrong,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: AppTheme.alphaOverlay),
            blurRadius: isSelected
                ? AppTheme.shadowBlurLg
                : AppTheme.shadowBlurSm,
            spreadRadius: isSelected ? 2 : 0,
          ),
        ],
      ),
      child: Icon(
        _categoryIcon(category),
        size: isSelected ? AppTheme.iconSizeLg : AppTheme.iconSizeMd,
        color: borderColor,
      ),
    );
  }

  IconData _categoryIcon(String cat) {
    switch (_normalizeCategory(cat)) {
      case 'velero':
        return Icons.sailing;
      case 'jetski':
      case 'jetsky':
        return Icons.waves;
      case 'catamaran':
        return Icons.directions_boat;
      case 'yate':
      case 'yateamotor':
        return Icons.directions_boat_filled;
      default:
        return Icons.directions_boat_outlined;
    }
  }
}

// Bottom sheet para grupo de barcos en el mismo puerto

class _BoatGroupSheet extends StatelessWidget {
  const _BoatGroupSheet({
    required this.boats,
    required this.selectedBoatId,
    required this.onSelect,
  });

  final List<BoatModel> boats;
  final String selectedBoatId;
  final ValueChanged<BoatModel> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        0,
        AppTheme.spacing16,
        AppTheme.spacing16,
      ),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacing16,
              AppTheme.spacing16,
              AppTheme.spacing16,
              AppTheme.spacing8,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: AppTheme.iconSizeMd,
                  color: AppTheme.deepNavy,
                ),
                const SizedBox(width: AppTheme.spacing6),
                Text(
                  '${boats.length} barcos en este puerto',
                  style: AppTheme.headlineSmall,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de barcos del grupo
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: boats.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final boat = boats[index];
              final isSelected = boat.id == selectedBoatId;

              return InkWell(
                onTap: () => onSelect(boat),
                child: Container(
                  color: isSelected
                      ? AppTheme.deepNavy.withValues(alpha: AppTheme.alphaChip)
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing16,
                    vertical: AppTheme.spacing10,
                  ),
                  child: Row(
                    children: [
                      // Dot de color de categoría
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _pinColor(boat.category),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _pinBorderColor(boat.category),
                            width: AppTheme.borderWidthStrong,
                          ),
                        ),
                        child: Icon(
                          _BoatPin(
                            category: boat.category,
                            isSelected: false,
                          )._categoryIcon(boat.category),
                          size: AppTheme.iconSizeMd,
                          color: _pinBorderColor(boat.category),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing12),

                      // Info del barco
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              boat.name,
                              style: AppTheme.labelMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppTheme.spacing2),
                            Wrap(
                              spacing: AppTheme.spacing6,
                              children: [
                                _InfoChip(
                                  label: boat.category,
                                  color: _pinColor(boat.category),
                                ),
                                _InfoChip(
                                  label: '${boat.pricePerDay.toInt()} €/día',
                                  color: AppTheme.sunsetGold,
                                ),
                                _InfoChip(
                                  label: '${boat.capacity} pers.',
                                  color: AppTheme.oceanBlue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Flecha indicativa
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.textSecondary,
                        size: AppTheme.iconSizeMd,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Espacio inferior seguro
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// Popup con info del barco (individual)

class _BoatPopup extends StatelessWidget {
  const _BoatPopup({
    required this.boat,
    required this.onClose,
    required this.onViewDetail,
  });

  final BoatModel boat;
  final VoidCallback onClose;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: AppTheme.borderRadiusCard,
      child: Container(
        decoration: AppTheme.cardDecoration(),
        child: Row(
          children: [
            // Imagen del barco
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radiusCard),
                bottomLeft: Radius.circular(AppTheme.radiusCard),
              ),
              child: boat.imageUrl.isNotEmpty
                  ? Image.network(
                      boat.imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      boat.name,
                      style: AppTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Wrap(
                      spacing: AppTheme.spacing4,
                      runSpacing: AppTheme.spacing4,
                      children: [
                        _InfoChip(
                          label: boat.category,
                          color: _pinColor(boat.category),
                        ),
                        _InfoChip(
                          label: '${boat.capacity} pers.',
                          color: AppTheme.oceanBlue,
                        ),
                        _InfoChip(
                          label: '${boat.pricePerDay.toInt()} €/día',
                          color: AppTheme.sunsetGold,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: AppTheme.iconSizeSmall,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: AppTheme.spacing2),
                        Expanded(
                          child: Text(
                            boat.portName,
                            style: AppTheme.helperTextStyle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onViewDetail,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(
                          Icons.open_in_new_rounded,
                          size: AppTheme.iconSizeSmall,
                        ),
                        label: const Text('Ver detalle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botón cerrar
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: AppTheme.spacing8,
                  top: AppTheme.spacing8,
                ),
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacing2),
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundDim,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: AppTheme.iconSizeMd,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: AppTheme.backgroundDim,
      child: const Icon(
        Icons.directions_boat,
        color: AppTheme.textSecondary,
        size: AppTheme.placeholderIconSize,
      ),
    );
  }
}

// Chip de info reutilizable

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppTheme.alphaChip),
        borderRadius: AppTheme.borderRadiusPill,
        border: Border.all(
          color: color.withValues(alpha: AppTheme.alphaBorder),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppTheme.fontSize11,
          fontWeight: FontWeight.w600,
          color: color == Colors.white ? AppTheme.deepNavy : color,
        ),
      ),
    );
  }
}

// Leyenda de categorías

class _CategoryLegend extends StatefulWidget {
  const _CategoryLegend();

  @override
  State<_CategoryLegend> createState() => _CategoryLegendState();
}

class _CategoryLegendState extends State<_CategoryLegend> {
  bool _expanded = false;

  static const _categories = [
    ('Lancha / Semirígida', Color(0xFF64B5F6)),
    ('Velero', Colors.white),
    ('Yate a Motor', AppTheme.sunsetGold),
    ('Catamarán', AppTheme.oceanBlue),
    ('Jet Ski', Colors.orange),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: AppTheme.animationNormal,
        padding: const EdgeInsets.all(AppTheme.spacing10),
        decoration: AppTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.legend_toggle,
                  size: AppTheme.iconSizeMd,
                  color: AppTheme.deepNavy,
                ),
                const SizedBox(width: AppTheme.spacing6),
                Text('Leyenda', style: AppTheme.labelMedium),
                const SizedBox(width: AppTheme.spacing6),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: AppTheme.iconSizeMd,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: AppTheme.spacing8),
              ..._categories.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacing2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: entry.$2,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: entry.$2 == Colors.white
                                ? AppTheme.deepNavy
                                : Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(entry.$1, style: AppTheme.helperTextStyle),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
