import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/models/user_model.dart';
import 'package:ocean_rent/providers/auth_providers.dart';
import 'package:ocean_rent/providers/user_providers.dart';
import 'package:ocean_rent/widgets/profile_widgets.dart';

// Helpers y widgets anidados

enum LicenseStatus { pending, verified, rejected, none }

LicenseStatus _statusFromString(String s) => switch (s.toLowerCase()) {
  NauticalLicenseStatus.pending => LicenseStatus.pending,
  NauticalLicenseStatus.verified => LicenseStatus.verified,
  NauticalLicenseStatus.rejected => LicenseStatus.rejected,
  _ => LicenseStatus.none,
};

({Color color, IconData icon, String label}) _statusCfg(LicenseStatus s) =>
    switch (s) {
      LicenseStatus.verified => (
        color: AppTheme.oceanBlue,
        icon: Icons.check_circle_rounded,
        label: 'Verificado',
      ),
      LicenseStatus.pending => (
        color: AppTheme.sunsetGold,
        icon: Icons.hourglass_top_rounded,
        label: 'Pendiente',
      ),
      LicenseStatus.rejected => (
        color: AppTheme.alertRed,
        icon: Icons.cancel_rounded,
        label: 'Rechazado',
      ),
      LicenseStatus.none => (
        color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaDisabled),
        icon: Icons.remove_circle_outline_rounded,
        label: 'Sin verificar',
      ),
    };

