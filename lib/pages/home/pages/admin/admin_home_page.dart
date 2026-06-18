import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/models/booking_model.dart';
import 'package:ocean_rent/pages/home/pages/admin/pages/admin_bookings_page.dart';
import 'package:ocean_rent/pages/home/pages/admin/pages/admin_calendar_page.dart';
import 'package:ocean_rent/pages/home/pages/admin/pages/admin_chats_page.dart';
import 'package:ocean_rent/pages/home/pages/admin/pages/admin_deposits_page.dart';
import 'package:ocean_rent/pages/home/pages/admin/pages/admin_licenses_page.dart';
import 'package:ocean_rent/pages/home/pages/admin/pages/admin_profile_screen.dart';
import 'package:ocean_rent/pages/home/pages/admin/pages/admin_reviews_page.dart';
import 'package:ocean_rent/pages/home/pages/admin/pages/boat_form_page.dart';
import 'package:ocean_rent/pages/home/pages/admin/widgets/admin_empty_section.dart';
import 'package:ocean_rent/pages/home/pages/admin/widgets/admin_quick_action_card.dart';
import 'package:ocean_rent/pages/home/pages/admin/widgets/admin_summary_card.dart';
import 'package:ocean_rent/pages/onboarding/onboarding_page.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/providers/boat_providers.dart';
import 'package:ocean_rent/providers/booking_providers.dart';
import 'package:ocean_rent/providers/user_providers.dart';
import 'package:ocean_rent/utils/boat_utils.dart';
import 'package:ocean_rent/widgets/boat_image_placeholder.dart';

class AdminHomePage extends ConsumerWidget {
  const AdminHomePage({super.key});

