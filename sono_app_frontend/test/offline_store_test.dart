import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sono_app_frontend/models/equipment.dart';
import 'package:sono_app_frontend/models/staff_member.dart';
import 'package:sono_app_frontend/models/transport_vehicle.dart';
import 'package:sono_app_frontend/models/sono_event.dart';
import 'package:sono_app_frontend/services/equipment_api_service.dart';
import 'package:sono_app_frontend/services/event_api_service.dart';
import 'package:sono_app_frontend/services/seed_data.dart';
import 'package:sono_app_frontend/services/staff_api_service.dart';
import 'package:sono_app_frontend/services/transport_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ensureSeeded();
  });

  test('seed creates admin + stock + vehicles', () async {
    final staff = await StaffApiService().fetchStaff();
    expect(staff.length, 1);
    expect(staff.first.role, 'Admin');

    final stock = await EquipmentApiService().fetchEquipments();
    expect(stock.length, 9);

    final vehicles = await TransportApiService().fetchVehicles();
    expect(vehicles.length, 3);
  });

  test('login ok / wrong password fails', () async {
    final user = await StaffApiService().login('admin@sono.tn', 'admin123');
    expect(user.isAdmin, true);
    expect(() => StaffApiService().login('admin@sono.tn', 'bad'),
        throwsException);
    expect(() => StaffApiService().login('nobody@t.tn', 'x'),
        throwsException);
  });

  test('equipment CRUD', () async {
    final api = EquipmentApiService();
    final created = await api.createEquipment(
        const Equipment(id: 'x', nomMateriel: 'Test Mic', quantiteTotale: 4));
    expect(created.quantiteTotale, 4);
    expect(() => api.createEquipment(const Equipment(
        id: 'y', nomMateriel: 'test mic', quantiteTotale: 1)), throwsException);
    final updated = await api.updateEquipment(Equipment(
        id: created.id, nomMateriel: 'Test Mic', quantiteTotale: 7));
    expect(updated.quantiteTotale, 7);
    await api.deleteEquipment(created.id);
    expect((await api.fetchEquipments()).length, 9);
  });

  test('staff add + delete', () async {
    final api = StaffApiService();
    final m = await api.createMember(const StaffMember(
        id: 'x', nomPrenom: 'Sami', email: 'sami@t.tn', role: 'Aideur'));
    final login = await api.login('sami@t.tn', 'sono1234');
    expect(login.nomPrenom, 'Sami');
    await api.deleteMember(m.id);
    expect((await api.fetchStaff()).length, 1);
  });

  test('event + vehicle CRUD', () async {
    final events = EventApiService();
    final now = DateTime(2026, 9, 20);
    final created = await events.createEvent(SonoEvent(
        id: 'x',
        troupe: 'Oscar',
        type: 'Trio',
        description: 'd',
        lieu: 'Tunis',
        date: now,
        staffNames: const ['Sami'],
        vehicle: 'Camion 1',
        numChateau: 1,
        numBase: 0,
        numRetour: 0,
        numChanteur: 0,
        numPercussion: 0,
        batterie: false));
    expect((await events.fetchEvents()).length, 1);
    await events.deleteEvent(created.id);
    expect((await events.fetchEvents()).isEmpty, true);

    final vehicles = TransportApiService();
    final v = await vehicles.createVehicle(
        const TransportVehicle(id: 'x', matricule: 'AA 1', modele: 'Van'));
    final upd = await vehicles.updateVehicle(TransportVehicle(
        id: v.id, matricule: 'AA 1', modele: 'Van XL'));
    expect(upd.modele, 'Van XL');
    await vehicles.deleteVehicle(v.id);
  });
}