String _formatBirthDate(DateTime? birthDate) {
  if (birthDate == null) return 'No indicada';

  final day = birthDate.day.toString().padLeft(2, '0');
  final month = birthDate.month.toString().padLeft(2, '0');
  final year = birthDate.year.toString();

  return '$day/$month/$year';
}
// SCREEN PRINCIPAL

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxLicenseFileSizeBytes = 10 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();

  UserModel? _profile;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;
  LicenseStatus _licenseStatus = LicenseStatus.none;
  String _licenseType = 'none';
  String? _pickedFileName;

  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: AppTheme.fadeDuration,
  );
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _fadeCtrl,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _emailCtrl.dispose();
    _birthDateCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // Lógica y funciones auxiliares

  Future<void> _loadProfile() async {
    final auth = ref.read(authNotifierProvider);
    if (auth.currentUser == null) await auth.checkCurrentSession();

    final uid = ref.read(authNotifierProvider).currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      _snack('No se pudo obtener el usuario', error: true);
      return;
    }
    try {
      final profile = await ref.read(userRepositoryProvider).getUser(uid);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameCtrl.text = profile.name;
        _surnameCtrl.text = profile.surname;
        _emailCtrl.text = profile.email;
        _birthDateCtrl.text = _formatBirthDate(profile.birthDate);
        _licenseStatus = _statusFromString(
          profile.nauticalLicense?.status ?? 'none',
        );
        _licenseType = profile.nauticalLicense?.type ?? 'none';
        _isLoading = false;
      });
      _fadeCtrl.forward();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _snack('Error al cargar el perfil: $e', error: true);
    }
  }

  Future<void> _pickDocument() async {
    if (_licenseType == 'none') {
      _snack('Selecciona primero el tipo de titulación', error: true);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final pickedFile = result.files.single;

    if (pickedFile.bytes == null && pickedFile.path == null) {
      _snack('No se pudo leer el archivo', error: true);
      return;
    }

    if (pickedFile.size > _maxLicenseFileSizeBytes) {
      _snack('El documento no puede superar los 10 MB', error: true);
      return;
    }

    setState(() {
      _pickedFileName = pickedFile.name;
      _isUploading = true;
    });

    try {
      final uid = ref.read(authNotifierProvider).currentUser!.uid;
      final repo = ref.read(userRepositoryProvider);

      final documentUrl = await repo.uploadLicenseDocument(
        uid: uid,
        file: pickedFile.path != null
            ? XFile(pickedFile.path!, name: pickedFile.name)
            : XFile.fromData(
                pickedFile.bytes!,
                name: pickedFile.name,
                mimeType: _mimeTypeForFileName(pickedFile.name),
              ),
      );

      await repo.updateNauticalLicense(
        uid: uid,
        type: _licenseType,
        documentUrl: documentUrl,
        status: NauticalLicenseStatus.pending,
      );

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _licenseStatus = LicenseStatus.pending;
        _profile = UserModel(
          uid: _profile!.uid,
          email: _profile!.email,
          name: _profile!.name,
          surname: _profile!.surname,
          birthDate: _profile!.birthDate,
          role: _profile!.role,
          nauticalLicense: NauticalLicense(
            type: _licenseType,
            documentUrl: documentUrl,
            status: NauticalLicenseStatus.pending,
          ),
        );
      });
      _snack('Titulación enviada para verificación');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      _snack(
        _friendlyError(e, 'No se pudo guardar la titulación'),
        error: true,
      );
    }
  }

  String _mimeTypeForFileName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    return switch (extension) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final uid = ref.read(authNotifierProvider).currentUser!.uid;
      await ref
          .read(userRepositoryProvider)
          .updateProfile(
            uid: uid,
            name: _nameCtrl.text.trim(),
            surname: _surnameCtrl.text.trim(),
          );
      _snack('Perfil actualizado correctamente');
    } catch (e) {
      _snack(_friendlyError(e, 'No se pudo guardar el perfil'), error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final profileEmail = _profile?.email.trim() ?? '';
    final email = profileEmail.isNotEmpty
        ? await _confirmPasswordResetEmail(profileEmail)
        : await _askPasswordResetEmail();

    if (!mounted || email == null) return;

    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      _snack('Introduce un correo válido', error: true);
      return;
    }

    final success = await ref
        .read(authNotifierProvider)
        .sendPasswordResetEmail(email: normalizedEmail);

    if (!mounted) return;

    if (success) {
      _snack('Correo de restablecimiento enviado');
      return;
    }

    _snack(
      ref.read(authNotifierProvider).errorMessage ??
          'No se pudo enviar el correo de restablecimiento',
      error: true,
    );
  }

  Future<String?> _confirmPasswordResetEmail(String email) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusCard,
        ),
        title: Text('Restablecer contraseña', style: AppTheme.titleMedium),
        content: Text(
          'Enviar correo de recuperacion a $email?',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: AppTheme.accentButtonStyle,
            onPressed: () => Navigator.of(dialogContext).pop(email),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  Future<String?> _askPasswordResetEmail() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusCard,
        ),
        title: Text('Restablecer contraseña', style: AppTheme.titleMedium),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: AppTheme.inputDecoration(
            labelText: 'Correo electrónico',
            icon: Icons.mail_outline,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: AppTheme.accentButtonStyle,
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
        ),
        backgroundColor: error ? AppTheme.alertRed : AppTheme.oceanBlue,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTheme.borderRadiusInput,
        ),
        margin: AppTheme.listPadding,
      ),
    );
  }

  String _friendlyError(Object error, String fallback) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    if (message.contains('permission-denied')) {
      return 'No tienes permisos para realizar esta acción.';
    }

    if (message.isEmpty) return fallback;

    return message;
  }

  // Build principal

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.oceanBlue),
      );
    }
    if (_profile == null) {
      return Center(
        child: Text(
          'No se pudo cargar el perfil',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.deepNavy),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        padding: AppTheme.responsiveScreenPadding(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarSection(profile: _profile!),
              const SizedBox(height: AppTheme.spacing32),
              const ProfileSectionLabel('Datos Personales'),
              const SizedBox(height: AppTheme.spacing16),
              _PersonalDataCard(
                nameCtrl: _nameCtrl,
                surnameCtrl: _surnameCtrl,
                emailCtrl: _emailCtrl,
                birthDateCtrl: _birthDateCtrl,
              ),
              const SizedBox(height: AppTheme.spacing28),
              const ProfileSectionLabel('Titulación Náutica'),
              const SizedBox(height: AppTheme.spacing16),
              _NauticalCard(
                licenseStatus: _licenseStatus,
                licenseType: _licenseType,
                pickedFileName: _pickedFileName,
                isUploading: _isUploading,
                profile: _profile!,
                onTypeChanged: (v) => setState(() => _licenseType = v),
                onPickDocument: _pickDocument,
              ),
              const SizedBox(height: AppTheme.spacing28),
              const ProfileSectionLabel('Seguridad'),
              const SizedBox(height: AppTheme.spacing16),
              _SecurityCard(onPasswordReset: _sendPasswordReset),
              const SizedBox(height: AppTheme.spacing36),
              ProfileSaveButton(isSaving: _isSaving, onPressed: _saveProfile),
              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
      ),
    );
  }
}

// WIDGETS ANIDADOS
// Avatar

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.profile});

  final UserModel profile;

  @override
  Widget build(BuildContext context) {
    final initials = (profile.name.isNotEmpty && profile.surname.isNotEmpty)
        ? '${profile.name[0]}${profile.surname[0]}'.toUpperCase()
        : profile.name.isNotEmpty
        ? profile.name[0].toUpperCase()
        : '?';
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: AppTheme.avatarSize,
                height: AppTheme.avatarSize,
                decoration: AppTheme.profileAvatarDecoration(),
                child: Center(
                  child: Text(
                    initials,
                    style: AppTheme.headlineLarge.copyWith(
                      color: AppTheme.white,
                      fontSize: AppTheme.fontSize30,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: AppTheme.avatarCameraSize,
                  height: AppTheme.avatarCameraSize,
                  decoration: AppTheme.profileCameraDecoration(),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: AppTheme.iconSizeSmall,
                    color: AppTheme.deepNavy.withValues(
                      alpha: AppTheme.alphaDisabled,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            '${profile.name} ${profile.surname}',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Container(
            padding: AppTheme.profileBadgePadding,
            decoration: AppTheme.badgeDecoration(color: AppTheme.oceanBlue),
            child: Text('Cliente', style: AppTheme.badgeTextStyle),
          ),
        ],
      ),
    );
  }
}

