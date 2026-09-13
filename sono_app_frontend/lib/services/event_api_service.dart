import '../models/sono_event.dart';
import 'local_store.dart';

/// نفس الواجهة كما قبل، لكن التخزين محلي 100% Offline.
class EventApiService {
  static const String baseUrl = '';

  final _store = LocalStore.instance;

  Future<List<SonoEvent>> fetchEvents() async {
    final items = await _store.readAll('app_events');
    final events =
        items.map((item) => SonoEvent.fromJson(item)).toList();
    events.sort((a, b) => a.date.compareTo(b.date));
    return events;
  }

  Future<SonoEvent> createEvent(SonoEvent event) async {
    final saved = await _store.insert('app_events', {
      'id': await _store.nextId('app_events'),
      ...event.toJson(),
    });
    return SonoEvent.fromJson(saved);
  }

  Future<SonoEvent> updateEvent(SonoEvent event) async {
    final updated =
        await _store.update('app_events', event.id, event.toJson());
    if (updated == null) {
      throw Exception('Evenement introuvable');
    }
    return SonoEvent.fromJson(updated);
  }

  Future<void> deleteEvent(String eventId) async {
    final ok = await _store.delete('app_events', eventId);
    if (!ok) throw Exception('Evenement introuvable');
  }
}
