import 'package:flutter_test/flutter_test.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';

MaintenanceDeviceModel _baseModel({
  String? deviceId,
  double? finalAmountCharged,
  String? technicalFinding,
  DateTime? technicalWorkConcludedAt,
}) {
  return MaintenanceDeviceModel(
    name: 'Test Customer',
    phoneNumber: '+970500000000',
    model: 'Test Model',
    colorHex: '111111',
    deviceId: deviceId,
    finalAmountCharged: finalAmountCharged,
    technicalFinding: technicalFinding,
    technicalWorkConcludedAt: technicalWorkConcludedAt,
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

  group(
      'MaintenanceDeviceModel finalAmountCharged/technicalFinding/technicalWorkConcludedAt serialization (ADR-007 §4/§5)',
      () {
    // Same failure class as the deviceId fix above, closed the same way
    // rather than left for a later PR to remember: no write path sets
    // these fields yet, so every caller that reconstructs a model to save
    // an unrelated edit (including new_device_maintenance.dart's
    // onSaveLogic(), which doesn't know about these fields at all)
    // defaults them to null. Writing them unconditionally would let a
    // merge write for an unrelated edit silently erase an
    // already-persisted value the moment a later PR starts setting one.

    test('null finalAmountCharged is omitted from toJson()', () {
      final json = _baseModel(finalAmountCharged: null).toJson();
      expect(json.containsKey('finalAmountCharged'), isFalse);
    });

    test('null technicalFinding is omitted from toJson()', () {
      final json = _baseModel(technicalFinding: null).toJson();
      expect(json.containsKey('technicalFinding'), isFalse);
    });

    test('null technicalWorkConcludedAt is omitted from toJson()', () {
      final json = _baseModel(technicalWorkConcludedAt: null).toJson();
      expect(json.containsKey('technicalWorkConcludedAt'), isFalse);
    });

    test('non-null values for all three still serialize correctly', () {
      final concludedAt = DateTime(2026, 2, 1, 10, 30);
      final json = _baseModel(
        finalAmountCharged: 125.5,
        technicalFinding: 'Repaired',
        technicalWorkConcludedAt: concludedAt,
      ).toJson();

      expect(json['finalAmountCharged'], 125.5);
      expect(json['technicalFinding'], 'Repaired');
      expect(json['technicalWorkConcludedAt'], concludedAt.toIso8601String());
    });

    test('legacy Firestore map (none of the three present) round-tripped through fromMap() -> toJson() manufactures none of them', () {
      final model = MaintenanceDeviceModel.fromMap(_legacyFirestoreMap(), 'doc-1');
      expect(model.finalAmountCharged, isNull);
      expect(model.technicalFinding, isNull);
      expect(model.technicalWorkConcludedAt, isNull);

      final roundTripped = model.toJson();
      expect(roundTripped.containsKey('finalAmountCharged'), isFalse);
      expect(roundTripped.containsKey('technicalFinding'), isFalse);
      expect(roundTripped.containsKey('technicalWorkConcludedAt'), isFalse);
    });
  });
}
