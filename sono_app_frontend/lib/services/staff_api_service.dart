import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/staff_member.dart';
import 'event_api_service.dart';

class StaffApiService {
  static const Duration _timeout = Duration(seconds: 10);

  static Uri _uri([String path = '']) =>
      Uri.parse('${EventApiService.baseUrl}/users$path');

  Future<List<StaffMember>> fetchStaff() async {
    final response = await http.get(_uri()).timeout(_timeout);
    _throwIfFailed(response);
    try {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => StaffMember.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw Exception('Données serveur invalides');
    }
  }

  Future<StaffMember> login(String email, String password) async {
    final response = await http
        .post(
          Uri.parse('${EventApiService.baseUrl}/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(_timeout);
    _throwIfFailed(response);
    return StaffMember.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<StaffMember> createMember(StaffMember member,
      {String password = 'sono1234'}) async {
    final response = await http
        .post(
          _uri(),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(member.toJson(password: password)),
        )
        .timeout(_timeout);
    _throwIfFailed(response);
    return StaffMember.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteMember(String memberId) async {
    final response = await http.delete(_uri('/$memberId')).timeout(_timeout);
    _throwIfFailed(response);
  }

  void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Erreur API ${response.statusCode}: ${response.body}');
  }
}
