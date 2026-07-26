import 'package:cloud_firestore/cloud_firestore.dart';

/// ADR-007 §8 — one immutable revision in a Visit's Estimate sequence.
/// `createdAt`/`decidedAt`/`resolvedAt` are server-authoritative Timestamps
/// (rules-enforced == request.time), not client-supplied.
class EstimateModel {
  final String? id;
  final String proposedScope;
  final double proposedAmount;
  final String createdByUid;
  final DateTime? createdAt;
  final String outcome; // 'pending' | 'approved' | 'declined'
  final String? decidedByUid;
  final DateTime? decidedAt;
  final String? declineReason;
  final String? resolutionOutcome; // 'continue' | 'stop', declined-and-qualifying only
  final String? resolvedByUid;
  final DateTime? resolvedAt;

  EstimateModel({
    this.id,
    required this.proposedScope,
    required this.proposedAmount,
    required this.createdByUid,
    this.createdAt,
    this.outcome = 'pending',
    this.decidedByUid,
    this.decidedAt,
    this.declineReason,
    this.resolutionOutcome,
    this.resolvedByUid,
    this.resolvedAt,
  });

  factory EstimateModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EstimateModel(
      id: documentId,
      proposedScope: map['proposedScope'] as String,
      // Firestore may return an int-typed number (e.g. a whole-dollar
      // amount stored as 50, not 50.0) — (num).toDouble() tolerates both,
      // matching MaintenanceDeviceModel's existing `price` parsing.
      proposedAmount: (map['proposedAmount'] as num).toDouble(),
      createdByUid: map['createdByUid'] as String,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      outcome: map['outcome'] as String? ?? 'pending',
      decidedByUid: map['decidedByUid'] as String?,
      decidedAt: (map['decidedAt'] as Timestamp?)?.toDate(),
      declineReason: map['declineReason'] as String?,
      resolutionOutcome: map['resolutionOutcome'] as String?,
      resolvedByUid: map['resolvedByUid'] as String?,
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }
}
