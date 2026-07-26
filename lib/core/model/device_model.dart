import 'package:cloud_firestore/cloud_firestore.dart';

/// ADR-007 §1 — the persistent Device identity anchor. `imeiNumberNormalized`
/// is derived, matching data only: never independently authored by a UI
/// caller — always computed from `imeiNumber` by DeviceServices' write path
/// (see core/utils/imei_normalization.dart). This model's constructor still
/// accepts it, since reading a document back from Firestore needs to
/// reconstruct exactly what's stored — the invariant is enforced at the
/// service write path, not by hiding the field from the model entirely.
class DeviceModel {
  final String? id;
  final String? brand;
  final String model;
  final String colorHex;
  final String? imeiNumber;
  final String? imeiNumberNormalized;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DeviceModel({
    this.id,
    this.brand,
    required this.model,
    required this.colorHex,
    this.imeiNumber,
    this.imeiNumberNormalized,
    this.createdAt,
    this.updatedAt,
  });

  factory DeviceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return DeviceModel(
      id: documentId,
      brand: map['brand'] as String?,
      model: map['model'] as String,
      colorHex: map['colorHex'] as String,
      imeiNumber: map['imeiNumber'] as String?,
      imeiNumberNormalized: map['imeiNumberNormalized'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
