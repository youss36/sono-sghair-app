import '../models/staff_member.dart';
import 'local_store.dart';

class StaffApiService {
  final _store = LocalStore.instance;

  Future<StaffMember> login(String email, String password) async {
    final items = await _store.readAll('users');
    final emailNorm = email.trim().toLowerCase();
    Map<String, dynamic>? found;
    for (final u in items) {
      if ((u['email'] as String).toLowerCase() == emailNorm) {
        found = u;
        break;
      }
    }
    if (found == null) {
      throw Exception('Email ou mot de passe incorrect.');
    }
    final salt = (found['salt'] ?? LocalStore.makeSalt(emailNorm)) as String;
    final hash = LocalStore.hashPassword(password, salt);
    if (hash != found['password_hash']) {
      throw Exception('Email ou mot de passe incorrect.');
    }
    return StaffMember.fromJson(found);
  }

  Future<List<StaffMember>> fetchStaff() async {
    final items = await _store.readAll('users');
    final list = items.map((item) => StaffMember.fromJson(item)).toList();
    list.sort((a, b) => a.nomPrenom.compareTo(b.nomPrenom));
    return list;
  }

  Future<StaffMember> createMember(StaffMember member,
      {String password = 'sono1234'}) async {
    final items = await _store.readAll('users');
    final emailNorm = member.email.trim().toLowerCase();
    final exists =
        items.any((u) => (u['email'] as String).toLowerCase() == emailNorm);
    if (exists) throw Exception('Cet email est déjà utilisé');
    final salt = LocalStore.makeSalt(emailNorm);
    final saved = await _store.insert('users', {
      'id': await _store.nextId('users'),
      'nom_prenom': member.nomPrenom,
      'email': member.email.trim(),
      'role': member.role,
      'photo_url': member.photoUrl,
      'salt': salt,
      'password_hash': LocalStore.hashPassword(password, salt),
    });
    return StaffMember.fromJson(saved);
  }

  Future<void> deleteMember(String memberId) async {
    final ok = await _store.delete('users', memberId);
    if (!ok) throw Exception('Membre introuvable');
  }
}
