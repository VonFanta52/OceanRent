import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';

Future<void> mostrarDialogoConfirmacion(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required VoidCallback onAceptar,
  String textoCancelar = 'Cancelar',
  String textoAceptar = 'Aceptar',
}) async {
  final eleccion = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppTheme.borderRadiusCard,
      ),
      title: Text(titulo, style: AppTheme.titleMedium),
      content: Text(
        mensaje,
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.textMuted,
          height: AppTheme.lineHeightInfo,
        ),
      ),
      actionsPadding: const EdgeInsets.only(
        left: AppTheme.spacing16,
        right: AppTheme.spacing16,
        bottom: AppTheme.spacing12,
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(textoCancelar, style: AppTheme.labelMedium),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppTheme.oceanBlue),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            textoAceptar,
            style: AppTheme.labelMedium.copyWith(
              color: AppTheme.oceanBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  if (eleccion == true) {
    onAceptar();
  }
}
