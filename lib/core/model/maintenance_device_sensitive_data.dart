/// Sensitive maintenance device fields, stored separately from
/// [MaintenanceDeviceModel] per docs/ai-workflow/ADR-001-sensitive-data-separation.md.
///
/// These fields must never be visible to the owning customer, even for
/// their own device — see docs/ai-workflow/SECURITY_AUDIT.md §6 and the
/// product-owner decision recorded in docs/ai-workflow/DECISIONS_LOG.md.
class MaintenanceDeviceSensitiveData {
  final String? pin;
  final List<int>? patternLock;
  final String? notesHidden;

  const MaintenanceDeviceSensitiveData({
    this.pin,
    this.patternLock,
    this.notesHidden,
  });

  bool get hasAnyValue =>
      (pin != null && pin!.isNotEmpty) ||
      (patternLock != null && patternLock!.isNotEmpty) ||
      (notesHidden != null && notesHidden!.isNotEmpty);

  Map<String, dynamic> toMap() {
    return {
      'pin': pin,
      'patternLock': patternLock,
      'notesHidden': notesHidden,
    };
  }

  /// Reads only the three known keys from [map] — safe to call with either
  /// the new subdocument's map (which has only these keys) or a legacy
  /// parent maintenanceDevices document's raw map (which has many more
  /// keys; the extra keys are simply ignored).
  factory MaintenanceDeviceSensitiveData.fromMap(Map<String, dynamic> map) {
    return MaintenanceDeviceSensitiveData(
      pin: map['pin'] as String?,
      patternLock:
          (map['patternLock'] as List<dynamic>?)?.map((e) => e as int).toList(),
      notesHidden: map['notesHidden'] as String?,
    );
  }
}
