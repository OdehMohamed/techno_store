import 'package:techno_store/core/model/device_match_candidate.dart';
import 'package:techno_store/core/model/device_model.dart';

/// ADR-007 Device Matching Policy — merges the two candidate-producing
/// pathways (exact-IMEI match, customer-known Devices) into one ordered,
/// deduplicated list. Pure and Firestore-free by design, so the merge/
/// ordering logic is directly unit-testable.
///
/// Deduplicates by `DeviceModel.id`: the same physical device commonly
/// satisfies both pathways at once (a customer's own known device that
/// also matches by IMEI), and must surface as one candidate carrying both
/// reason tags, never two separate cards.
///
/// Ordering — three buckets, exactly as ratified: both reasons present,
/// then IMEI-only, then known-for-customer-only. Brand/model/color are
/// deliberately not used to rank within the last bucket here — the
/// ratified policy says they *may* be used for that, not that they must;
/// a stable, deterministic secondary order (model name, then id) is used
/// instead, kept simple rather than building an unspecified similarity
/// heuristic this pass doesn't need.
List<DeviceMatchCandidate> buildMatchCandidates({
  required List<DeviceModel> imeiMatches,
  required List<DeviceModel> knownDevices,
}) {
  final byId = <String, DeviceMatchCandidate>{};

  void addAll(List<DeviceModel> devices, MatchReason reason) {
    for (final device in devices) {
      final id = device.id;
      if (id == null) continue;
      final existing = byId[id];
      if (existing != null) {
        existing.reasons.add(reason);
      } else {
        byId[id] = DeviceMatchCandidate(device: device, reasons: {reason});
      }
    }
  }

  addAll(imeiMatches, MatchReason.imeiMatch);
  addAll(knownDevices, MatchReason.knownForCustomer);

  final candidates = byId.values.toList();
  candidates.sort((a, b) {
    final bucketCompare = _bucket(a.reasons).compareTo(_bucket(b.reasons));
    if (bucketCompare != 0) return bucketCompare;
    final modelCompare = a.device.model.compareTo(b.device.model);
    if (modelCompare != 0) return modelCompare;
    return (a.device.id ?? '').compareTo(b.device.id ?? '');
  });
  return candidates;
}

int _bucket(Set<MatchReason> reasons) {
  final hasImei = reasons.contains(MatchReason.imeiMatch);
  final hasKnown = reasons.contains(MatchReason.knownForCustomer);
  if (hasImei && hasKnown) return 0;
  if (hasImei) return 1;
  return 2;
}
