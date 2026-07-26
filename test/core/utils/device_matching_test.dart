import 'package:flutter_test/flutter_test.dart';
import 'package:techno_store/core/model/device_match_candidate.dart';
import 'package:techno_store/core/model/device_model.dart';
import 'package:techno_store/core/utils/device_matching.dart';

DeviceModel _device(String id, {String model = 'Model'}) {
  return DeviceModel(id: id, model: model, colorHex: '111111');
}

void main() {
  group('buildMatchCandidates', () {
    test('empty inputs produce an empty list', () {
      final result = buildMatchCandidates(imeiMatches: [], knownDevices: []);
      expect(result, isEmpty);
    });

    test('a device appearing in only the IMEI list gets exactly the imeiMatch tag', () {
      final result = buildMatchCandidates(
        imeiMatches: [_device('d1')],
        knownDevices: [],
      );
      expect(result, hasLength(1));
      expect(result.single.reasons, {MatchReason.imeiMatch});
    });

    test('a device appearing in only the known-devices list gets exactly the knownForCustomer tag', () {
      final result = buildMatchCandidates(
        imeiMatches: [],
        knownDevices: [_device('d1')],
      );
      expect(result, hasLength(1));
      expect(result.single.reasons, {MatchReason.knownForCustomer});
    });

    test('a device appearing in both lists is deduplicated into one candidate with both reasons', () {
      final result = buildMatchCandidates(
        imeiMatches: [_device('d1')],
        knownDevices: [_device('d1')],
      );
      expect(result, hasLength(1));
      expect(result.single.reasons, {MatchReason.imeiMatch, MatchReason.knownForCustomer});
    });

    test('ordering: both-reasons before IMEI-only before known-only', () {
      final result = buildMatchCandidates(
        imeiMatches: [_device('imei-only'), _device('both')],
        knownDevices: [_device('known-only'), _device('both')],
      );
      expect(result.map((c) => c.device.id).toList(), [
        'both',
        'imei-only',
        'known-only',
      ]);
    });

    test('within the known-only bucket, order is stable and deterministic (model name, then id)', () {
      final result = buildMatchCandidates(
        imeiMatches: [],
        knownDevices: [
          _device('d2', model: 'Zebra'),
          _device('d1', model: 'Apple'),
        ],
      );
      expect(result.map((c) => c.device.id).toList(), ['d1', 'd2']);
    });

    test('devices with no id are skipped rather than crashing', () {
      final noId = DeviceModel(model: 'X', colorHex: '000000');
      final result = buildMatchCandidates(
        imeiMatches: [noId],
        knownDevices: [],
      );
      expect(result, isEmpty);
    });
  });
}
