import 'package:flutter_test/flutter_test.dart';
import 'package:techno_store/core/utils/imei_normalization.dart';

void main() {
  group('ImeiNormalization.normalize', () {
    test('returns null for null input', () {
      expect(ImeiNormalization.normalize(null), isNull);
    });

    test('returns null for empty or whitespace-only input', () {
      expect(ImeiNormalization.normalize(''), isNull);
      expect(ImeiNormalization.normalize('   '), isNull);
    });

    test('strips common separators (spaces, hyphens, colons)', () {
      expect(
        ImeiNormalization.normalize('35-209900-176148-1'),
        '352099001761481',
      );
      expect(ImeiNormalization.normalize('35 2099 0017 6148 1'), '352099001761481');
      expect(ImeiNormalization.normalize('35:2099:0017:6148:1'), '352099001761481');
    });

    test('trims surrounding whitespace', () {
      expect(ImeiNormalization.normalize('  352099001761481  '), '352099001761481');
    });

    test('uppercases alphanumeric serials (no-op for all-digit IMEIs)', () {
      expect(ImeiNormalization.normalize('abc123def'), 'ABC123DEF');
      expect(ImeiNormalization.normalize('352099001761481'), '352099001761481');
    });

    test('two differently-formatted inputs normalize to the same value', () {
      final a = ImeiNormalization.normalize('35-209900-176148-1');
      final b = ImeiNormalization.normalize('352099 0017 61481');
      expect(a, equals(b));
    });

    test('does not enforce a fixed length or checksum', () {
      // A short non-phone serial number must not be rejected/mangled.
      expect(ImeiNormalization.normalize('sn-42'), 'SN42');
    });
  });
}
