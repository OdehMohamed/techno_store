# SEARCH_FILTER_IMPLEMENTATION_PLAN.md

> - **Archived:** 2026-07-17
> - **Historical reference only.**
> - Reflects the project's state before this feature shipped. This plan's own "Status" line below (written 2026-07-09) predates implementation — the maintenance-devices search/filtering (v1) feature it describes shipped in v1.1.0 (2026-07-09); see `CHANGELOG.md`.
> - **Must not be treated as the current source of truth.** For current information, see `CHANGELOG.md` (the shipped feature) and `docs/ai-workflow/DECISIONS_LOG.md` (the build record). Retained as historical reference documentation — parts of it, particularly the "Explicitly out of scope for v1" section, may be useful when planning a future v2, but it should not be treated as a current or authoritative plan. Deferred items are tracked in `docs/ai-workflow/BACKLOG.md`.

**Status:** Approved for implementation by the product owner on 2026-07-09. **No code has been modified. No Firestore rules or indexes have been deployed.**
**Branch:** `feature/maintenance-devices-search-filter` (not yet created).
**Scope:** v1 is a Firestore-native implementation — no Algolia/Typesense/external search service. Structured filters (status/brand/employee/date range) plus client-side substring search (phone/name/model/IMEI) on an already-bounded, already-filtered result set. Explicitly designed to fix, not worsen, the existing unbounded staff device stream (`BACKLOG.md` item 1g).

This plan sequences the work; it does not execute it. Implementation proceeds commit-by-commit per `CONTRIBUTING.md`, each commit presented for approval before it's created.

---

## 1. Current implementation (reviewed before planning)

`InnerMaintenanceList` renders three tabs (In Maintenance / Fixed / Delivered), each a `GridView` built from one `MaintenanceListLoaded` state holding all three groups at once (`GroupedMaintenanceDevices`). No search or filter UI exists today.

`MaintenanceListServices.streamMaintenanceDevices(uid)` is the sole data source: for staff (`uid == null`), `.collection('maintenanceDevices').orderBy('receivedAt', descending: true).snapshots()` — no `.where()`, no `.limit()`. A live listener on the entire collection, split into the three tab groups by client-side `status` string matching on every snapshot. Already documented as the dominant cost driver in `FIREBASE_COST_REVIEW.md` and tracked in `BACKLOG.md` item 1g. The customer path (`.where('userId', '==', uid)`) is small and bounded already and is not the concern here.

Two reusable/relevant facts found during this review:
- `MaintenanceListServices.fetchDevicesByStatus` already exists with the right query shape (`status` equality + `receivedAt` order) but has zero call sites — an unused building block for the per-tab query this plan uses.
- `assignedTechnicianId` on `MaintenanceDeviceModel` is dormant (declared, never set or read anywhere else in the app). The field actually populated for "who's working on this" is `maintenanceEmployee` (free-text name from the fixed `AppConstants.maintenanceDialogEmployeeList`).

No `firestore.indexes.json` exists in this repo. The one composite index live in production (`userId` + `receivedAt`) was created out-of-band via Console during Phase 1C and was never captured in version control.

## 2. Limitations this plan addresses

1. Unbounded, unfiltered, real-time listener for all non-customer roles.
2. All three tabs fetched together, always, split client-side, even though only one tab is visible at a time.
3. No structured filtering at the query level.
4. No free-text search, and Firestore has no native substring/"contains" search.
5. No indexes file — index requirements live only in Console state, invisible to code review.

## 3. Decisions (confirmed with the product owner before writing this plan)

- **"Serial" == `imeiNumber`.** No new model field. Search-by-serial and search-by-IMEI are the same operation.
- **"Filter by technician" uses `maintenanceEmployee`**, the field actually populated today. `assignedTechnicianId` stays dormant and out of scope — a candidate for its own future `BACKLOG.md` item (wire it up, or remove it) if ever revisited.
- **Filter combination scope: status (tab) + at most one more structured filter** (brand, OR employee, OR date range — not combined with each other). Keeps the composite-index count small and bounded for v1; a fully composable multi-filter builder is out of scope.
- **Pagination: live top-N + explicit "load more."** Each tab/filter combination is a live `.limit(N)` listener (real-time updates within that window matter for a staff dashboard reflecting live status changes), with an explicit "load more" action doing a one-time `startAfterDocument` fetch appended to the list for anything beyond that window — the same pattern the already-written, currently-unused `fetchMaintenanceDevicesPaginated` anticipated.

