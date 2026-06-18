import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/user_model.dart';
import 'package:ocean_rent/providers/user_providers.dart';

class AdminLicensesPage extends ConsumerStatefulWidget {
  const AdminLicensesPage({super.key});

  @override
  ConsumerState<AdminLicensesPage> createState() => _AdminLicensesPageState();
}

class _AdminLicensesPageState extends ConsumerState<AdminLicensesPage> {
  final Set<String> _updatingUsers = {};

  Future<void> _setLicenseStatus(UserModel user, String status) async {
    if (_updatingUsers.contains(user.uid)) return;

    final reason = status == NauticalLicenseStatus.rejected
        ? await _askRejectionReason()
        : null;

    if (!mounted) return;
    if (status == NauticalLicenseStatus.rejected && reason == null) return;
    if (status == NauticalLicenseStatus.rejected &&
        (reason?.trim().isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica un motivo para rechazar.')),
      );
      return;
    }

    setState(() => _updatingUsers.add(user.uid));

    try {
      await ref
          .read(userRepositoryProvider)
          .updateNauticalLicenseStatus(
            uid: user.uid,
            status: status,
            rejectionReason: reason,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_successMessage(status))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyError(error, 'No se pudo actualizar la titulacion.'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingUsers.remove(user.uid));
      }
    }
  }

  Future<String?> _askRejectionReason() {
    String reason = '';

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusCard,
        ),
        title: Text('Rechazar titulacion', style: AppTheme.titleMedium),
        content: TextField(
          maxLines: 3,
          onChanged: (value) => reason = value,
          decoration: AppTheme.inputDecoration(
            labelText: 'Motivo',
            icon: Icons.info_outline,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: AppTheme.destructiveButtonStyle,
            onPressed: () => Navigator.of(dialogContext).pop(reason.trim()),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  String _successMessage(String status) {
    return switch (status) {
      NauticalLicenseStatus.verified => 'Licencia validada correctamente',
      NauticalLicenseStatus.rejected => 'Licencia rechazada correctamente',
      _ => 'Licencia actualizada correctamente',
    };
  }

  String _friendlyError(Object error, String fallback) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    if (message.contains('permission-denied')) {
      return 'No tienes permisos para actualizar esta titulacion.';
    }

    return message.isEmpty ? fallback : message;
  }

  @override
  Widget build(BuildContext context) {
    final licensesAsync = ref.watch(customersWithLicensesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Titulaciones')),
      body: licensesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.oceanBlue),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: AppTheme.screenPadding,
            child: Text(
              'No se pudieron cargar las titulaciones.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.alertRed),
            ),
          ),
        ),
        data: (users) {
          if (users.isEmpty) return const _EmptyLicensesState();

          return ListView.separated(
            padding: AppTheme.listPadding,
            itemCount: users.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppTheme.spacing12),
            itemBuilder: (context, index) {
              final user = users[index];

              return _LicenseCard(
                key: ValueKey('license-${user.uid}'),
                user: user,
                isUpdating: _updatingUsers.contains(user.uid),
                onVerify: () =>
                    _setLicenseStatus(user, NauticalLicenseStatus.verified),
                onReject: () =>
                    _setLicenseStatus(user, NauticalLicenseStatus.rejected),
              );
            },
          );
        },
      ),
    );
  }
}

class _LicenseCard extends StatelessWidget {
  final UserModel user;
  final bool isUpdating;
  final VoidCallback onVerify;
  final VoidCallback onReject;

  const _LicenseCard({
    super.key,
    required this.user,
    required this.isUpdating,
    required this.onVerify,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final license = user.nauticalLicense;
    final fullName = '${user.name} ${user.surname}'.trim();
    final displayName = fullName.isEmpty ? 'Cliente' : fullName;
    final status = license?.status ?? 'none';
    final statusColor = _statusColor(status);

    return Container(
      padding: AppTheme.compactCardPadding,
      decoration: AppTheme.adminCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.oceanBlue,
                child: Text(
                  displayName[0].toUpperCase(),
                  style: AppTheme.labelLarge.copyWith(color: AppTheme.white),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.titleSmall.copyWith(
                        color: AppTheme.deepNavy,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: status, color: statusColor),
            ],
          ),
          const SizedBox(height: AppTheme.spacing14),
          _InfoRow(
            label: 'Tipo',
            value: (license?.type ?? 'none').toUpperCase(),
          ),
          _InfoRow(
            label: 'Documento',
            value: (license?.documentUrl.isNotEmpty ?? false)
                ? 'Subido'
                : 'No disponible',
          ),
          if ((license?.rejectionReason ?? '').trim().isNotEmpty)
            _InfoRow(label: 'Motivo', value: license!.rejectionReason!),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      isUpdating || status == NauticalLicenseStatus.verified
                      ? null
                      : onVerify,
                  style: AppTheme.accentButtonStyle,
                  icon: isUpdating
                      ? const SizedBox(
                          width: AppTheme.iconSizeMedium,
                          height: AppTheme.iconSizeMedium,
                          child: CircularProgressIndicator(
                            strokeWidth: AppTheme.progressStrokeWidth,
                            color: AppTheme.white,
                          ),
                        )
                      : const Icon(Icons.verified_outlined),
                  label: const Text('Validar'),
                ),
              ),
              const SizedBox(width: AppTheme.spacing10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      isUpdating || status == NauticalLicenseStatus.rejected
                      ? null
                      : onReject,
                  style: AppTheme.destructiveButtonStyle,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Rechazar'),
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
        _statusLabel(status),
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

class _EmptyLicensesState extends StatelessWidget {
  const _EmptyLicensesState();

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
                Icons.verified_user_outlined,
                color: AppTheme.oceanBlue,
                size: AppTheme.emptyStateIconSize,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'No hay titulaciones',
                style: AppTheme.titleMedium.copyWith(color: AppTheme.deepNavy),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Cuando un cliente suba su licencia náutica aparecerá aquí.',
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

Color _statusColor(String status) {
  return switch (status) {
    NauticalLicenseStatus.verified => AppTheme.oceanBlue,
    NauticalLicenseStatus.rejected => AppTheme.alertRed,
    NauticalLicenseStatus.pending => AppTheme.sunsetGold,
    _ => AppTheme.textSecondary,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    NauticalLicenseStatus.verified => 'Verificada',
    NauticalLicenseStatus.rejected => 'Rechazada',
    NauticalLicenseStatus.pending => 'Pendiente',
    _ => 'Sin estado',
  };
}
