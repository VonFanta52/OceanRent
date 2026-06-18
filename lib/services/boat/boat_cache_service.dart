import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/services/boat/boat_service.dart';

class BoatCacheService {
  final box = Hive.box<BoatModel>('boats');

  List<BoatModel> getCachedBoats() {
    return box.values.toList();
  }

  void syncWithFirebase() {
    BoatService.instance.getBoats().listen((boats) {
      for (final boat in boats) {
        box.put(boat.id, boat);
        debugPrint('Hive actualizado: ${boat.name}');
      }
    });
  }

  Future<void> clearCache() => box.clear();
}