## 4. Architecture

**Per-tab queries replace the single unbounded fetch.** Each tab becomes its own query: `where('status', '==', X).orderBy('receivedAt', descending: true).limit(N)`, adapting the existing `fetchDevicesByStatus` shape into a live listener. Only the active tab is listened to.

**Structured filters** add one more `.where()` clause on top of the tab's base query:
- Brand: `where('brand', '==', selectedBrand)`
- Employee: `where('maintenanceEmployee', '==', selectedEmployee)`
- Date range: range filter on `receivedAt` itself — same field already used for ordering, so this does not require an additional composite index beyond the base one.

**Free-text search** (name/phone/model/IMEI) runs client-side, substring match, against the currently loaded (bounded, possibly filtered) result set only — never against the full collection. This is deliberately not a Firestore query: Firestore has no native "contains anywhere" search, and a client-side substring match over a bounded page (≤ a few hundred documents) is cheap and correct, unlike doing it over the whole collection.

**Tab-switch behavior change (explicit trade-off):** because each tab now drives its own query instead of slicing one big pre-loaded list, switching tabs is no longer instant on first visit — it shows a brief loading state while that tab's query resolves. To keep revisits within a session fast, the cubit keeps each visited tab's last-loaded result cached for the session (cleared when a filter or search changes), so switching back to an already-visited tab doesn't re-fetch. New filters or search text reset that tab's pagination and re-query.

## 5. Firestore indexes

New `firestore.indexes.json` committed to the repo for the first time, containing:

1. `maintenanceDevices`: `status` (ASC) + `receivedAt` (DESC) — the base per-tab query. **Must be verified/created** — `fetchDevicesByStatus` has never been called, so this index likely does not exist yet in production despite the query code already existing.
2. `maintenanceDevices`: `status` (ASC) + `brand` (ASC) + `receivedAt` (DESC) — status + brand filter combination.
3. `maintenanceDevices`: `status` (ASC) + `maintenanceEmployee` (ASC) + `receivedAt` (DESC) — status + employee filter combination.
4. `maintenanceDevices`: `userId` (ASC) + `receivedAt` (DESC) — the existing customer-path index, captured in version control for the first time; already live and confirmed `READY` in production since Phase 1C.

Date-range filtering reuses index #1 (same field as the order-by) — no additional index needed.

## 6. New/changed files (planned, not yet created)

- `firestore.indexes.json` (new, repo root) — the four indexes above.
- `lib/features/maintenance_list/services/maintenance_list_services.dart` — replace/adapt `fetchDevicesByStatus` into the live per-tab query method; add the structured-filter and date-range query variants.
- `lib/features/maintenance_list/cubit/maintenance_list_cubit.dart` + `maintenance_list_state.dart` — new state shape carrying the active tab, active filter (if any), search text, loaded devices, `hasMore`, and per-tab session cache.
- `lib/features/maintenance_list/view/inner_maintenance_list.dart` — new search/filter UI (search field, filter selector using existing `AppConstants.deviceBrandList`/`maintenanceDialogEmployeeList` plus a date-range picker), tab-switch driving the cubit instead of a static pre-loaded `TabBarView`, "load more" affordance.

## 7. Explicitly out of scope for v1 (documented per product-owner instruction, candidates for a future phase)

- **True full-text/fuzzy/relevance-ranked search** — would need Algolia, Typesense, or a similar external index. Not evaluated further here since explicitly ruled out for this phase.
- **Fully composable multi-filter queries** (any combination of brand + employee + date range simultaneously) — v1 supports status + at most one more filter; going further multiplies the composite-index count and likely needs a different query strategy (or an external search service) rather than more Firestore indexes.
- **Searching beyond the currently loaded/paginated window** — free-text search only searches what's already loaded for the active tab/filter. A staff member searching for something outside that window won't find it without loading more first. Direct, accepted consequence of bounding reads to fix the cost problem.
- **Wiring up or removing `assignedTechnicianId`** — separate, smaller candidate item, not part of this feature.
