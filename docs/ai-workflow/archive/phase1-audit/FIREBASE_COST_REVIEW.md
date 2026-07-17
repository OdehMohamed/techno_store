# FIREBASE_COST_REVIEW.md

> - **Archived:** 2026-07-17
> - **Historical reference only.**
> - Reflects the project's state before the Phase 1 remediation work was completed (structural risk analysis, 2026-07-03). Its headline risk — the unbounded `streamMaintenanceDevices` listener for staff/guest roles — was resolved by the v1.1.0 search/filter feature (`BACKLOG.md` item 1g, closed 2026-07-09).
> - **Must not be treated as the current source of truth.** For current information, see `docs/ai-workflow/BACKLOG.md` (still-open items: Storage cleanup on delete, no client-side image compression) and `docs/ai-workflow/DECISIONS_LOG.md` (the full decision record).

Companion to `SECURITY_AUDIT.md`. Covers Firestore read/write/listener cost patterns, Storage cost patterns, and index requirements, based strictly on the query and listener code actually present in this codebase. No load-testing or production usage data was available for this review — all figures below are **structural risk analysis** (what the code *would* cost as usage grows), not measured cost. Where a number would require production metrics (document counts, concurrent session counts, actual read volume), it's marked **Unknown**.

---

## 1. Firestore read/write cost patterns

| Access | Code | Cost shape |
|---|---|---|
| `streamMaintenanceDevices(null)` | `MaintenanceListServices.streamMaintenanceDevices`, called via `MaintenanceListCubit.listenToMaintenanceDevices` from `main_screen.dart:59-61` for every role **except Customer** (Admin, Reception, Maintenance, Guest) | Live listener on `.collection('maintenanceDevices').orderBy('receivedAt', descending: true).snapshots()` with **no `.limit()`**. Initial listen bills one read per document in the entire collection. **Every subsequent write to any document in the collection re-delivers the full updated document to every open listener of this kind**, billed as a read per listener per change. |
| `streamMaintenanceDevices(uid)` | Same method, Customer path only, filtered `.where('userId', isEqualTo: uid)` | Scoped to one customer's own devices — bounded by how many devices a single customer has (small, in practice). Low cost per session. |
| `fetchMaintenanceDevices` / `fetchMaintenanceDevicesPaginated` | Dormant per `PROJECT_CONTEXT.md`/`SECURITY_AUDIT.md` (defined, effectively unreachable today) | If ever wired up: `fetchMaintenanceDevices` does a one-shot `.get()` over the **entire** collection with no limit — one read per document, every call (e.g., every pull-to-refresh). `fetchMaintenanceDevicesPaginated` is the only query in the codebase that actually paginates (`.limit(limit)` + `startAfterDocument`), but it's unused. |
| `NewDeviceServices.getUserIdByPhoneNumber` | `.collection('users').where('phoneNumber', isEqualTo: phoneNumber).limit(1)` | Bounded (`limit(1)`), called once per new device creation/update — low, predictable cost. |
| `CreateUserAccountServices.findUserDevices` | `.collection('maintenanceDevices').where('phoneNumber', isEqualTo: phoneNumber)` | No `.limit()`, but naturally bounded by how many devices share one phone number (small in practice) — low cost. Called once per signup completion. |
| `AuthCubit._listenToActivation` | Live listener on a single document (`users/{uid}/meta/isActivated`) | One read per session start, then only re-bills on actual writes to that one document — negligible per-user cost, but it's a **permanent open listener for the lifetime of every session** (not explicitly cancelled anywhere except implicitly on cubit disposal) — worth noting as one more long-lived connection per active user, though not a meaningful billing concern by itself. |
| `HomeServices.getUserData` | Reads `users/{uid}` once, but **short-circuits to `SharedPreferences` cache** if the cached `uid` matches the current session | Effectively free after first login per app install — this is the one place in the codebase that actively reduces Firestore read cost via local caching. |

### Headline risk

**`streamMaintenanceDevices(null)` is the dominant cost driver in this codebase.** Four of five roles (everyone except Customer) use it, it has no limit, and every write to any device fans out to every connected listener of this kind. Concretely: if there are *N* staff/guest sessions open concurrently and someone updates one device's status, Firestore bills approximately *N* reads for that single write (one delivered update per open listener), on top of the *N × (collection size)* reads already billed when each of those *N* sessions first connected. This scales multiplicatively with both collection growth (more devices ever received) and concurrent staff/guest usage — exactly the kind of cost curve worth flagging before it's load-tested in production.