// Datos personales

class _PersonalDataCard extends StatelessWidget {
  const _PersonalDataCard({
    required this.nameCtrl,
    required this.surnameCtrl,
    required this.emailCtrl,
    required this.birthDateCtrl,
  });

  final TextEditingController nameCtrl, surnameCtrl, emailCtrl, birthDateCtrl;

  static String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null;

  @override
  Widget build(BuildContext context) => ProfileCard(
    child: Column(
      children: [
        ProfileField(
          controller: nameCtrl,
          label: 'Nombre',
          icon: Icons.person_outline_rounded,
          validator: _required,
        ),
        const SizedBox(height: AppTheme.spacing20),
        ProfileField(
          controller: surnameCtrl,
          label: 'Apellidos',
          icon: Icons.badge_outlined,
          validator: _required,
        ),
        const SizedBox(height: AppTheme.spacing20),
        ProfileField(
          controller: emailCtrl,
          label: 'Correo Electrónico',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          readOnly: true,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Campo requerido';
            if (!v.contains('@')) return 'Email inválido';
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacing20),
        ProfileField(
          controller: birthDateCtrl,
          label: 'Fecha de nacimiento',
          icon: Icons.cake_outlined,
          readOnly: true,
        ),
      ],
    ),
  );
}

class _SecurityCard extends StatelessWidget {
  final VoidCallback onPasswordReset;

