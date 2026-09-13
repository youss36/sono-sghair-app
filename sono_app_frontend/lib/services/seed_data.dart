import 'local_store.dart';

/// بيانات البداية لأول تشغيل (Offline).
Future<void> ensureSeeded() async {
  final store = LocalStore.instance;
  if (await store.checkSeeded()) return;

  // حساب المدير الافتراضي — بدّل كلمة السر بعد الدخول (احذف الحساب وعاودو).
  const adminEmail = 'admin@sono.tn';
  const adminPassword = 'admin123';
  await store.insert('users', {
    'id': await store.nextId('users'),
    'nom_prenom': 'Admin',
    'email': adminEmail,
    'role': 'Admin',
    'photo_url': null,
    'salt': LocalStore.makeSalt(adminEmail),
    'password_hash':
        LocalStore.hashPassword(adminPassword, LocalStore.makeSalt(adminEmail)),
  });

  // الستوك الافتراضي.
  const stock = [
    'Chateau',
    'Sub',
    'Retour',
    'Side',
    'Sac cablage courant',
    'Sac cablage signal',
    'Sac perche',
    'Sac micro',
    'Regulateur',
  ];
  for (final name in stock) {
    await store.insert('equipments', {
      'id': await store.nextId('equipments'),
      'nom_materiel': name,
      'quantite_totale': 0,
    });
  }

  // الكراهب.
  const vehicles = [
    'Citroen Jumper',
    'Fiat Doblo',
    'Citroen Berlingo',
  ];
  for (final name in vehicles) {
    await store.insert('transports', {
      'id': await store.nextId('transports'),
      'matricule': name,
      'modele': name,
    });
  }

  await store.markSeeded();
}
