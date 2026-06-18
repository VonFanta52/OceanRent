import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/services/boat/boat_service.dart';

class BoatRepository {
  BoatRepository(this._boatService);

  final BoatService _boatService;

  Stream<List<BoatModel>> watchBoats() {
    return _boatService.getBoats();
  }

  Future<void> deleteBoat(String id) {
    return _boatService.deleteBoat(id);
  }
}
