import 'package:cloud_functions/cloud_functions.dart';
import 'package:techno_store/core/model/user_data.dart';
import 'package:techno_store/core/services/firestore_services.dart';
import 'package:techno_store/core/utils/firestore_api_path.dart';
import 'package:techno_store/core/utils/user_role.dart';
import 'package:techno_store/features/staff_management/model/staff_member.dart';

class StaffManagementServices {
  final _firestoreServices = FirestoreServices.instance;

  /// All staff accounts (Admin/Reception/Maintenance), any status — unlike
  /// [FirestoreServices.getActiveStaffByRoles] (ADR-006), which is
  /// deliberately active-only for attribution dropdowns. A one-time fetch,
  /// not a stream: staff rosters at this scale change rarely enough that a
  /// live listener isn't warranted (same reasoning as ADR-006's dropdown
  /// fetch). Pagination deliberately deferred — see ADR-004.
  Future<List<StaffMember>> fetchStaff() async {
    final accounts = await _firestoreServices.getCollection<UserData>(
      path: FirestoreApiPath.users(),
      builder: (data, documentID) => UserData.fromMap(data, documentID),
      queryBuilder: (q) => q.where(
        'type',
        whereIn: [UserRole.admin, UserRole.reception, UserRole.maintenance],
      ),
    );

    final members = <StaffMember>[];
    for (final account in accounts) {
      final statusData = await _firestoreServices.getDocumentOrNull(
        path: FirestoreApiPath.staffStatus(account.uid),
      );
      members.add(StaffMember(
        userData: account,
        status: statusData?['status'] as String? ?? 'inactive',
      ));
    }
    members.sort(
      (a, b) => (a.userData.name ?? '').compareTo(b.userData.name ?? ''),
    );
    return members;
  }

  /// Creates a staff account via the createStaffAccount Cloud Function — the
  /// only trusted path for this, per ADR-004. [requestId] must be stable
  /// across retries of the same creation attempt (generated once by the
  /// caller, not regenerated per call) — it's what anchors this function's
  /// idempotency/resume contract, not email/role content.
  Future<String> createStaffAccount({
    required String requestId,
    required String name,
    required String email,
    required String password,
    required int type,
  }) async {
    final result =
        await FirebaseFunctions.instance.httpsCallable('createStaffAccount').call({
      'requestId': requestId,
      'name': name,
      'email': email,
      'password': password,
      'type': type,
    });
    return (result.data as Map)['uid'] as String;
  }

  /// Activates/deactivates a staff account via the already-shipped
  /// setStaffStatus Cloud Function (ADR-004's Staff Status Architecture
  /// Pass) — unmodified, reused as-is.
  Future<void> setStaffStatus({
    required String uid,
    required String status,
  }) async {
    await FirebaseFunctions.instance.httpsCallable('setStaffStatus').call({
      'uid': uid,
      'status': status,
    });
  }
}
