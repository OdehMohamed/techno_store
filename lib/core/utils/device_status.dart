/// Maintenance device status vocabulary — bridge phase (ADR-007 Phase 2).
///
/// This app currently writes only the legacy literals below. The
/// ADR-007 literals are read-only here: no write call site in this
/// codebase may assign them until Phase 4 (the capability client).
/// Grouping lets tabs/colors/icons/actions treat either vocabulary's
/// literal for "the same operational meaning" identically, without
/// scattering ad-hoc string comparisons across features.
class DeviceStatus {
  // Legacy literals — the only values any write path in this app produces.
  static const String inMaintenance = 'In Maintenance';
  static const String fixed = 'Fixed';
  static const String delivered = 'Delivered';

  // ADR-007 vocabulary — read-only in this build.
  static const String inProgress = 'In Progress';
  static const String awaitingApproval = 'Awaiting Approval';
  static const String readyForHandback = 'Ready for Handback';

  /// Legacy 'In Maintenance' groups with new 'In Progress' and 'Awaiting
  /// Approval' — this bridge build has no separate tab/UI concept for an
  /// Estimate awaiting approval, so the closest honest approximation is to
  /// treat it as still "active work" alongside 'In Progress'.
  static const List<String> inMaintenanceGroup = [
    inMaintenance,
    inProgress,
    awaitingApproval,
  ];

  static const List<String> fixedGroup = [fixed, readyForHandback];

  // Same literal in both vocabularies today; kept as its own group for a
  // consistent shape at every call site.
  static const List<String> deliveredGroup = [delivered];

  /// Case-insensitive membership test against a status group, matching the
  /// case-insensitive comparisons this vocabulary has always used.
  static bool isInGroup(String? status, List<String> group) {
    if (status == null) return false;
    final normalized = status.toLowerCase();
    return group.any((value) => value.toLowerCase() == normalized);
  }
}
