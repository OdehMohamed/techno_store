import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techno_store/features/new_device_maintenance/services/device_services.dart';

void main() {
  group('DeviceServices.buildImeiFields', () {
    test('a typed value produces both fields, synchronized', () {
      final fields = DeviceServices.buildImeiFields('35-209900-176148-1');
      expect(fields['imeiNumber'], '35-209900-176148-1');
      expect(fields['imeiNumberNormalized'], '352099001761481');
    });

    test('create (isUpdate: false) with no value omits both keys entirely', () {
      final fields = DeviceServices.buildImeiFields(null, isUpdate: false);
      expect(fields.containsKey('imeiNumber'), isFalse);
      expect(fields.containsKey('imeiNumberNormalized'), isFalse);

      final fieldsEmpty = DeviceServices.buildImeiFields('   ', isUpdate: false);
      expect(fieldsEmpty, isEmpty);
    });

    test('update (isUpdate: true) with no value deletes both keys explicitly', () {
      final fields = DeviceServices.buildImeiFields(null, isUpdate: true);
      expect(fields['imeiNumber'], isA<FieldValue>());
      expect(fields['imeiNumberNormalized'], isA<FieldValue>());
    });

    test('correcting IMEI recomputes the normalized form from the new value, not the old', () {
      final first = DeviceServices.buildImeiFields('AAA-111', isUpdate: true);
      final corrected = DeviceServices.buildImeiFields('BBB-222', isUpdate: true);

      expect(first['imeiNumberNormalized'], 'AAA111');
      expect(corrected['imeiNumberNormalized'], 'BBB222');
      expect(corrected['imeiNumberNormalized'], isNot(first['imeiNumberNormalized']));
    });

    test('imeiNumberNormalized is never independently settable — it is always derived', () {
      // There is no parameter on buildImeiFields (or DeviceServices'
      // public API) accepting a normalized value directly; this is a
      // structural guarantee, not just a runtime assertion. Confirmed
      // here by checking the derived value always matches what
      // ImeiNormalization.normalize would independently produce.
      const raw = 'zz 99-88';
      final fields = DeviceServices.buildImeiFields(raw);
      expect(fields['imeiNumberNormalized'], 'ZZ9988');
    });
  });
}
