import 'package:flutter_test/flutter_test.dart';
import 'package:techno_store/features/new_device_maintenance/services/new_device_services.dart';

void main() {
  group('NewDeviceServices.chunkIds — Firestore whereIn 30-value limit', () {
    test('empty input produces no chunks', () {
      expect(NewDeviceServices.chunkIds([]), isEmpty);
    });

    test('fewer than the limit produces exactly one chunk', () {
      final ids = List.generate(5, (i) => 'id$i');
      final chunks = NewDeviceServices.chunkIds(ids);
      expect(chunks, hasLength(1));
      expect(chunks.single, ids);
    });

    test('exactly at the limit produces exactly one chunk', () {
      final ids = List.generate(30, (i) => 'id$i');
      final chunks = NewDeviceServices.chunkIds(ids, chunkSize: 30);
      expect(chunks, hasLength(1));
      expect(chunks.single, hasLength(30));
    });

    test('one over the limit produces two chunks, none exceeding the limit', () {
      final ids = List.generate(31, (i) => 'id$i');
      final chunks = NewDeviceServices.chunkIds(ids, chunkSize: 30);
      expect(chunks, hasLength(2));
      expect(chunks[0], hasLength(30));
      expect(chunks[1], hasLength(1));
      for (final chunk in chunks) {
        expect(chunk.length, lessThanOrEqualTo(30));
      }
    });

    test('a large distinct set is split into multiple chunks covering every id exactly once', () {
      final ids = List.generate(97, (i) => 'id$i');
      final chunks = NewDeviceServices.chunkIds(ids, chunkSize: 30);
      expect(chunks, hasLength(4)); // 30 + 30 + 30 + 7
      final flattened = chunks.expand((c) => c).toList();
      expect(flattened, ids); // every id present, in order, none dropped
    });
  });
}
