import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';

class BoatImagePicker extends StatelessWidget {
  const BoatImagePicker({
    super.key,
    required this.selectedImage,
    required this.imageUrl,
    required this.isPickingImage,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final File? selectedImage;
  final String imageUrl;
  final bool isPickingImage;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto del barco',
          style: AppTheme.titleMedium.copyWith(color: AppTheme.deepNavy),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Container(
          height: AppTheme.formImagePreviewHeight,
          width: double.infinity,
          decoration: AppTheme.cardDecoration(
            color: AppTheme.surface,
            radius: AppTheme.radiusButton,
            border: Border.all(
              color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaChip),
            ),
            boxShadow: [],
          ),
          child: ClipRRect(
            borderRadius: AppTheme.borderRadiusButton,
            child: selectedImage != null
                ? Image.file(selectedImage!, fit: BoxFit.cover)
                : imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _Placeholder(),
                  )
                : _Placeholder(),
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        SizedBox(
          width: double.infinity,
          height: AppTheme.compactButtonHeight,
          child: ElevatedButton.icon(
            onPressed: isPickingImage ? null : onPickImage,
            style: AppTheme.accentButtonStyle,
            icon: isPickingImage
                ? const SizedBox(
                    width: AppTheme.loadingSize,
                    height: AppTheme.loadingSize,
                    child: CircularProgressIndicator(
                      strokeWidth: AppTheme.progressStrokeWidth,
                      color: AppTheme.white,
                    ),
                  )
                : const Icon(
                    Icons.image_outlined,
                    size: AppTheme.iconSizeLarge,
                  ),
            label: Text(
              isPickingImage ? 'Seleccionando...' : 'Seleccionar imagen',
              style: AppTheme.buttonTextStyle.copyWith(color: AppTheme.white),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing6),
        Text(
          'Selecciona una imagen. Se subirá cuando guardes el formulario.',
          style: AppTheme.helperTextStyle.copyWith(color: AppTheme.textMuted),
        ),
        if (selectedImage != null) ...[
          const SizedBox(height: AppTheme.spacing8),
          TextButton.icon(
            onPressed: onRemoveImage,
            style: AppTheme.compactTextButtonStyle,
            icon: const Icon(
              Icons.delete_outline,
              size: AppTheme.iconSizeLarge,
              color: AppTheme.alertRed,
            ),
            label: Text(
              'Eliminar imagen',
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.alertRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: AppTheme.imagePickerIconSize,
          color: AppTheme.deepNavy.withValues(
            alpha: AppTheme.alphaTextSecondary,
          ),
        ),
      ),
    );
  }
}
