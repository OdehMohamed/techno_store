import 'package:techno_store/core/model/user_data.dart';

/// A staff account (Admin/Reception/Maintenance) paired with its
/// `users/{uid}/meta/staffStatus` value, for the Admin-only Staff
/// Management surface. See docs/ai-workflow/ADR-004-admin-user-management-design.md.
///
/// [status] defaults to 'inactive' when the staffStatus document is
/// missing — fail-closed, matching AuthCubit's `_fetchStaffIsActive`
/// treatment of the same case, not a display-only convenience.
class StaffMember {
  final UserData userData;
  final String status;

  const StaffMember({required this.userData, required this.status});

  bool get isActive => status == 'active';
}
