import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ocean_rent/models/boat_model.dart';

class BoatService {
  BoatService._();

  static final BoatService instance = BoatService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _boatsCollection =>
      _firestore.collection('boats');

  Stream<List<BoatModel>> getBoats() {
    return _boatsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BoatModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> createBoat({
    required String name,
    required String category,
    required int capacity,
    required double pricePerDay,
    required String description,
    required String imageUrl,
    required String portName,
    required double depositAmount,
    required String requiredLicense,
    required bool isAvailable,
    GeoPoint? location, // NUEVO
  }) async {
    await _boatsCollection.add({
      'name': name.trim(),
      'category': category.trim(),
      'capacity': capacity,
      'price_per_day': pricePerDay,
      'description': description.trim(),
      'imageUrl': imageUrl.trim(),
      'port_name': portName.trim(),
      'deposit_amount': depositAmount,
      'required_license': requiredLicense,
      'is_available': isAvailable,
      'location': location,
      // Guardamos la ubicación aunque sea null para eliminarla si el usuario decide quitarla
    });
  }

  Future<void> updateBoat({
    required String id,
    required String name,
    required String category,
    required int capacity,
    required double pricePerDay,
    required String description,
    required String imageUrl,
    required String portName,
    required double depositAmount,
    required String requiredLicense,
    required bool isAvailable,
    GeoPoint? location, // NUEVO
  }) async {
    await _boatsCollection.doc(id).update({
      'name': name.trim(),
      'category': category.trim(),
      'capacity': capacity,
      'price_per_day': pricePerDay,
      'description': description.trim(),
      'imageUrl': imageUrl.trim(),
      'port_name': portName.trim(),
      'deposit_amount': depositAmount,
      'required_license': requiredLicense,
      'is_available': isAvailable,
      'location': location,
      // Guardamos la ubicación aunque sea null para eliminarla si el usuario decide quitarla
    });
  }

  Future<void> deleteBoat(String id) async {
    await _boatsCollection.doc(id).delete();
  }
}
