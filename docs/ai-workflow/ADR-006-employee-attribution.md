# ADR-006: Employee Attribution on Maintenance Devices

**Status:** Settled — approved by the product owner 2026-07-24, ready for implementation.
**Date:** 2026-07-24, during the Reception & Maintenance area of "Current Application Review & Evolution," as the second of three remaining findings from that area's review (after the dead-code cleanup, PR #21).
**Related:** `ADR-004-admin-user-management-design.md` (Staff Auth: roles, `staffStatus`), `ADR-005-device-lifecycle-archive-deletion.md` (the precedent this ADR follows: additive-field-not-repurposed-field, no backfill for pre-existing incompatible data), `docs/product/PRD.md`.

## Context

`MaintenanceDeviceModel` has three employee-attribution fields — `receivedByEmployee` (required), `maintenanceEmployee` (required when `status` is Fixed or Delivered), `deliveredByEmployee` (required when `status` is Delivered) — all plain `String` values. Their values come from two hardcoded Arabic-name lists in `AppConstants` (`newDeviceEmployeeList`, 7 names, used for Received By; `maintenanceDialogEmployeeList`, 3 names, used for Maintenance Employee and reused for Delivered By), populated once at some point in the app's history and never reconciled against real accounts.

Since Staff Auth shipped (PR #9–#15), real staff accounts exist in `users/{uid}` with a role (`UserRole`: Admin/Reception/Maintenance/Customer/Guest) and a separate `staffStatus` (active/inactive) document. The two systems are completely disconnected: a name in the hardcoded list has no relationship to a real account, doesn't update if a real employee's name changes, doesn't reflect who's actually currently staff, and provides no way to trace a device record back to the real account that touched it.

## Decision

**Add real-account references alongside the existing name fields, without changing the existing fields' type or requiring a migration.**

- `receivedByEmployee` / `maintenanceEmployee` / `deliveredByEmployee` remain exactly as they are today: required (per their existing status-conditional rules) plain-`String` display names. No schema change to these fields, no migration of existing records.
- Three new, nullable, additive fields are added: `receivedByEmployeeUid`, `maintenanceEmployeeUid`, `deliveredByEmployeeUid`. `null` on every one of the ~494 pre-existing records (and stays `null` forever for those — there is no reliable way to map a legacy plain-name string back to a real account, and no value in guessing). Populated going forward whenever the corresponding action is taken through the redesigned dropdowns.
- This mirrors ADR-005's `recordState` precedent exactly: a genuinely new field for a genuinely new concept, not a repurposing of the existing one, and no backfill attempted for data that predates the concept.

**The three dropdowns are sourced from real staff accounts instead of `AppConstants`' hardcoded lists, each filtered to `staffStatus == active` and role-scoped per the following split** (explicit product-owner reasoning, distinct from the current two-list split which grouped Received-By with neither Delivered-By nor Maintenance consistently):
- **Received By Employee** and **Delivered By Employee**: any active staff account (Admin, Reception, *or* Maintenance) — receiving and delivering devices are explicitly shared capabilities across staff roles per the PRD, not restricted to one function.
- **Maintenance Employee**: active Maintenance or Admin accounts only — this one represents technical repair work and judgment, not a shared front-of-house capability.

**Active-only, with an exception for editing historical records:** new selections can only go to a currently-active staff account — you cannot newly attribute work to someone deactivated. When editing a record whose stored employee has since been deactivated, that value still appears in the dropdown (so the field isn't blank or invalid) but no other inactive accounts are offered. The historical value is preserved, not silently dropped or blocked from being viewed/re-saved unchanged.

**No Cloud Function, no additional Firestore rules enforcement of the uid's validity.** This is not a sensitive or irreversible operation — matches the risk-matched-rigor principle already applied to `newDeviceMaintenance`'s route guard (PR #17) and confirmed as standing practice after ADR-005 closed. The uid is written by the same client code path, under the same existing staff-only `maintenanceDevices` write rules, that already writes the plain-name string today without server-side validation against the "real" employee list. This is a continuation of that existing trust model, not a departure from it.

**Query approach:** a one-time fetch of active staff accounts per role scope when a relevant form/dialog opens (not a live stream) — staff rosters at this scale (single-digit to low-double-digit headcount, per the existing 3–7-name lists) change rarely enough that a live listener isn't warranted, and this avoids adding a new long-lived Firestore listener to forms that are already open-act-close. Firestore rules already permit any staff member to read any `users/{uid}` document and its `meta/staffStatus` subdocument, so this requires no rules changes.

## Consequences

- `MaintenanceDeviceModel` gains three new nullable `String? ...Uid` fields, threaded through `toJson`/`fromJson`/`fromMap`/`copyWith` — same shape of change ADR-005 made for `recordState`.
- `AppConstants.newDeviceEmployeeList` and `AppConstants.maintenanceDialogEmployeeList` become dead once the dropdowns are redesigned, and should be removed as part of this implementation (not left as unused dead code re-introducing the exact problem the prior cleanup pass, PR #21, just removed).
- The three dropdowns (intake form's Received By Employee, the Fixed dialog's Maintenance Employee, the Deliver dialog's Delivered By Employee) each need a live-staff-backed data source instead of a static list — a genuinely new query pattern for this codebase (nothing today queries `users` filtered by role; the only precedent is a single-phone-number lookup in `NewDeviceServices.getUserIdByPhoneNumber`).
- Historical device records (~494 existing) permanently have `null` on all three new `...Uid` fields. Any future feature wanting "which real account did this" for old records simply won't have an answer for pre-ADR-006 records — an accepted, permanent limitation, not a gap to close later.
- No `auditLogs` or `lifecycleEvents` provenance entry is created for employee attribution — it's an ordinary field on the device document, written by the same staff-wide write path as every other intake/Fixed/Deliver field, consistent with how those fields have always been treated.

## Explicitly not decided by this ADR

- The intake-form-shape question (single large form vs. PRD's "captures only what's genuinely required" framing) — the third and last of the three Reception & Maintenance findings from this review, deliberately sequenced after this one.
- Any UI/UX polish beyond swapping the dropdown's data source (e.g., showing a staff account's photo, a "select yourself" shortcut for the currently signed-in user) — not raised by the product owner, not assumed here.
- Whether the two now-dead `AppConstants` lists' removal should also trigger a broader audit of `AppConstants` for other similarly-stale hardcoded lists — out of scope, not investigated.
