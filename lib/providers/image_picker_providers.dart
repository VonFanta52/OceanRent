import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocean_rent/services/image/image_picker_service.dart';

final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});

final selectedImagesProvider =
    StateNotifierProvider<SelectedImagesNotifier, List<XFile>>((ref) {
      final imagePickerService = ref.read(imagePickerServiceProvider);
      return SelectedImagesNotifier(imagePickerService);
    });

// Controla la lista de imágenes seleccionadas.
class SelectedImagesNotifier extends StateNotifier<List<XFile>> {
  final ImagePickerService _imagePickerService;

  // Estado inicial: lista vacía.
  SelectedImagesNotifier(this._imagePickerService) : super([]);

  // Selecciona varias imágenes y actualiza el estado.
  Future<void> pickImages() async {
    final images = await _imagePickerService.pickMultipleImages();
    state = images;
  }

  // Vacía la lista de imágenes seleccionadas.
  void clearImages() {
    state = [];
  }
}