  Future<void> _deleteBoat(
    BuildContext context,
    WidgetRef ref,
    BoatModel boat,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusCard,
        ),
        title: Text('Eliminar barco', style: AppTheme.titleMedium),
        content: Text(
          '¿Seguro que quieres eliminar "${boat.name}"?',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textMuted,
            height: AppTheme.lineHeightInfo,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: AppTheme.labelMedium.copyWith(color: AppTheme.deepNavy),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Eliminar',
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.alertRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ref.read(boatRepositoryProvider).deleteBoat(boat.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barco eliminado correctamente')),
      );
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authNotifierProvider).signOut();
    ref.invalidate(bookingsStreamProvider);
    ref.invalidate(userBookingsStreamProvider);

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boatsAsync = ref.watch(boatsStreamProvider);
    final bookingsAsync = ref.watch(bookingsStreamProvider);
    final licensesAsync = ref.watch(customersWithLicensesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Panel Admin'),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            onPressed: () {
              Navigator.of(context).push(
                // Mantenimiento
                MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
              );
            },
            icon: const Icon(
              Icons.person_outline,
              size: AppTheme.iconSizeLarge,
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout, size: AppTheme.iconSizeLarge),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.deepNavy,
        foregroundColor: AppTheme.white,
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const BoatFormPage()));
        },
        icon: const Icon(Icons.add, size: AppTheme.iconSizeLarge),
        label: Text(
          'Nuevo Barco',
          style: AppTheme.buttonTextStyle.copyWith(color: AppTheme.white),
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
              'Error cargando el panel:\n$error',
              textAlign: TextAlign.center,
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.alertRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        data: (boats) {
          return bookingsAsync.when(
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
                  'Error cargando reservas:\n$error',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.alertRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            data: (bookings) {
              final pendingLicensesCount = licensesAsync.maybeWhen(
                data: (users) => users
                    .where((user) => user.nauticalLicense?.status == 'pending')
                    .length,
                orElse: () => 0,
              );

              return _AdminDashboard(
                boats: boats,
                bookings: bookings,
                pendingLicensesCount: pendingLicensesCount,
                onCreateBoat: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BoatFormPage()),
                  );
                },
                onEditBoat: (boat) async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BoatFormPage(boat: boat)),
                  );
                },
                onDeleteBoat: (boat) => _deleteBoat(context, ref, boat),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminDashboard extends StatefulWidget {
  final List<BoatModel> boats;
  final List<BookingModel> bookings;
  final int pendingLicensesCount;
  final VoidCallback onCreateBoat;
  final ValueChanged<BoatModel> onEditBoat;
  final ValueChanged<BoatModel> onDeleteBoat;

  const _AdminDashboard({
    required this.boats,
    required this.bookings,
    required this.pendingLicensesCount,
    required this.onCreateBoat,
    required this.onEditBoat,
    required this.onDeleteBoat,
  });

  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToFleetSection() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: AppTheme.animationNormal,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final boats = widget.boats;
    final bookings = widget.bookings;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    final upcomingBookings = bookings.where((booking) {
      final startDate = DateTime(
        booking.startDate.year,
        booking.startDate.month,
        booking.startDate.day,
      );

      return booking.status != BookingModel.statusCancelled &&
          !startDate.isBefore(todayOnly);
    }).length;

    final pendingBookings = bookings
        .where((booking) => booking.status == BookingModel.statusPending)
        .length;

    final heldDepositsAmount = bookings
        .where(
          (booking) =>
              booking.status != BookingModel.statusCancelled &&
              booking.depositStatus == BookingModel.depositStatusHeld,
        )
        .fold<double>(0, (total, booking) => total + booking.depositAmount);

    final recentBookings = [...bookings]
      ..sort((a, b) {
        final firstDate = a.createdAt ?? a.startDate;
        final secondDate = b.createdAt ?? b.startDate;
        return secondDate.compareTo(firstDate);
      });

    final boatNames = {for (final boat in boats) boat.id: boat.name};

    return ListView(
      controller: _scrollController,
      padding: AppTheme.adminDashboardPadding,
      children: [
        _AdminHeader(totalBoats: boats.length),
        const SizedBox(height: AppTheme.spacing20),
        const _SectionTitle(
          title: 'Resumen de actividad',
          subtitle: 'Estado general del panel de administración.',
        ),
        const SizedBox(height: AppTheme.spacing12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppTheme.spacing12,
          crossAxisSpacing: AppTheme.spacing12,
          childAspectRatio: AppTheme.adminSummaryAspectRatio,
          children: [
            AdminSummaryCard(
              title: 'Reservas proximas',
              value: '$upcomingBookings',
              subtitle: '$pendingBookings pendientes',
              icon: Icons.calendar_month_outlined,
              color: AppTheme.oceanBlue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminBookingsPage()),
                );
              },
            ),
            AdminSummaryCard(
              title: 'Fianzas retenidas',
              value: '${heldDepositsAmount.toStringAsFixed(0)} EUR',
              subtitle: 'Estado held',
              icon: Icons.payments_outlined,
              color: AppTheme.sunsetGold,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminDepositsPage()),
                );
              },
            ),
            AdminSummaryCard(
              title: 'Barcos registrados',
              value: '${boats.length}',
              subtitle: 'Datos reales de boats',
              icon: Icons.directions_boat_filled_outlined,
              color: AppTheme.deepNavy,
              onTap: _scrollToFleetSection,
            ),
            AdminSummaryCard(
              title: 'Titulaciones',
              value: '${widget.pendingLicensesCount}',
              subtitle: 'Pendientes de validar',
              icon: Icons.verified_user_outlined,
              color: AppTheme.alertRed,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminLicensesPage()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing26),
        const _SectionTitle(
          title: 'Accesos rápidos',
          subtitle: 'Acciones principales del administrador.',
        ),
        const SizedBox(height: AppTheme.spacing12),
        AdminQuickActionCard(
          title: 'Pedidos / reservas',
          subtitle: 'Consultar solicitudes de alquiler.',
          icon: Icons.assignment_outlined,
          color: AppTheme.oceanBlue,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminBookingsPage()),
            );
          },
        ),
        const SizedBox(height: AppTheme.spacing12),
        AdminQuickActionCard(
          title: 'Calendario',
          subtitle: 'Consultar disponibilidad de la flota.',
          icon: Icons.calendar_month_outlined,
          color: AppTheme.deepNavy,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminCalendarPage(initialTabIndex: 0),
              ),
            );
          },
        ),
        const SizedBox(height: AppTheme.spacing12),
        AdminQuickActionCard(
          title: 'Reseñas',
          subtitle: 'Gestionar reseñas de clientes.',
          icon: Icons.rate_review_outlined,
          color: AppTheme.oceanBlue,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AdminReviewsPage()));
          },
        ),
        const SizedBox(height: AppTheme.spacing12),
        AdminQuickActionCard(
          title: 'Mensajes',
          subtitle: 'Chatear con los clientes sobre sus reservas.',
          icon: Icons.forum_outlined,
          color: AppTheme.deepNavy,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AdminChatsPage()));
          },
        ),
        const SizedBox(height: AppTheme.spacing12),
        AdminQuickActionCard(
          title: 'Mantenimiento',
          subtitle: 'Bloquear fechas por revisión, avería o mantenimiento.',
          icon: Icons.build_outlined,
          color: AppTheme.sunsetGold,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AdminCalendarPage(initialTabIndex: 1),
              ),
            );
          },
        ),
        const SizedBox(height: AppTheme.spacing26),
        const _SectionTitle(
          title: 'Pedidos recientes',
          subtitle: 'Últimas reservas registradas en Firestore.',
        ),
        const SizedBox(height: AppTheme.spacing12),
        if (recentBookings.isEmpty)
          const AdminEmptySection(
            icon: Icons.event_note_outlined,
            title: 'No hay reservas todavía',
            message: 'Cuando un cliente reserve, aparecerá aquí.',
          )
        else
          ...recentBookings
              .take(3)
              .map(
                (booking) => Padding(
                  padding: AppTheme.cardBottomMargin,
                  child: _RecentBookingCard(
                    booking: booking,
                    boatName: boatNames[booking.boatId] ?? booking.boatId,
                  ),
                ),
              ),
        const SizedBox(height: AppTheme.spacing26),
        _SectionTitle(
          title: 'Gestión de flota',
          subtitle: 'CRUD de barcos disponible desde el panel.',
          trailing: TextButton.icon(
            onPressed: widget.onCreateBoat,
            style: AppTheme.compactTextButtonStyle,
            icon: const Icon(Icons.add, size: AppTheme.iconSizeLarge),
            label: Text(
              'Crear barco',
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.oceanBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        if (boats.isEmpty)
          AdminEmptySection(
            icon: Icons.directions_boat_filled_outlined,
            title: 'No hay barcos registrados',
            message:
                'Crea el primer barco para empezar a completar el catálogo.',
            buttonText: 'Crear barco',
            onPressed: widget.onCreateBoat,
          )
        else
          ...boats.map(
            (boat) => Padding(
              padding: AppTheme.cardBottomMargin,
              child: _BoatAdminCard(
                boat: boat,
                onEdit: () => widget.onEditBoat(boat),
                onDelete: () => widget.onDeleteBoat(boat),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final int totalBoats;

  const _AdminHeader({required this.totalBoats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.adminHeaderPadding,
      decoration: AppTheme.adminHeaderDecoration(),
      child: Row(
        children: [
          Container(
            width: AppTheme.adminHeaderIconBoxSize,
            height: AppTheme.adminHeaderIconBoxSize,
            decoration: AppTheme.adminIconBoxDecoration(AppTheme.white),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: AppTheme.white,
              size: AppTheme.iconSize3xl,
            ),
          ),
          const SizedBox(width: AppTheme.spacing14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel del Admin',
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.white,
                    fontSize: AppTheme.fontSize22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  'Control de reservas, calendario, flota y titulaciones.',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.white.withValues(
                      alpha: AppTheme.alphaTextMuted,
                    ),
                    height: AppTheme.lineHeightRegular,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacing10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalBoats',
                style: AppTheme.titleLarge.copyWith(
                  color: AppTheme.sunsetGold,
                  fontSize: AppTheme.fontSize26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'barcos',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.white.withValues(
                    alpha: AppTheme.alphaTextOnDark,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                subtitle,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                  height: AppTheme.lineHeightSmall,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _RecentBookingCard extends StatelessWidget {
  final BookingModel booking;
  final String boatName;

  const _RecentBookingCard({required this.booking, required this.boatName});

  @override
  Widget build(BuildContext context) {
    final statusColor = _bookingStatusColor(booking.status);

    return Container(
      padding: AppTheme.compactCardPadding,
      decoration: AppTheme.adminCardDecoration(),
      child: Row(
        children: [
          Container(
            width: AppTheme.summaryIconBoxSize,
            height: AppTheme.summaryIconBoxSize,
            decoration: AppTheme.adminIconBoxDecoration(statusColor),
            child: Icon(
              Icons.event_available_outlined,
              color: statusColor,
              size: AppTheme.iconSize2xl,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  boatName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.titleSmall.copyWith(color: AppTheme.deepNavy),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  '${_formatBookingDate(booking.startDate)} - ${_formatBookingDate(booking.endDate)}',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacing10),
          Container(
            padding: AppTheme.licenseStatusBadgePadding,
            decoration: AppTheme.badgeDecoration(color: statusColor),
            child: Text(
              booking.status,
              style: AppTheme.labelSmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _bookingStatusColor(String status) {
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

String _formatBookingDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

class _BoatAdminCard extends StatelessWidget {
  final BoatModel boat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BoatAdminCard({
    required this.boat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = boat.imageUrl.trim();

    return Container(
      decoration: AppTheme.cardDecoration(
        color: AppTheme.surface,
        radius: AppTheme.radiusCard,
        border: Border.all(
          color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
        ),
        boxShadow: AppTheme.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppTheme.borderRadiusCardTop,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: AppTheme.imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        BoatImagePlaceholder(name: boat.name),
                  )
                : BoatImagePlaceholder(name: boat.name),
          ),
          Padding(
            padding: AppTheme.compactCardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  boat.name,
                  style: AppTheme.titleLarge.copyWith(
                    color: AppTheme.deepNavy,
                    fontSize: AppTheme.fontSize22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Wrap(
                  spacing: AppTheme.spacing8,
                  runSpacing: AppTheme.spacing8,
                  children: [
                    _InfoChip(
                      icon: boat.isAvailable
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      label: boat.isAvailable ? 'Activo' : 'No disponible',
                      color: boat.isAvailable
                          ? AppTheme.oceanBlue
                          : AppTheme.alertRed,
                    ),
                    _InfoChip(
                      icon: Icons.directions_boat_outlined,
                      label: formatBoatCategory(boat.category),
                    ),
                    _InfoChip(
                      icon: Icons.people_alt_outlined,
                      label: '${boat.capacity} personas',
                    ),
                    _InfoChip(
                      icon: Icons.euro_outlined,
                      label: '${boat.pricePerDay.toStringAsFixed(0)} €/día',
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing14),
                Text(
                  boat.description.trim().isEmpty
                      ? 'Sin descripción'
                      : boat.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textMuted,
                    height: AppTheme.lineHeightLarge,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        style: AppTheme.outlinedButtonStyle.copyWith(
                          minimumSize: const WidgetStatePropertyAll(
                            Size.fromHeight(AppTheme.compactButtonHeight),
                          ),
                        ),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: AppTheme.iconSizeLarge,
                        ),
                        label: Text(
                          'Editar',
                          style: AppTheme.buttonTextStyle.copyWith(
                            color: AppTheme.deepNavy,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDelete,
                        style: AppTheme.destructiveButtonStyle.copyWith(
                          minimumSize: const WidgetStatePropertyAll(
                            Size.fromHeight(AppTheme.compactButtonHeight),
                          ),
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: AppTheme.iconSizeLarge,
                        ),
                        label: Text(
                          'Eliminar',
                          style: AppTheme.buttonTextStyle.copyWith(
                            color: AppTheme.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = AppTheme.oceanBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.chipPadding,
      decoration: AppTheme.badgeDecoration(
        color: color,
        alpha: AppTheme.alphaLight,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppTheme.iconSizeMedium, color: color),
          const SizedBox(width: AppTheme.spacing6),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.deepNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
