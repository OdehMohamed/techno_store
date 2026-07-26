import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:techno_store/core/model/device_model.dart';
import 'package:techno_store/core/utils/firestore_api_path.dart';
import 'package:techno_store/core/utils/imei_normalization.dart';

/// ADR-007 §1 — the persistent Device identity anchor. Narrowly scoped to
/// what the Device Matching Policy actually needs (create, read-by-id,
/// exact-IMEI lookup) — no generalized repository abstraction. The
/// customer-known-Devices query (ADR-007 Addendum) is deliberately not
/// here yet: it belongs with the intake-selection UI that calls it.
class DeviceServices {
  final FirebaseFirestore _firestoreInstance = FirebaseFirestore.instance;

  /// The single place imeiNumber/imeiNumberNormalized are computed
  /// together, so the two can never independently drift — no caller of
  /// this service ever supplies imeiNumberNormalized directly. [isUpdate]
  /// selects the correct "no value" representation: omit the keys
  /// entirely on a brand-new document (nothing to clear), or explicitly
  /// delete both on an update (correcting a device back to "unknown" must
  /// not leave a stale imeiNumberNormalized still pointing at the old,
  /// now-removed value).
  static Map<String, dynamic> buildImeiFields(
    String? imeiNumber, {
    bool isUpdate = false,
  }) {
    final trimmed = imeiNumber?.trim();
    final hasValue = trimmed != null && trimmed.isNotEmpty;

    if (hasValue) {
      return {
        'imeiNumber': trimmed,
        'imeiNumberNormalized': ImeiNormalization.normalize(trimmed),
      };
    }
    if (isUpdate) {
      return {
        'imeiNumber': FieldValue.delete(),
        'imeiNumberNormalized': FieldValue.delete(),
      };
    }
    return {};
  }

  Future<String> createDevice({
    String? brand,
    required String model,
    required String colorHex,
    String? imeiNumber,
  }) async {
    final docRef = _firestoreInstance.collection(FirestoreApiPath.devices()).doc();
    await docRef.set({
      if (brand != null && brand.trim().isNotEmpty) 'brand': brand.trim(),
      'model': model,
      'colorHex': colorHex,
      ...buildImeiFields(imeiNumber),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint('✅ Device created: ${docRef.id}');
    return docRef.id;
  }

  Future<DeviceModel?> getDeviceById(String deviceId) async {
    final snapshot =
        await _firestoreInstance.collection(FirestoreApiPath.devices()).doc(deviceId).get();
    if (!snapshot.exists) return null;
    return DeviceModel.fromMap(snapshot.data()!, snapshot.id);
  }

  /// The exact-match pathway (ADR-007 Addendum): normalizes the typed
  /// search input the same way stored values are normalized, then queries
  /// only the canonical field — never the raw imeiNumber. Empty/absent
  /// input never issues a query: an unrecorded IMEI is absent evidence,
  /// not a matchable value shared by every other device lacking one.
  Future<List<DeviceModel>> findByNormalizedImei(String typedValue) async {
    final normalized = ImeiNormalization.normalize(typedValue);
    if (normalized == null) return [];

    final snapshot = await _firestoreInstance
        .collection(FirestoreApiPath.devices())
        .where('imeiNumberNormalized', isEqualTo: normalized)
        .get();
    return snapshot.docs
        .map((doc) => DeviceModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
