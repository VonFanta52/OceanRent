import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';

/// Contenedor genérico para secciones de perfil
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: AppTheme.cardPadding,
    decoration: AppTheme.cardDecoration(),
    child: child,
  );
}

/// Etiqueta de sección del perfil con color opcional
class ProfileSectionLabel extends StatelessWidget {
  const ProfileSectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: color != null
        ? AppTheme.sectionLabelStyle.copyWith(color: color)
        : AppTheme.sectionLabelStyle,
  );
}

/// Campo de texto de perfil reutilizable
class ProfileField extends StatelessWidget {
  const ProfileField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool readOnly;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    readOnly: readOnly,
    validator: validator,
    style: readOnly ? AppTheme.readOnlyFieldTextStyle : AppTheme.fieldTextStyle,
    decoration:
        AppTheme.inputDecoration(
          labelText: label,
          icon: icon,
          readOnly: readOnly,
        ).copyWith(
          errorStyle: AppTheme.helperTextStyle.copyWith(color: AppTheme.error),
        ),
  );
}

/// Botón de guardar cambios del perfil
class ProfileSaveButton extends StatelessWidget {
  const ProfileSaveButton({
    super.key,
    required this.isSaving,
    required this.onPressed,
  });

  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: AppTheme.buttonHeight,
    child: ElevatedButton(
      onPressed: isSaving ? null : onPressed,
      style: AppTheme.accentButtonStyle.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppTheme.oceanBlue.withValues(alpha: AppTheme.alphaDisabled);
          }
          return AppTheme.oceanBlue;
        }),
      ),
      child: isSaving
          ? const SizedBox(
              width: AppTheme.loadingSize,
              height: AppTheme.loadingSize,
              child: CircularProgressIndicator(
                strokeWidth: AppTheme.progressStrokeWidth,
                color: AppTheme.white,
              ),
            )
          : Text(
              'Guardar cambios',
              style: AppTheme.buttonTextStyle.copyWith(color: AppTheme.white),
            ),
    ),
  );
}