  const _SecurityCard({required this.onPasswordReset});

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      child: Row(
        children: [
          Container(
            width: AppTheme.summaryIconBoxSize,
            height: AppTheme.summaryIconBoxSize,
            decoration: AppTheme.adminIconBoxDecoration(AppTheme.oceanBlue),
            child: const Icon(
              Icons.lock_reset_outlined,
              color: AppTheme.oceanBlue,
              size: AppTheme.iconSize2xl,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restablecer contraseña',
                  style: AppTheme.titleSmall.copyWith(color: AppTheme.deepNavy),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  'Recibe un correo para cambiar la contraseña de tu cuenta.',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          IconButton(
            tooltip: 'Enviar correo de restablecimiento',
            onPressed: onPasswordReset,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

// Titulación náutica

class _NauticalCard extends StatelessWidget {
  const _NauticalCard({
    required this.licenseStatus,
    required this.licenseType,
    required this.pickedFileName,
    required this.isUploading,
    required this.profile,
    required this.onTypeChanged,
    required this.onPickDocument,
  });

  final LicenseStatus licenseStatus;
  final String licenseType;
  final String? pickedFileName;
  final bool isUploading;
  final UserModel profile;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onPickDocument;

  static const _licenseTypes = [
    ('none', 'Sin licencia'),
    ('pnb', 'Patrón de Navegación Básica (PNB)'),
    ('per', 'Patrón de Embarcaciones de Recreo (PER)'),
  ];

  @override
  Widget build(BuildContext context) {
    final cfg = _statusCfg(licenseStatus);
    return ProfileCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Estado de verificación',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.deepNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: AppTheme.animationNormal,
                padding: AppTheme.licenseStatusBadgePadding,
                decoration: AppTheme.badgeDecoration(color: cfg.color),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cfg.icon,
                      size: AppTheme.iconSizeMini,
                      color: cfg.color,
                    ),
                    const SizedBox(width: AppTheme.spacing5),
                    Text(
                      cfg.label,
                      style: AppTheme.labelSmall.copyWith(
                        color: cfg.color,
                        fontWeight: FontWeight.w700,
                        fontSize: AppTheme.fontSize12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing20),
          DropdownButtonFormField<String>(
            initialValue: licenseType,
            isExpanded: true,
            decoration: AppTheme.inputDecoration(
              labelText: 'Tipo de titulación',
              icon: Icons.anchor_rounded,
            ),
            style: AppTheme.fieldTextStyle,
            dropdownColor: AppTheme.white,
            borderRadius: AppTheme.borderRadiusInput,
            items: _licenseTypes
                .map(
                  (t) => DropdownMenuItem(
                    value: t.$1,
                    child: Text(
                      t.$2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.deepNavy,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onTypeChanged(v);
            },
          ),
          const SizedBox(height: AppTheme.spacing20),
          Divider(
            color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaMedium),
          ),
          const SizedBox(height: AppTheme.spacing16),
          _DocumentUpload(
            licenseStatus: licenseStatus,
            pickedFileName: pickedFileName,
            isUploading: isUploading,
            profile: profile,
            onTap: onPickDocument,
          ),
        ],
      ),
    );
  }
}

// Upload de documentos

class _DocumentUpload extends StatelessWidget {
  const _DocumentUpload({
    required this.licenseStatus,
    required this.pickedFileName,
    required this.isUploading,
    required this.profile,
    required this.onTap,
  });

  final LicenseStatus licenseStatus;
  final String? pickedFileName;
  final bool isUploading;
  final UserModel profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFile =
        pickedFileName != null ||
        (profile.nauticalLicense?.documentUrl.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documento acreditativo',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.deepNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          'Sube tu titulación en formato PDF, JPG o PNG (máx. 10 MB)',
          style: AppTheme.helperTextStyle,
        ),
        const SizedBox(height: AppTheme.spacing14),
        GestureDetector(
          onTap: isUploading ? null : onTap,
          child: AnimatedContainer(
            duration: AppTheme.animationFast,
            width: double.infinity,
            padding: AppTheme.documentUploadPadding,
            decoration: AppTheme.uploadBoxDecoration(hasFile: hasFile),
            child: isUploading
                ? Column(
                    children: [
                      const SizedBox(
                        width: AppTheme.documentUploadLoadingSize,
                        height: AppTheme.documentUploadLoadingSize,
                        child: CircularProgressIndicator(
                          strokeWidth: AppTheme.progressStrokeWidth,
                          color: AppTheme.oceanBlue,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing10),
                      Text(
                        'Subiendo documento...',
                        style: AppTheme.helperTextStyle,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasFile
                            ? Icons.insert_drive_file_rounded
                            : Icons.upload_file_rounded,
                        color: hasFile
                            ? AppTheme.oceanBlue
                            : AppTheme.deepNavy.withValues(
                                alpha: AppTheme.alphaDisabled,
                              ),
                        size: AppTheme.iconSizeXl,
                      ),
                      const SizedBox(width: AppTheme.spacing10),
                      Flexible(
                        child: Text(
                          pickedFileName ??
                              ((profile
                                          .nauticalLicense
                                          ?.documentUrl
                                          .isNotEmpty ??
                                      false)
                                  ? 'Documento subido'
                                  : 'Seleccionar documento'),
                          style: AppTheme.helperTextStyle.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: AppTheme.fontSize13,
                            color: hasFile
                                ? AppTheme.oceanBlue
                                : AppTheme.deepNavy.withValues(
                                    alpha: AppTheme.alphaDisabled,
                                  ),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!hasFile) ...[
                        const SizedBox(width: AppTheme.spacing6),
                        Container(
                          padding: AppTheme.browseBadgePadding,
                          decoration: BoxDecoration(
                            color: AppTheme.oceanBlue.withValues(
                              alpha: AppTheme.alphaMedium,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXs,
                            ),
                          ),
                          child: Text(
                            'Examinar',
                            style: AppTheme.badgeTextStyle.copyWith(
                              fontSize: AppTheme.fontSize11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        if (licenseStatus == LicenseStatus.rejected) ...[
          const SizedBox(height: AppTheme.spacing10),
          _InfoBanner(
            color: AppTheme.alertRed,
            icon: Icons.info_outline_rounded,
            text: _rejectionMessage(profile.nauticalLicense?.rejectionReason),
          ),
        ],
        if (licenseStatus == LicenseStatus.pending) ...[
          const SizedBox(height: AppTheme.spacing10),
          _InfoBanner(
            color: AppTheme.sunsetGold,
            icon: Icons.hourglass_top_rounded,
            text: 'Documento en revisión. Te avisaremos cuando sea verificado.',
          ),
        ],
        if (licenseStatus == LicenseStatus.verified) ...[
          const SizedBox(height: AppTheme.spacing10),
          _InfoBanner(
            color: AppTheme.oceanBlue,
            icon: Icons.verified_rounded,
            text: 'Tu titulación náutica ha sido verificada correctamente.',
          ),
        ],
      ],
    );
  }

  String _rejectionMessage(String? reason) {
    final cleanReason = reason?.trim() ?? '';

    if (cleanReason.isEmpty) {
      return 'Tu documento fue rechazado. Por favor, sube uno nuevo.';
    }

    return 'Tu documento fue rechazado: $cleanReason. Puedes subir uno nuevo.';
  }
}

// Info del banner

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.color,
    required this.icon,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: AppTheme.infoBannerPadding,
    decoration: AppTheme.infoBannerDecoration(color),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppTheme.iconSizeMd, color: color),
        const SizedBox(width: AppTheme.spacing8),
        Expanded(child: Text(text, style: AppTheme.infoBannerTextStyle(color))),
      ],
    ),
  );
}
