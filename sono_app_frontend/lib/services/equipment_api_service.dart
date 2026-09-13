import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/equipment.dart';
import 'event_api_service.dart';

class EquipmentApiService {
  static const Duration _timeout = Duration(seconds: 10);

  static Uri _uri([String path = '']) =>
      Uri.parse('${EventApiService.baseUrl}/equipments$path');

  Future<List<Equipment>> fetchEquipments() async {
    final response = await http.get(_uri()).timeout(_timeout);
    _throwIfFailed(response);
    try {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => Equipment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw Exception('Données serveur invalides');
    }
  }

  Future<Equipment> createEquipment(Equipment equipment) async {
    final response = await http
        .post(
          _uri(),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(equipment.toJson()),
        )
        .timeout(_timeout);
    _throwIfFailed(response);
    return Equipment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Equipment> updateEquipment(Equipment equipment) async {
    final response = await http
        .put(
          _uri('/${equipment.id}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(equipment.toJson()),
        )
        .timeout(_timeout);
    _throwIfFailed(response);
    return Equipment.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteEquipment(String equipmentId) async {
    final response = await http.delete(_uri('/$equipmentId')).timeout(_timeout);
    _throwIfFailed(response);
  }

  void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Erreur API ${response.statusCode}: ${response.body}');
  }
}
