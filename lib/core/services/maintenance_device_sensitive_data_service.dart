import 'package:techno_store/core/model/maintenance_device_sensitive_data.dart';
import 'package:techno_store/core/services/firestore_services.dart';
import 'package:techno_store/core/utils/firestore_api_path.dart';

/// Single shared place that knows how to read a device's sensitive fields
/// (pin, patternLock, notesHidden) during the migration window described in
/// docs/ai-workflow/PHASE1_IMPLEMENTATION_PLAN.md.
///
/// Until the Phase 1C migration runs, some devices have these fields on the
/// new `private/sensitive` subdocument (created by new code shipped in this
/// phase) and others still have them inline on the parent document (created
/// before this phase). This service checks the new location first and
/// falls back to the legacy location, so both create/edit forms and the
/// device details screen see correct data regardless of migration state —
/// this is the "preserve backward compatibility until migration is
/// complete" requirement from the approved Phase 1B implementation request.
///
/// Both [NewDeviceServices] (create/edit prefill) and
/// [MaintenanceListServices] (staff-facing display) delegate to this
/// service rather than duplicating the fallback logic.
class MaintenanceDeviceSensitiveDataService {
  MaintenanceDeviceSensitiveDataService._();

  static final instance = MaintenanceDeviceSensitiveDataService._();

  final FirestoreServices _firestoreServices = FirestoreServices.instance;

  Future<MaintenanceDeviceSensitiveData?> fetch(String deviceId) async {
    final subDocData = await _firestoreServices.getDocumentOrNull(
      path: FirestoreApiPath.maintenanceDeviceSensitiveData(deviceId),
    );
    if (subDocData != null) {
      final data = MaintenanceDeviceSensitiveData.fromMap(subDocData);
      if (data.hasAnyValue) return data;
    }

    // Not migrated yet (or never had sensitive data) — fall back to the
    // legacy inline fields on the parent document, if any.
    final parentData = await _firestoreServices.getDocumentOrNull(
      path: FirestoreApiPath.maintenanceDevice(deviceId),
    );
    if (parentData == null) return null;

    final legacy = MaintenanceDeviceSensitiveData.fromMap(parentData);
    return legacy.hasAnyValue ? legacy : null;
  }
}
