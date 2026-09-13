import '../models/transport_vehicle.dart';
import 'local_store.dart';

class TransportApiService {
  final _store = LocalStore.instance;

  Future<List<TransportVehicle>> fetchVehicles() async {
    final items = await _store.readAll('transports');
    final list =
        items.map((item) => TransportVehicle.fromJson(item)).toList();
    list.sort((a, b) => a.modele.compareTo(b.modele));
    return list;
  }

  Future<TransportVehicle> createVehicle(TransportVehicle vehicle) async {
    final items = await _store.readAll('transports');
    final exists = items.any((v) =>
        (v['matricule'] as String).toLowerCase() ==
        vehicle.matricule.toLowerCase());
    if (exists) throw Exception('Ce matricule existe déjà');
    final saved = await _store.insert('transports', {
      'id': await _store.nextId('transports'),
      ...vehicle.toJson(),
    });
    return TransportVehicle.fromJson(saved);
  }

  Future<TransportVehicle> updateVehicle(TransportVehicle vehicle) async {
    final updated = await _store.update(
        'transports', vehicle.id, vehicle.toJson());
    if (updated == null) throw Exception('Véhicule introuvable');
    return TransportVehicle.fromJson(updated);
  }

  Future<void> deleteVehicle(String vehicleId) async {
    final ok = await _store.delete('transports', vehicleId);
    if (!ok) throw Exception('Véhicule introuvable');
  }
}
