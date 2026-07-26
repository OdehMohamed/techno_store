import 'package:flutter_test/flutter_test.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';

MaintenanceDeviceModel _baseModel({String? deviceId}) {
  return MaintenanceDeviceModel(
    name: 'Test Customer',
    phoneNumber: '+970500000000',
    model: 'Test Model',
    colorHex: '111111',
    deviceId: deviceId,
    problems: const [],
    accessories: const [],
    deviceStatusReceived: const [],
    receivedByEmployee: 'Test Employee',
    receivedAt: DateTime(2026, 1, 1),
  );
}

Map<String, dynamic> _legacyFirestoreMap() {
  // No deviceId key at all — the real shape of a document written before
  // ADR-007's Device selection ever existed. Must never come back from
  // fromMap()/toJson() with a manufactured deviceId: null.
  return {
    'name': 'Test Customer',
    'phoneNumber': '+970500000000',
    'model': 'Test Model',
    'colorHex': '111111',
    'problems': <String>[],
    'accessories': <String>[],
    'deviceStatusReceived': <String>[],
    'receivedByEmployee': 'Test Employee',
    'receivedAt': DateTime(2026, 1, 1).toIso8601String(),
  };
}

void main() {
  group('MaintenanceDeviceModel deviceId serialization (ADR-007 §3)', () {
    // Regression coverage for the exact compatibility bug found while
    // implementing the deviceId-immutability rules change: toJson() used
    // to write every optional field unconditionally, including an
    // explicit `deviceId: null` for a legacy Visit. Combined with
    // NewDeviceServices.updateDevice's merge:true write, that would have
    // tripped firestore.rules' new absence check on every ordinary edit
    // of every legacy Visit in production.

    test('legacy model (deviceId == null) — toJson() contains no deviceId key at all', () {
      final json = _baseModel(deviceId: null).toJson();
      expect(json.containsKey('deviceId'), isFalse);
    });

    test('new-world model (real deviceId) — toJson() contains that exact value', () {
      final json = _baseModel(deviceId: 'device-abc').toJson();
      expect(json.containsKey('deviceId'), isTrue);
      expect(json['deviceId'], 'device-abc');
    });

    test('legacy Firestore map (no deviceId) round-tripped through fromMap() -> toJson() never manufactures deviceId: null', () {
      final model = MaintenanceDeviceModel.fromMap(_legacyFirestoreMap(), 'doc-1');
      expect(model.deviceId, isNull);

      final roundTripped = model.toJson();
      expect(roundTripped.containsKey('deviceId'), isFalse);
    });
  });
}
