import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  // Abre la galería y devuelve varias imágenes seleccionadas.
  Future<List<XFile>> pickMultipleImages() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 85);

    return images;
  }
}
