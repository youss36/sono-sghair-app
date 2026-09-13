import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/sono_event.dart';

class EventApiService {
  // Windows/Desktop: 127.0.0.1 يعمل. Android Emulator: استعمل 10.0.2.2. هاتف حقيقي: IP الحاسوب في الشبكة.
  // مثال: flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const Duration _timeout = Duration(seconds: 10);

  static Uri _uri([String path = '']) => Uri.parse('$baseUrl/app-events$path');

  Future<List<SonoEvent>> fetchEvents() async {
    final response = await http.get(_uri()).timeout(_timeout);
    _throwIfFailed(response);
    try {
      final data = jsonDecode(response.body) as List<dynamic>;
      final events = data
          .map((item) => SonoEvent.fromJson(item as Map<String, dynamic>))
          .toList();
      events.sort((a, b) => a.date.compareTo(b.date));
      return events;
    } catch (_) {
      throw Exception('Données serveur invalides');
    }
  }

  Future<SonoEvent> createEvent(SonoEvent event) async {
    final response = await http
        .post(
          _uri(),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(event.toJson()),
        )
        .timeout(_timeout);
    _throwIfFailed(response);
    return SonoEvent.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<SonoEvent> updateEvent(SonoEvent event) async {
    final response = await http
        .put(
          _uri('/${event.id}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(event.toJson()),
        )
        .timeout(_timeout);
    _throwIfFailed(response);
    return SonoEvent.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteEvent(String eventId) async {
    final response = await http.delete(_uri('/$eventId')).timeout(_timeout);
    _throwIfFailed(response);
  }

  void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Erreur API ${response.statusCode}: ${response.body}');
  }
}
