/// Centralized role definitions and checks for [UserData.type].
///
/// Role checks must be written as allow-lists (e.g. `isStaff(type)`), never
/// as deny-lists (e.g. `type != customer`). A deny-list silently grants
/// access to any role that didn't exist yet when the check was written —
/// this is exactly how GuestAccount ended up with unintended staff-level
/// access to customer data (see docs/ai-workflow/ADR-003-guest-account-behavior.md
/// and docs/ai-workflow/SECURITY_AUDIT.md §5c).
///
/// GuestAccount (9) has no defined business role (per ADR-003) and
/// deliberately has no `isGuest`/allow-list entry here — it must not appear
/// in any allow-list unless a future decision explicitly grants it one.
class UserRole {
  UserRole._();

  static const int admin = 0;
  static const int customer = 1;
  static const int reception = 2;
  static const int maintenance = 3;
  static const int guest = 9;

  static bool isAdmin(int type) => type == admin;
  static bool isCustomer(int type) => type == customer;
  static bool isReception(int type) => type == reception;
  static bool isMaintenance(int type) => type == maintenance;

  /// Admin, Reception, or Maintenance. Customer and Guest are never staff.
  static bool isStaff(int type) =>
      isAdmin(type) || isReception(type) || isMaintenance(type);
}
