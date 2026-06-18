import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocean_rent/models/boat_model.dart';
import 'package:ocean_rent/repository/boat_repository.dart';
import 'package:ocean_rent/services/boat/boat_service.dart';

final boatRepositoryProvider = Provider<BoatRepository>((ref) {
  return BoatRepository(BoatService.instance);
});

final boatsStreamProvider = StreamProvider<List<BoatModel>>((ref) {
  final repository = ref.watch(boatRepositoryProvider);
  return repository.watchBoats();
});
