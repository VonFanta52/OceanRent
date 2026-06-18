import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/repository/storage_repository.dart';
import 'package:ocean_rent/services/storage/firebase_storage_service.dart';

// Provider del servicio que se encarga de subir imágenes a Firebase Storage
final firebaseStorageServiceProvider = Provider<FirebaseStorageService>((ref) {
  return FirebaseStorageService();
});

// Provider del repositorio que usará el servicio anterior
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final firebaseStorageService = ref.watch(firebaseStorageServiceProvider);
  return StorageRepository(firebaseStorageService);
});