This is compounded by the Guest-role finding in `SECURITY_AUDIT.md` §5c: if Guest accounts are more numerous or longer-lived than intended (e.g., left open in a browser tab), they contribute to this same unfiltered listener fan-out with no functional benefit, since guests presumably shouldn't need this data at all.

## 2. Storage cost patterns

**Facts:**
- `FirebaseStorageServices.uploadFile` uploads the raw file as picked (`ref.putFile(file)` / `ref.putData(bytes)` on web) — **no client-side image compression or resizing** before upload. Photos taken directly from a phone camera (multi-megapixel) would be stored and later re-downloaded at full resolution every time they're displayed (e.g., via `CachedNetworkImage` in `device_details_sheet.dart`/drawer avatar), which is both a Storage cost (storage volume) and a bandwidth cost (egress on every fresh view, though `cached_network_image` does mitigate repeat views on the same device via local caching).
- **`MaintenanceListServices.deleteDevice` deletes the Firestore document but never deletes the associated Storage files** (`imagesBeforeReceiving`, `imagesAfterDelivery`). Confirmed: no call to `FirebaseStorageServices.deleteFileByPath`/`deleteImageByUrl` exists in the delete path. Every deleted device leaves its photos permanently in Storage, accumulating storage cost indefinitely with no cleanup mechanism.
- No lifecycle rules or scheduled cleanup job found anywhere in this repository (no Cloud Functions directory exists at all).

**Risk:** storage cost grows monotonically and permanently, uncorrelated with the actual number of *active* devices, since deleted records' images are never reclaimed.

## 3. Index requirements

No `firestore.indexes.json` exists in this repository. Two queries in the current codebase combine an equality filter with an `orderBy` on a *different* field — this combination requires a Firestore composite index; without one, the query throws `FAILED_PRECONDITION` at runtime until an index is created (Firestore's error includes a direct console link to auto-create it, but that's a runtime discovery, not a build-time guarantee):

| Query | Fields | Status |
|---|---|---|
| `streamMaintenanceDevices(uid)` — the **live, actually-used Customer path** (`.where('userId', isEqualTo: uid).orderBy('receivedAt', descending: true)`) | `userId` (equality) + `receivedAt` (order) | **This path is live today** for every Customer session. If the required composite index doesn't already exist in the Firebase Console (unverifiable from this repo), every customer's device list would currently be failing at runtime. This needs direct verification against the Firebase Console — it cannot be confirmed or ruled out from source code alone. |
| `fetchDevicesByStatus` (`.where('status', isEqualTo: status).orderBy('receivedAt', descending: true)`) | `status` (equality) + `receivedAt` (order) | Method exists but — per grep — has no call sites anywhere in the app today. Not an active risk unless/until it's wired up, but would need this index the moment it is. |

Single-field equality queries elsewhere (`phoneNumber` lookups on `users` and `maintenanceDevices`) do not require composite indexes — Firestore auto-indexes single fields by default.

**Action needed (verification, not implementation):** export the current indexes configured in the Firebase Console for project `technostore-v2` and confirm the `userId` + `receivedAt` composite index exists. If it doesn't, this is not a cost risk but a **live functional bug** — customers would be seeing errors instead of their device list. This is a discrepancy between what can be verified from this repository and what may be true in the live Firebase project; flagged per the audit's ground rule not to assume server-side state.

## 4. Recommendations for follow-up (not implemented here)

Listed for prioritization, not as approved work:

1. Add `.limit(...)` (and eventually real pagination, reusing the already-written but unused `fetchMaintenanceDevicesPaginated` pattern) to `streamMaintenanceDevices` for non-Customer roles, so staff/guest sessions don't listen to an ever-growing, unbounded collection.
2. Reconsider whether Guest accounts should hold this listener at all, pending the role-definition clarification raised in `PERMISSIONS_MATRIX.md`.
3. Add Storage cleanup to `deleteDevice` (delete associated `imagesBeforeReceiving`/`imagesAfterDelivery` files when a device document is deleted).
4. Add client-side image compression/resizing before upload in `FirebaseStorageServices.uploadFile` or its callers.
5. Commit a `firestore.indexes.json` to this repository once the Console's current indexes are exported and confirmed, so index requirements are version-controlled rather than living only in Console state invisible to code review.
6. Verify directly against the Firebase Console whether the `userId` + `receivedAt` composite index already exists, given it's required for a live, currently-used customer-facing path.
