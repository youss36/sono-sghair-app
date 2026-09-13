import '../models/equipment.dart';
import 'local_store.dart';

class EquipmentApiService {
  final _store = LocalStore.instance;

  Future<List<Equipment>> fetchEquipments() async {
    final items = await _store.readAll('equipments');
    final list = items.map((item) => Equipment.fromJson(item)).toList();
    list.sort((a, b) => a.nomMateriel.compareTo(b.nomMateriel));
    return list;
  }

  Future<Equipment> createEquipment(Equipment equipment) async {
    final items = await _store.readAll('equipments');
    final exists = items.any((e) =>
        (e['nom_materiel'] as String).toLowerCase() ==
        equipment.nomMateriel.toLowerCase());
    if (exists) throw Exception('Ce matériel existe déjà');
    final saved = await _store.insert('equipments', {
      'id': await _store.nextId('equipments'),
      ...equipment.toJson(),
    });
    return Equipment.fromJson(saved);
  }

  Future<Equipment> updateEquipment(Equipment equipment) async {
    final updated = await _store.update(
        'equipments', equipment.id, equipment.toJson());
    if (updated == null) throw Exception('Matériel introuvable');
    return Equipment.fromJson(updated);
  }

  Future<void> deleteEquipment(String equipmentId) async {
    final ok = await _store.delete('equipments', equipmentId);
    if (!ok) throw Exception('Matériel introuvable');
  }
}
