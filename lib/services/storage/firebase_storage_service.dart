import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseStorageService {
  FirebaseStorageService({FirebaseStorage? firebaseStorage})
    : _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance;

  final FirebaseStorage _firebaseStorage;

  Future<String> uploadBoatImage({
    required String boatId,
    required XFile image,
  }) async {
    final file = File(image.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
    final ref = _firebaseStorage.ref().child('boats/$boatId/$fileName');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadLicenseDocument({
    required String uid,
    required XFile file,
  }) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final ref = _firebaseStorage.ref().child('licenses/$uid/$fileName');
    final metadata = SettableMetadata(contentType: _contentType(file.name));

    if (kIsWeb) {
      await ref.putData(await file.readAsBytes(), metadata);
    } else {
      await ref.putFile(File(file.path), metadata);
    }

    return ref.getDownloadURL();
  }

  String? _contentType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    return switch (extension) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      _ => null,
    };
  }
}
