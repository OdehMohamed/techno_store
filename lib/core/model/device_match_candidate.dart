import 'package:techno_store/core/model/device_model.dart';

/// ADR-007 Device Matching Policy — why a candidate was surfaced. A
/// candidate may carry both reasons at once (the common case: the same
/// physical device this customer has brought in before also matches by
/// IMEI), which is exactly why this is a Set, not a single value.
enum MatchReason { imeiMatch, knownForCustomer }

/// One candidate Device, with the reason(s) it was surfaced. Deliberately
/// carries only `DeviceModel` fields — brand/model/colorHex/imeiNumber and
/// the reason — never customer identity or Visit content, since Device
/// itself has no such field to leak (ADR-007 §1).
class DeviceMatchCandidate {
  final DeviceModel device;
  final Set<MatchReason> reasons;

  DeviceMatchCandidate({required this.device, required this.reasons});
}
