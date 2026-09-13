import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مخزن محلي 100% Offline (SharedPreferences + JSON).
/// يشتغل على الهاتف و Chrome و Windows بدون سيرفر.
class LocalStore {
  LocalStore._();

  static final LocalStore instance = LocalStore._();

  static const _seedKey = 'seeded_v1';

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> readAll(String collection) async {
    final prefs = await _prefs;
    final raw = prefs.getString('db_$collection');
    if (raw == null || raw.isEmpty) return [];
    final data = jsonDecode(raw) as List<dynamic>;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _writeAll(
      SharedPreferences prefs, String collection, List<Map<String, dynamic>> items) async {
    await prefs.setString('db_$collection', jsonEncode(items));
  }

  /// id جديد متزايد لكل مجموعة.
  Future<String> nextId(String collection) async {
    final prefs = await _prefs;
    final key = 'seq_$collection';
    final next = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, next);
    return next.toString();
  }

  Future<Map<String, dynamic>> insert(
      String collection, Map<String, dynamic> item) async {
    final prefs = await _prefs;
    final items = await readAll(collection);
    final withId = Map<String, dynamic>.from(item)
      ..putIfAbsent('id', () => '');
    if ((withId['id'] as String).isEmpty) {
      withId['id'] = await nextId(collection);
    }
    items.add(withId);
    await _writeAll(prefs, collection, items);
    return withId;
  }

  Future<Map<String, dynamic>?> update(
      String collection, String id, Map<String, dynamic> item) async {
    final prefs = await _prefs;
    final items = await readAll(collection);
    final index = items.indexWhere((e) => e['id'].toString() == id);
    if (index == -1) return null;
    final updated = Map<String, dynamic>.from(item)..['id'] = items[index]['id'];
    items[index] = updated;
    await _writeAll(prefs, collection, items);
    return updated;
  }

  Future<bool> delete(String collection, String id) async {
    final prefs = await _prefs;
    final items = await readAll(collection);
    final before = items.length;
    items.removeWhere((e) => e['id'].toString() == id);
    if (items.length == before) return false;
    await _writeAll(prefs, collection, items);
    return true;
  }

  bool get isSeeded =>
      _seededCache ?? false;
  bool? _seededCache;

  Future<bool> checkSeeded() async {
    final prefs = await _prefs;
    _seededCache = prefs.getBool(_seedKey) ?? false;
    return _seededCache!;
  }

  Future<void> markSeeded() async {
    final prefs = await _prefs;
    await prefs.setBool(_seedKey, true);
    _seededCache = true;
  }

  /// تجزئة كلمة السر (SHA-256 + ملح) — كافية للاستعمال المحلي.
  static String hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt::$password')).toString();
  }

  static String makeSalt(String email) {
    return sha256.convert(utf8.encode('sono-sghaier-${email.trim().toLowerCase()}')).toString();
  }
}
