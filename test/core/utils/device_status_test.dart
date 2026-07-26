import 'package:flutter_test/flutter_test.dart';
import 'package:techno_store/core/utils/device_status.dart';

void main() {
  group('DeviceStatus.isInGroup', () {
    test('matches the legacy literal a group is named after', () {
      expect(
        DeviceStatus.isInGroup(
          DeviceStatus.inMaintenance,
          DeviceStatus.inMaintenanceGroup,
        ),
        isTrue,
      );
      expect(
        DeviceStatus.isInGroup(DeviceStatus.fixed, DeviceStatus.fixedGroup),
        isTrue,
      );
      expect(
        DeviceStatus.isInGroup(
          DeviceStatus.delivered,
          DeviceStatus.deliveredGroup,
        ),
        isTrue,
      );
    });

    test('matches the ADR-007 literals bridged into each group', () {
      expect(
        DeviceStatus.isInGroup(
          DeviceStatus.inProgress,
          DeviceStatus.inMaintenanceGroup,
        ),
        isTrue,
      );
      expect(
        DeviceStatus.isInGroup(
          DeviceStatus.awaitingApproval,
          DeviceStatus.inMaintenanceGroup,
        ),
        isTrue,
      );
      expect(
        DeviceStatus.isInGroup(
          DeviceStatus.readyForHandback,
          DeviceStatus.fixedGroup,
        ),
        isTrue,
      );
    });

    test('is case-insensitive, matching every pre-existing comparison site',
        () {
      expect(
        DeviceStatus.isInGroup('in maintenance', DeviceStatus.inMaintenanceGroup),
        isTrue,
      );
      expect(
        DeviceStatus.isInGroup('FIXED', DeviceStatus.fixedGroup),
        isTrue,
      );
    });

    test('does not cross-match between groups', () {
      expect(
        DeviceStatus.isInGroup(DeviceStatus.fixed, DeviceStatus.inMaintenanceGroup),
        isFalse,
      );
      expect(
        DeviceStatus.isInGroup(
          DeviceStatus.readyForHandback,
          DeviceStatus.inMaintenanceGroup,
        ),
        isFalse,
      );
      expect(
        DeviceStatus.isInGroup(
          DeviceStatus.awaitingApproval,
          DeviceStatus.fixedGroup,
        ),
        isFalse,
      );
    });

    test('rejects unrecognized or null status values', () {
      expect(
        DeviceStatus.isInGroup('Some Other Status', DeviceStatus.inMaintenanceGroup),
        isFalse,
      );
      expect(
        DeviceStatus.isInGroup(null, DeviceStatus.deliveredGroup),
        isFalse,
      );
    });

    test('groups partition the vocabulary — no literal appears twice', () {
      final allGroups = [
        DeviceStatus.inMaintenanceGroup,
        DeviceStatus.fixedGroup,
        DeviceStatus.deliveredGroup,
      ];
      final seen = <String>{};
      for (final group in allGroups) {
        for (final literal in group) {
          expect(
            seen.add(literal.toLowerCase()),
            isTrue,
            reason: '$literal appears in more than one group',
          );
        }
      }
    });
  });
}
