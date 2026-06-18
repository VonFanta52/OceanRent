import 'package:image_picker/image_picker.dart';
import 'package:ocean_rent/models/user_model.dart';
import 'package:ocean_rent/services/storage/firebase_storage_service.dart';
import 'package:ocean_rent/services/user/user_service.dart';

class UserRepository {
  UserRepository(this._userService, this._storageService);

  final UserService _userService;
  final FirebaseStorageService _storageService;

  Future<UserModel> getUser(String uid) => _userService.getUser(uid);

  Stream<List<UserModel>> watchCustomersWithLicenses() =>
      _userService.watchCustomersWithLicenses();

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String surname,
  }) => _userService.updateProfile(uid: uid, name: name, surname: surname);

  Future<String> uploadLicenseDocument({
    required String uid,
    required XFile file,
  }) => _storageService.uploadLicenseDocument(uid: uid, file: file);

  Future<void> updateNauticalLicense({
    required String uid,
    required String type,
    required String documentUrl,
    required String status,
  }) => _userService.updateNauticalLicense(
    uid: uid,
    type: type,
    documentUrl: documentUrl,
    status: status,
  );

  Future<void> updateNauticalLicenseStatus({
    required String uid,
    required String status,
    String? rejectionReason,
  }) => _userService.updateNauticalLicenseStatus(
    uid: uid,
    status: status,
    rejectionReason: rejectionReason,
  );
}
