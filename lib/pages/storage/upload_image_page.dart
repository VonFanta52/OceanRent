import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocean_rent/core/theme/app_theme.dart';
import 'package:ocean_rent/services/storage/storage_service.dart';

class UploadImagePage extends StatefulWidget {
  const UploadImagePage({super.key});

  @override
  State<UploadImagePage> createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  final ImagePicker _picker = ImagePicker();

  List<File> _selectedImages = [];
  List<String> _imageUrls = [];
  bool _isUploading = false;

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(
      imageQuality: 85,
    );

    if (pickedFiles.isEmpty) return;

    setState(() {
      _selectedImages = pickedFiles.map((file) => File(file.path)).toList();
      _imageUrls = [];
    });
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final List<String> urls = [];

      for (final image in _selectedImages) {
        final String url = await StorageService.instance.uploadImage(image);
        urls.add(url);
      }

      setState(() {
        _imageUrls = urls;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imágenes subidas correctamente',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusInput,
          ),
          margin: AppTheme.listPadding,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al subir las imágenes',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.white),
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusInput,
          ),
          margin: AppTheme.listPadding,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Widget _buildSelectedImagesGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: AppTheme.imageGridCrossAxisCount,
        crossAxisSpacing: AppTheme.spacing8,
        mainAxisSpacing: AppTheme.spacing8,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: AppTheme.borderRadiusInput,
          child: Image.file(_selectedImages[index], fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildEmptyImagesState() {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      decoration: AppTheme.cardDecoration(
        color: AppTheme.surface,
        border: Border.all(
          color: AppTheme.deepNavy.withValues(alpha: AppTheme.alphaSoft),
        ),
        boxShadow: [],
      ),
      child: Text(
        'No has seleccionado ninguna imagen',
        textAlign: TextAlign.center,
        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildGeneratedUrls() {
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: AppTheme.generatedUrlMargin,
            child: SelectableText(
              _imageUrls[index],
              style: AppTheme.bodySmall.copyWith(color: AppTheme.deepNavy),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Práctica Firebase Storage')),
      body: Padding(
        padding: AppTheme.listPadding,
        child: Column(
          children: [
            Expanded(
              child: _selectedImages.isNotEmpty
                  ? _buildSelectedImagesGrid()
                  : _buildEmptyImagesState(),
            ),
            const SizedBox(height: AppTheme.spacing20),
            SizedBox(
              width: double.infinity,
              height: AppTheme.compactButtonHeight,
              child: ElevatedButton(
                onPressed: _pickImages,
                style: AppTheme.accentButtonStyle,
                child: Text(
                  'Seleccionar imágenes',
                  style: AppTheme.buttonTextStyle.copyWith(
                    color: AppTheme.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            SizedBox(
              width: double.infinity,
              height: AppTheme.compactButtonHeight,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadImages,
                style: AppTheme.fullWidthPrimaryButtonStyle,
                child: _isUploading
                    ? const SizedBox(
                        width: AppTheme.loadingSize,
                        height: AppTheme.loadingSize,
                        child: CircularProgressIndicator(
                          strokeWidth: AppTheme.borderWidthThin * 2,
                          color: AppTheme.white,
                        ),
                      )
                    : Text(
                        'Subir a Firebase Storage',
                        style: AppTheme.buttonTextStyle.copyWith(
                          color: AppTheme.pearlWhite,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppTheme.spacing20),
            if (_imageUrls.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'URLs generadas:',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.deepNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              _buildGeneratedUrls(),
            ],
          ],
        ),
      ),
    );
  }
}
