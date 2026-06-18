import 'package:image_picker/image_picker.dart';
import 'package:ocean_rent/services/storage/firebase_storage_service.dart';

class StorageRepository {
  StorageRepository(this._firebaseStorageService);

  final FirebaseStorageService _firebaseStorageService;

  Future<String> uploadBoatImage({
    required String boatId,
    required XFile image,
  }) {
    return _firebaseStorageService.uploadBoatImage(
      boatId: boatId,
      image: image,
    );
  }
}
