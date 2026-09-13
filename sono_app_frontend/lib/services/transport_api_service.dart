import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/transport_vehicle.dart';
import 'event_api_service.dart';

class TransportApiService {
  static const Duration _timeout = Duration(seconds: 10);

  static Uri _uri([String path = '']) =>
      Uri.parse('${EventApiService.baseUrl}/transports$path');

  Future<List<TransportVehicle>> fetchVehicles() async {
    final response = await http.get(_uri()).timeout(_timeout);
    _throwIfFailed(response);
    try {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) =>
              TransportVehicle.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw Exception('Données serveur invalides');
    }
  }

  Future<TransportVehicle> createVehicle(TransportVehicle vehicle) async {
    final response = await http
        .post(
          _uri(),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(vehicle.toJson()),
        )
        .timeout(_timeout);
    _throwIfFailed(response);
    return TransportVehicle.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<TransportVehicle> updateVehicle(TransportVehicle vehicle) async {
    final response = await http
        .put(
          _uri('/${vehicle.id}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(vehicle.toJson()),
        )
        .timeout(_timeout);
    _throwIfFailed(response);
    return TransportVehicle.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteVehicle(String vehicleId) async {
    final response = await http.delete(_uri('/$vehicleId')).timeout(_timeout);
    _throwIfFailed(response);
  }

  void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Erreur API ${response.statusCode}: ${response.body}');
  }
}
