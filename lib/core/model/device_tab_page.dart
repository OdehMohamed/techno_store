import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';

/// One bounded page of devices for a single status tab/filter combination —
/// see docs/ai-workflow/SEARCH_FILTER_IMPLEMENTATION_PLAN.md.
///
/// [lastDocument] is the raw Firestore cursor (not just the mapped model),
/// needed to continue pagination via `startAfterDocument` — field values
/// alone aren't a valid Firestore pagination cursor. Null when [devices] is
/// empty (nothing to page from).
class DeviceTabPage {
  final List<MaintenanceDeviceModel> devices;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;

  const DeviceTabPage({
    required this.devices,
    this.lastDocument,
  });
}
