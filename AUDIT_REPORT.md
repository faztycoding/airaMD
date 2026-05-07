# airaMD — Comprehensive Code Audit Report

**Audit date:** 7 May 2026
**Scope:** Full repo at `/Users/faztycoding/Documents/GitHub/airaMD`
**Auditor mode:** READ-ONLY — no code changes were made.
**Codebase size:** ~37,612 lines of Dart in `airamd_app/lib`, 10 SQL migrations, 191 tests passing, `flutter analyze` clean.

> **Important context:** Multiple hardening rounds have already been applied (see `IMPLEMENTATION_PLAN_TH_2.md` and prior session memories). Migrations 008-010 are deployed. Many "obvious" issues are already fixed. This report focuses on what remains.

---

## Executive Summary — Top 10 Critical / High Priority Issues

| # | Severity | File:Line | Issue |
|---|----------|-----------|-------|
| 1 | 🔴 Critical | `airamd_app/lib/features/auth/login_screen.dart:127` | **Hardcoded production Supabase project URL** in `emailRedirectTo` — leaks project ref into source, breaks env switching dev/staging/prod |
| 2 | 🔴 Critical | `airamd_app/lib/config/supabase_config.dart:16-23` | **`assert()` for required env vars is stripped in release builds** — production binary built without `--dart-define=SUPABASE_URL` will silently start with empty URL |
| 3 | 🔴 Critical | `airamd_app/lib/features/auth/pin_lock_screen.dart:67-77` | **PIN stored as plaintext in flutter_secure_storage** — bypasses the bcrypt CHECK constraint on `staff.pin_hash` (migration 009). The "secure" label is misleading — anyone with device access + jailbreak can read it |
| 4 | 🔴 Critical | `supabase/migrations/004_drop_dev_rls.sql:60-130` & `005_production_hardening.sql` | **RBAC RLS gap**: migration 005 only restricts WRITE on `treatment_records`, `financial_records`, `staff`. Receptionist can still INSERT/UPDATE/DELETE on `patients`, `products`, `inventory_transactions`, `courses`, `course_sessions`, `consent_forms`, etc. via the `FOR ALL` policy from 004 |
| 5 | 🔴 Critical | `airamd_app/lib/features/auth/login_screen.dart:152-168` | **Non-atomic clinic + staff bootstrap** — clinic INSERT succeeds, staff INSERT may fail → orphaned clinic with no owner. No transaction or rollback |
| 6 | 🟠 High | `airamd_app/lib/core/services/offline_sync_service.dart:67-72` | **Read-modify-write race in `enqueue()`** — concurrent calls read same queue, last writer wins, ops get lost. iOS Keychain ~4KB per-key limit also silently truncates large queues |
| 7 | 🟠 High | `airamd_app/lib/core/services/offline_sync_service.dart:85` & `auto_sync_engine.dart:354,378,400` | **Operation IDs use millis/microsecondsSinceEpoch** — collisions on rapid taps (multiple ops in same ms). Should use UUID |
| 8 | 🟠 High | `airamd_app/lib/core/repositories/course_repository.dart:55-60` | **Race in `useSession()`** — read sessions_used, +1, write back. Two concurrent calls both see N, both write N+1, second use lost. No advisory lock or atomic UPDATE |
| 9 | 🟠 High | `airamd_app/lib/features/treatments/treatment_form_screen.dart` (1554 lines) | **Massive feature files**: 6 files exceed 1000 lines (`calendar_screen.dart` 1763, `treatment_form_screen.dart` 1554, `face_diagram_screen.dart` 1366, `digital_notepad_screen.dart` 1303, `audit_log_screen.dart` 1184, `inventory_screen.dart` 1044) — review effort, merge conflicts, test coverage |
| 10 | 🟠 High | `airamd_app/lib/core/repositories/patient_repository.dart:88-93` & `product_repository.dart:156-161` | **Duplicated `_escapeLike` helper** — same 5-line method copy/pasted; if the SQL injection rules ever change, only one will be updated |

---

## 1. Project Structure & Tech Stack

### Stack identified

| Layer | Technology | Version |
|-------|-----------|---------|
| Frontend | Flutter | 3.41.0 (CI pinned, `pubspec.yaml` SDK ^3.7.0) |
| Language | Dart | 3.x |
| State | flutter_riverpod | ^2.6.1 |
| Routing | go_router | ^14.8.1 |
| Backend | Supabase (PostgreSQL + Auth + Storage + Edge Functions) | supabase_flutter ^2.8.0 |
| Auth | Supabase Auth | + local PIN + biometrics (`local_auth` ^2.3.0) |
| Notifications | Firebase Messaging | ^15.2.4 + flutter_local_notifications ^18.0.1 |
| Crash | Firebase Crashlytics | ^4.3.2 |
| Offline | flutter_secure_storage + connectivity_plus + path_provider | mixed |
| Build | Flutter standard, GitHub Actions CI | `.github/workflows/ci.yml` |

### Folder structure observations

`@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/`

```
lib/
├── app.dart                  # Root MaterialApp + auth gate + PIN gate
├── main.dart                 # Bootstrap (Firebase, Supabase, push, crash)
├── config/                   # 4 files: theme, routes, constants, supabase_config
├── core/
│   ├── localization/         # 3 files (one massive 865-line app_localizations.dart)
│   ├── models/               # 23 files
│   ├── providers/            # 12 files (Riverpod)
│   ├── repositories/         # 21 files (data access)
│   ├── services/             # 9 files (cross-feature logic)
│   └── widgets/              # 14 reusable widgets
└── features/                 # 8 feature folders, 45 files
    ├── auth, calendar, courses, dashboard, financial, patients, settings, treatments
```

| Finding | Sev | File | Note |
|---------|-----|------|------|
| Conventions clean — feature/repo/service split is explicit | ✅ | — | Use of `_profile_*.dart` private parts in `patients/` is consistent |
| README references migrations 001 → 009 but 010 exists | Low | `@/Users/faztycoding/Documents/GitHub/airaMD/README.md:35` | Doc drift since migration 010 added |
| Two `IMPLEMENTATION_PLAN_TH*.md` files coexist | Low | repo root | Version bloat — `_2.md` should supersede `_1.md` |
| Duplicate `.flutter-plugins-dependencies 2` file | Low | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/` | OS-level duplicate — clean up |
| Top-level `Medical Face Diagram/` empty folder | Low | repo root | Stub directory, can be removed |
| `.agents/` and `.windsurf/` folders present | OK | — | Tooling state, expected |
| `dev_rls_bypass.sql` exists alongside production migrations | Medium | `@/Users/faztycoding/Documents/GitHub/airaMD/supabase/dev_rls_bypass.sql` | Verify NEVER applied to prod — accidental run = full DB exposure |

---

## 2. Frontend (Flutter UI)

### 2.1 Component reusability & state management

| Finding | Sev | File:Line | Note |
|---------|-----|-----------|------|
| Riverpod usage idiomatic — `Provider`, `FutureProvider`, `AsyncNotifierProvider` chosen appropriately | ✅ | — | Pagination implemented well in `paginatedPatientsProvider` |
| `currentClinicIdProvider` returns first staff's clinic_id only | Medium | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/core/providers/auth_providers.dart:34-37` | Multi-clinic doctors not supported — single staff row assumption |
| Massive UI files (>1000 LOC) | High | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/calendar/calendar_screen.dart` (1763), `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/treatments/treatment_form_screen.dart` (1554) | Hard to review, test, refactor. Should split with `part of` or extract widgets |
| `_dashSearchResultsProvider` no debounce | Medium | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/dashboard/dashboard_screen.dart:17-21` | Every keystroke fires a search RPC. Add 250-300ms debounce |
| Page builder pattern: `part '_dashboard_*.dart'` files | OK | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/dashboard/dashboard_screen.dart:11-13` | Good split |
| `_AppBootstrap` red error screen with no retry | Low | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/main.dart:112-122` | If init fails (network, Firebase) user is stuck. Add retry button |
| `appUnlockedProvider` defaults to `kIsWeb` | OK | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/app.dart:15` | Web auto-unlock is intentional |
| `MaterialApp` nested twice in `AiraApp.build` (lines 85+103) | Medium | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/app.dart:85-122` | Two `MaterialApp` instances on the unlocked path: outer `AuthGate` wrapper + inner `MaterialApp.router`. Causes duplicate `MediaQuery`, hero tag warnings, theme inheritance complexity. Should be a single `MaterialApp.router` with redirect logic |

### 2.2 Fonts

| Finding | Sev | Note |
|---------|-----|------|
| Uses `google_fonts` ^6.2.1 — Playfair Display + Plus Jakarta Sans | OK | Loaded via `GoogleFonts.playfairDisplay()` / `GoogleFonts.plusJakartaSans()` |
| **Network-loaded fonts on first launch** — no offline fallback | Medium | `google_fonts` fetches from Google CDN by default. Offline first-launch shows fallback system font (FOUT). For a clinic app on iPad with intermittent connectivity this is acceptable but worth documenting |
| No FOIT (Flash of Invisible Text) handling | Low | Default Google Fonts behavior — text shows blank momentarily before swap |
| **License compliance**: Google Fonts are SIL OFL — OK to ship | ✅ | Self-host recommendation: bundle as asset for guaranteed first-paint |

### 2.3 Styling / theme

| Finding | Sev | File:Line | Note |
|---------|-----|-----------|------|
| Single source of truth for colors | ✅ | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/config/theme.dart` | `AiraColors` class — good design token discipline |
| No dark mode | Medium | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/app.dart:88` | Only `AiraTheme.light` referenced. Clinic app on iPad — dark mode optional but increasingly expected |
| Hardcoded gradient colors scattered in features | Medium | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/financial/financial_screen.dart:102` and many others | `Color(0xFF3D2517)`, `Color(0xFFD4B89A)` etc. duplicated. Extract to `AiraColors` |
| Custom `withValues(alpha: x)` pattern everywhere | OK | All UI files | Migration to Flutter 3.27+ `Color.withValues` API. Consistent |

### 2.4 Responsiveness

| Finding | Sev | File:Line | Note |
|---------|-----|-----------|------|
| Landscape-only orientation lock | OK | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/main.dart:45-48` | Intentional for iPad-first design |
| `LayoutBuilder` + `isWide` / `isNarrow` breakpoints used in dashboard, patient list | ✅ | — | Adaptive layouts present |
| No portrait support → small iPhone users left out | Medium | — | If clinic ever uses an iPhone for quick reception tasks, layout breaks |
| Some hardcoded `width: 4, height: 28` accent bars | Low | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/patients/patient_list_screen.dart:185-187` | Dimensions repeat across screens — extract to a tiny `AiraAccentBar` widget |

### 2.5 Accessibility (a11y)

| Finding | Sev | File:Line | Note |
|---------|-----|-----------|------|
| `AiraTapEffect` exposes `Semantics(label, hint, button, enabled)` | ✅ | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/core/widgets/aira_tap_effect.dart:132-140` | All tap targets become accessible buttons |
| Most call sites of `AiraTapEffect` don't pass `semanticsLabel` | Medium | scattered | Reader falls back to child text — acceptable for cards but icon-only `IconButton` paths announce "ปุ่ม" with no context |
| No alt text strategy for `Image.network` (cached_network_image) | Medium | photo screens | iPad VoiceOver users get zero info on patient before/after photos |
| Color contrast not verified | Medium | — | `AiraColors.muted` (gray) on `AiraColors.cream` (beige) may fail WCAG AA. Run a contrast audit |
| No `TextScaler` clamp | Low | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/app.dart:103-119` | Dynamic Type at 200% will overflow most cards |

### 2.6 Performance

| Finding | Sev | File:Line | Note |
|---------|-----|-----------|------|
| Bundle size not measured | Medium | — | No `flutter build --analyze-size` step in CI |
| No code splitting / lazy routes | Medium | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/config/routes.dart` | All screens imported at top — initial JS payload (web) and tree-shake potential not optimized |
| `cached_network_image` used | ✅ | photos | Good |
| Image compression set | ✅ | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/config/constants.dart:41-43` | Max 2048w, 80% quality |
| `flutter_image_compress` ^2.3.0 included | ✅ | pubspec | But verify it's actually used in photo upload paths |
| `Listener` + `EagerGestureRecognizer` for face diagram pen | ✅ | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/patients/face_diagram_screen.dart` | Avoids re-paint storm |

### 2.7 Forms

| Finding | Sev | File:Line | Note |
|---------|-----|-----------|------|
| Client validation present | ✅ | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/settings/inventory_validation.dart`, `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/financial/financial_validation.dart` | Extracted helpers, well-tested |
| Server validation enforced via DB CHECK constraints | ✅ | migration 009 | `financial_records.amount >= 0`, `staff.pin_hash` bcrypt format |
| No async server-side double-check before save | Medium | most save flows | Trusts Supabase will reject — fine because RLS enforces, but UI can present stale data |
| `patient_form_screen` has 16 controllers + 8 state vars in single class | High | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/patients/patient_form_screen.dart:32-57` | Should extract a `PatientFormState` value object |
| Loading states present (`_loading` boolean) | OK | most forms | Standard pattern |
| Error toast pattern via `AiraFeedback` | ✅ | shared widget | Consistent UX |

---

## 3. Backend / API (Supabase)

There is **no custom REST/GraphQL backend** — the app talks directly to Supabase via `supabase_flutter`. "API" surface = PostgREST + RPCs + Edge Functions.

### 3.1 RPC inventory (verified migration 009 + 010)

| RPC | Args | Return | Caller | Status |
|-----|------|--------|--------|--------|
| `generate_patient_hn` | `()` (trigger) | n/a | `BEFORE INSERT ON patients` | ✅ |
| `deduct_stock_atomic(p_product_id UUID, p_quantity NUMERIC)` | atomic | `NUMERIC` | `product_repository.dart:118` | ✅ |
| `record_treatment_atomic(p_treatment JSONB, p_inventory JSONB)` | atomic | `JSONB` | `treatment_repository.dart:68` | ✅ |
| `get_my_clinic_ids()` | — | `SETOF UUID` | RLS policies | ✅ |
| `get_my_role(p_clinic_id UUID)` | — | `staff_role` | RLS policies | ✅ |
| `populate_course_sessions()` | — (trigger) | n/a | `AFTER INSERT ON courses` | ✅ |
| `bump_treatment_version()` | — (trigger) | n/a | `BEFORE UPDATE ON treatment_records` | ✅ |
| `get_today_revenue(p_clinic_id UUID)` | — | `NUMERIC` | `financial_repository.dart:88` | ✅ |
| `get_patient_full(p_patient_id UUID)` | — | `JSONB` | `patient_repository.dart:124` | ✅ |
| `escape_like(s TEXT)` | — | `TEXT` | helper | ✅ |
| `record_audit_log(...)` | 6 args | `audit_logs` | `audit_repository.dart:33` | ✅ |
| `is_own_clinic_path(bucket, path)` | — | `BOOLEAN` | storage RLS | ✅ |

| Finding | Sev | File:Line | Note |
|---------|-----|-----------|------|
| All RPC param names match Flutter call sites | ✅ | verified | Audited last session |
| Storage path injection via `is_own_clinic_path` casts first segment as UUID | ✅ | `@/Users/faztycoding/Documents/GitHub/airaMD/supabase/migrations/005_production_hardening.sql:67-82` | Returns FALSE on non-UUID path — safe |
| **Edge Function `send-line-message` referenced but not in repo** | High | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/core/services/messaging_service.dart:65` | `client.functions.invoke('send-line-message', ...)`. If the function isn't deployed, every LINE send fails with cryptic error. No deploy artifact in `supabase/` |

### 3.2 PostgREST direct queries (`.from(table)`)

These bypass any service-layer logic and rely 100% on RLS for authorization.

| Finding | Sev | File:Line | Note |
|---------|-----|-----------|------|
| Repositories call `.from(table)` directly — single tenancy enforced via `eq('clinic_id', clinicId)` and RLS | ✅ | every repository | Defense in depth |
| `audit_repository.getByEntity` queries WITHOUT `eq('clinic_id', x)` | Medium | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/core/repositories/audit_repository.dart:53-60` | Relies on RLS. Safe but not obvious — add explicit filter for defense-in-depth |
| `inventory_repository.getByProduct` no clinic filter | Medium | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/core/repositories/inventory_repository.dart:30-44` | Same — RLS-only protection |
| Status codes / error mapping | Mostly OK | `repository_exceptions.dart` | `PostgrestException.message.contains('insufficient_stock')` — string-match. Brittle if Postgres changes phrasing |

### 3.3 CORS, rate limiting, secrets

| Finding | Sev | File:Line | Note |
|---------|-----|-----------|------|
| `SUPABASE_URL` / `SUPABASE_ANON_KEY` from `--dart-define` | ✅ | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/config/constants.dart:23-25` | Not hardcoded |
| **`emailRedirectTo: 'https://pzqjqqaekxmfdlrxbgmk.supabase.co/auth/v1/verify'`** | 🔴 Critical | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/auth/login_screen.dart:127` | Hardcoded prod URL leaks project ref into source. Should be `${AppConstants.supabaseUrl}/auth/v1/verify` |
| **`assert()` for required env vars** | 🔴 Critical | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/config/supabase_config.dart:16-23` | `assert` is stripped in release — production binary built without `--dart-define=SUPABASE_URL` will silently start with empty URL → crash on first request |
| LINE Channel Token / Secret stored in `flutter_secure_storage` | OK | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/core/services/messaging_service.dart:230-241` | Per-device, not in source |
| No rate limiting on auth endpoints | Medium | — | Supabase has built-in throttling but it's project-wide. Login endpoint should have UI-level throttle |
| No CORS issues — native iOS/Android client only | ✅ | — | Web build exists but is dev-only |
| `.env.dev` file in `.gitignore` | ✅ | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/.gitignore` | Good |
| `.env.example` checked in | ✅ | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/.env.example` | Sample only, no real keys |

---

## 4. Database

### 4.1 Schema

10 migrations, well-versioned: `001_initial_schema.sql` (781 lines) → `010_audit_secure_writes.sql`. All migrations 008-010 verified idempotent.

| Finding | Sev | File:Line | Note |
|---------|-----|-----------|------|
| 21 tables, all have `clinic_id` (multi-tenant) and `created_at` | ✅ | `001_initial_schema.sql` | Consistent |
| All foreign keys with explicit `ON DELETE` (CASCADE / SET NULL) | ✅ | — | Good |
| RLS enabled on all tables | ✅ | `001_initial_schema.sql:633-652` | — |
| `treatment_records.version` for optimistic concurrency | ✅ | migration 009 | — |
| `course_sessions UNIQUE(course_id, session_number)` | ✅ | migration 009 | — |
| `financial_records.amount >= 0` CHECK | ✅ | migration 009 | — |
| `staff.pin_hash` CHECK bcrypt format | ✅ | migration 009 | But see #2.5 — Flutter doesn't actually use this column |
| GIN indexes on `drug_allergies`, `medical_conditions`, `current_medications` | ✅ | migration 009 | — |
| `product.expiry_date` partial index | ✅ | `005_production_hardening.sql:52-53` | — |
| **`courses.sessions_total` is GENERATED** | OK | `001:474` | `STORED` so it's queryable |
| No soft-delete column on `patients` (uses `is_active` per-staff but not per-patient) | Medium | `001:171-200` | `softDelete` in repo sets `is_active = false` but `patients` table has no `is_active` column → fails silently |
| No backups documented | Medium | — | Supabase free tier has daily backups; production should configure point-in-time recovery |

### 4.2 RLS authorization gaps

This is the largest cluster of issues. Migration 005 only locked down WRITE on `treatment_records`, `financial_records`, and `staff`. Everything else still uses migration 004's broad `FOR ALL` policy.

| Table | Read | Insert | Update | Delete | Issue |
|-------|------|--------|--------|--------|-------|
| `patients` | clinic | clinic | clinic | clinic | Receptionist can DELETE patients ⚠️ |
| `appointments` | clinic | clinic | clinic | clinic | OK for receptionist |
| `treatment_records` | clinic | OWNER+DOCTOR | OWNER+DOCTOR | OWNER only | ✅ |
| `financial_records` | clinic | OWNER+DOCTOR | OWNER+DOCTOR | OWNER only | ✅ |
| `staff` | clinic | OWNER only | OWNER OR self | OWNER only | ✅ |
| `audit_logs` | clinic | RPC only | none | none | ✅ |
| `products` | clinic | clinic | clinic | clinic | Receptionist can DELETE products ⚠️ |
| `inventory_transactions` | clinic | clinic | clinic | clinic | Receptionist can fake stock-in ⚠️ |
| `courses` | clinic | clinic | clinic | clinic | Receptionist can sell courses ⚠️ |
| `course_sessions` | clinic | clinic | clinic | clinic | Receptionist can mark session used ⚠️ |
| `consent_forms` | clinic | clinic | clinic | clinic | Receptionist can DELETE patient consent ⚠️ |
| `consent_form_templates` | clinic | clinic | clinic | clinic | Receptionist can edit templates |
| `face_diagrams` | clinic | clinic | clinic | clinic | Receptionist can write/delete clinical drawings ⚠️ |
| `digital_notepads` | clinic | clinic | clinic | clinic | Receptionist can write/delete clinical notes ⚠️ |
| `message_logs` | clinic | clinic | clinic | clinic | OK |
| `patient_photos` | clinic | clinic | clinic | clinic | Receptionist can DELETE before/after photos ⚠️ |
| `treatment_rules` | clinic | clinic | clinic | clinic | Receptionist can change repeat-day rules ⚠️ |
| `services` | clinic | clinic | clinic | clinic | Receptionist can edit price list ⚠️ |
| `clinics` | clinic | auth.uid only | clinic | clinic | OK at INSERT, weak at UPDATE |

> **Implication:** Even though the Flutter UI hides settings/financial/clinical write paths via `AccessGuard`, a malicious authenticated receptionist with the same anon key + curl can still mutate these tables directly. **The UI guards are NOT a substitute for DB-level RLS.**

| Finding | Sev | Recommended fix |
|---------|-----|-----------------|
| 12 tables grant write access to all clinic members | 🔴 Critical | New migration 011 that locks `INSERT/UPDATE/DELETE` on `patient_photos`, `face_diagrams`, `digital_notepads`, `consent_forms`, `consent_form_templates`, `treatment_rules`, `services`, `inventory_transactions`, `courses`, `course_sessions`, `products` to OWNER+DOCTOR. Patient creation may stay open since receptionist needs it |

### 4.3 Indexing

| Finding | Sev | Note |
|---------|-----|------|
| All foreign-key cols indexed | ✅ | — |
| Date-range cols indexed | ✅ | `appointments(clinic_id, date)`, `treatment_records(clinic_id, date DESC)` |
| Partial indexes for low-stock / expiry / outstanding | ✅ | migration 005 |
| `course_sessions` lookup by `clinic_id` | ✅ | migration 005 |
| **No composite index for `(patient_id, treatment_records.date DESC)`** | Medium | The patient profile screen orders treatments by date — single-column patient_id index forces extra sort |
| No index on `staff.user_id` | OK | actually exists (`idx_staff_user`) |
| `idx_staff_user_active` partial added in 009 | ✅ | — |

### 4.4 Migrations

| Finding | Sev | Note |
|---------|-----|------|
| 10 migrations, sequentially numbered | ✅ | — |
| Migrations 008-010 idempotent (verified) | ✅ | — |
| `001_initial_schema.sql` does `DROP TABLE ... CASCADE` at top | High | Re-running 001 nukes data — only safe on empty DB. Document this clearly |
| No migration testing in CI | Medium | CI only runs Flutter tests. Add a `psql -f` step against ephemeral Postgres |
| No down migrations | Low | Supabase migrations conventionally don't have `down`, but rollback strategy missing |

---

## 5. CRUD Operations — End-to-End

Methodology: pick representative entities, verify UI → repo → DB.

### Patients
| Op | UI | API | DB | Auth | Validation | Edge cases |
|----|-----|------|-----|------|------------|-----------|
| Create | `patient_form_screen.dart:109` | `patient_repository.create` | `INSERT INTO patients` (HN auto-gen) | RLS clinic ✅ | Identity required ✅ | Null clinicId handled ✅ |
| Read | `patient_list_screen` (paginated) + `patient_profile_screen` | `getFullProfile` RPC | `get_patient_full` JSONB | RLS clinic ✅ | — | Empty list ✅, RPC null ✅ |
| Update | `patient_form_screen.dart` (edit) | `patient_repository.updatePatient` | UPDATE | RLS clinic ✅ | Identity required ✅ | Conflicting save unhandled |
| Delete | NOT exposed in UI | `patient_repository.softDelete` | `UPDATE is_active = false` | RLS clinic — but column doesn't exist! | — | **Will silently fail (column missing)** ⚠️ |

### Treatments
| Op | UI | API | DB | Auth | Validation | Edge cases |
|----|-----|------|-----|------|------------|-----------|
| Create | `treatment_form_screen.dart` | `createWithInventory` RPC | `record_treatment_atomic` (transactional) | RLS OWNER+DOCTOR ✅ | Stock check, products required | Atomic ✅, offline queueing ✅, version conflict ✅ |
| Read | `treatment_form_screen` (edit) + profile dermatology tab | `treatmentRepoProvider.get` | SELECT | RLS ✅ | — | Returns null safely ✅ |
| Update | `treatment_form_screen` edit branch | `updateRecordVersioned` | UPDATE with version | RLS ✅ | Optimistic concurrency ✅ | `VersionConflictException` raised ✅ |
| Delete | NOT in UI | `deleteRecord` | DELETE | RLS OWNER only ✅ | — | — |

### Products / Inventory
| Op | UI | API | DB | Auth | Validation | Edge cases |
|----|-----|------|-----|------|------------|-----------|
| Create | `product_library_screen` | `productRepo.create` | INSERT | RLS clinic — should be OWNER+DOCTOR ⚠️ | basic | — |
| Stock-in | `inventory_screen` | `inventoryRepo.stockIn` | INSERT to inventory_transactions | RLS clinic ⚠️ | — | No CHECK that quantity > 0 (only at app level) |
| Stock-out (treatment) | inside `record_treatment_atomic` | RPC | atomic | ✅ | quantity > 0 + sufficient stock | Race-safe ✅ |
| Stock-out (manual) | `inventory_screen` | `inventoryRepo.create` | INSERT | RLS clinic | — | **Does NOT call deduct_stock_atomic** — stock_quantity stays unchanged for manual usage entries! ⚠️ |

| Finding | Sev | File:Line |
|---------|-----|-----------|
| `softDelete` writes to non-existent column | 🟠 High | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/core/repositories/patient_repository.dart:43-45` |
| Manual inventory entries don't update product.stock_quantity | 🟠 High | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/core/repositories/inventory_repository.dart:24-27` & 47-68 |
| `useSession()` race condition (RMW) | 🟠 High | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/core/repositories/course_repository.dart:55-65` |
| Most CRUD has no end-to-end test | Medium | — |

---

## 6. Security

### 6.1 Authentication & Session

| Finding | Sev | File:Line | Note |
|---------|-----|-----------|------|
| Supabase JWT lifecycle handled by `supabase_flutter` | ✅ | `auth_gate.dart` | Refresh automatic |
| Hardcoded redirect URL leaks production project ref | 🔴 Critical | `login_screen.dart:127` | (above) |
| **PIN stored as plaintext in secure storage** | 🔴 Critical | `pin_lock_screen.dart:67-77` | The `_pinStorageKey` reads back the PIN string and compares directly. Hash with bcrypt or scrypt before storing |
| Biometric auth wraps PIN, not auth token | OK | `pin_lock_screen.dart:100-120` | App-lock pattern only — re-auth still requires Supabase JWT |
| Auto-lock window | ✅ | `app.dart:50-60` | 5/30 min via env config |
| Auth gate streams `onAuthStateChange` | ✅ | `auth_gate.dart:19-25` | — |
| Sign-up: clinic + staff INSERTs not transactional | 🔴 Critical | `login_screen.dart:152-168` | Staff INSERT can fail leaving orphan clinic |

### 6.2 Authorization

| Finding | Sev | Note |
|---------|-----|------|
| Three-layer guards: AuthGate → PIN → AccessGuard (route-level) → InlineAccessGuard (in-screen) | ✅ | Defense in depth |
| `effectiveStaffRoleProvider` defaults to `receptionist` (deny by default) | ✅ | `auth_providers.dart:39-42` |
| `/patients/:id` route has NO AccessGuard | Low | `routes.dart:88-94` | Receptionist CAN open. Profile screen uses inline guards on tabs. Worth verifying every sensitive tab is guarded |
| `/dashboard` no AccessGuard | OK | Receptionist needs dashboard |
| RLS gaps (see §4.2) | 🔴 Critical | Multiple tables lack role-based RLS |

### 6.3 Injection / Web vulns

| Finding | Sev | Note |
|---------|-----|------|
| SQL injection: not possible — only PostgREST + RPCs, no raw SQL | ✅ | — |
| ILIKE wildcard injection: handled with `_escapeLike` | ✅ | (but duplicated, see §1) |
| XSS: not applicable — no WebView with HTML rendering | ✅ | — |
| CSRF: no cookies — JWT in Authorization header | ✅ | — |
| **SSRF via `emailRedirectTo`** | High | `login_screen.dart:127` | Hardcoded but if it became dynamic and not validated, bad redirects possible |
| **IDOR**: `/patients/:id` is opaque UUID + RLS — safe | ✅ | — |

### 6.4 Secrets / dependency hygiene

| Finding | Sev | Note |
|---------|-----|------|
| No secrets committed | ✅ | Verified via grep |
| `pubspec.lock` committed | ✅ | Reproducible builds |
| `flutter pub outdated` reports 110 packages with newer versions | Medium | CI noise — schedule a quarterly upgrade |
| No SAST step in CI | Medium | Add `dart analyze --fatal-infos` + `pub audit` |

---

## 7. Error Handling & Logging

| Finding | Sev | File:Line | Note |
|---------|-----|-----------|------|
| Sealed `RepositoryException` hierarchy | ✅ | `repository_exceptions.dart` | Typed errors |
| 9 places still use `throw Exception('...')` | Medium | `face_diagram_screen.dart:301`, `consent_form_screen.dart:85`, `digital_notepad_screen.dart:166`, `course_repository.dart:58`, others | Defeats typed exception design |
| `Log` service skips info/debug in release | ✅ | `logger_service.dart:18-30` | — |
| 82 raw `debugPrint` calls remain | Medium | scattered (16 in `auto_sync_engine`, 14 in `push_notification_service`) | Migrate to `Log.i/w/e` for consistent tagging + remote forwarding |
| Crashlytics wired for fatal errors | ✅ | `main.dart:55-65` | — |
| `CrashReporter` boilerplate ready for Sentry | ✅ | `crash_reporting_service.dart` | Awaiting DSN |
| **Audit log writes are non-blocking + swallow errors** | Medium | `audit_service.dart:31-34` | If audit logging fails, app continues. Compliance argues this should at least surface in logs |
| No global error boundary widget | Medium | — | Riverpod's `AsyncValue.error` handled per-widget. A top-level `ErrorWidget.builder` would catch render-time errors gracefully |

---

## 8. Testing

| Layer | Files | Tests | Coverage |
|-------|-------|-------|----------|
| Unit | 16 files | ~150 tests | repos, services, models, validation |
| Widget | 5 files | ~25 tests | login, settings, financial, auth_gate, aira_tap_effect |
| Integration | 1 file | ~15 tests | full app boot + nav |

**Total: 191 passing.** ✅ `flutter analyze` clean.

| Finding | Sev | Note |
|---------|-----|------|
| Strong unit coverage on validation + repos + models | ✅ | — |
| **Critical paths untested**: photo upload, face diagram save, consent PDF generation | 🟠 High | These are clinical-data heavy, regression-prone. No widget or integration tests |
| **No tests against real Supabase** (mocked or not) | High | All RPC calls are happy-path mocked. Param mismatch / RLS regressions not caught until manual smoke |
| No fuzzing of HN generation under concurrency | Medium | Race-safe at DB level (advisory lock) but no test asserts uniqueness |
| Coverage report not enforced in CI | Low | `ci.yml:39-44` generates lcov but never fails |
| No golden tests for theme-critical screens | Low | UI regressions silent |

---

## 9. Refactor Opportunities

| # | File:Line | Issue | Recommendation |
|---|-----------|-------|----------------|
| R1 | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/calendar/calendar_screen.dart` (1763 lines) | God-file | Split into `calendar_screen.dart` + `_calendar_grid.dart` + `_calendar_day_sheet.dart` |
| R2 | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/treatments/treatment_form_screen.dart` (1554 lines) | God-file | Extract `_TreatmentFormState` value object, split each tab into a part file |
| R3 | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/patients/face_diagram_screen.dart` (1366 lines) | God-file | Extract painter to existing `face_outline_painter.dart`, drawing controller to its own class |
| R4 | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/settings/audit_log_screen.dart` (1184 lines) | God-file | Extract row builders + filter chips into dedicated widgets |
| R5 | `_escapeLike` duplicated | `patient_repository.dart:88` & `product_repository.dart:156` | Extract to `lib/core/repositories/_helpers.dart` and call from both |
| R6 | `(json['x'] as num?)?.toDouble()` repeats 30+ times | every model | Extract to `numFromJson(json, 'key')` helper |
| R7 | `core/services/auto_sync_engine.dart` line `_offset += _patientPageSize` BEFORE await | `patient_list_screen.dart:111` | Increment AFTER successful fetch, or restore on catch |
| R8 | Identical loading/error/empty patterns in 8+ screens | most lists | Extract `AsyncValueListView<T>` widget |
| R9 | Magic numbers: `width: 4, height: 28` accent bar | `patient_list_screen.dart`, `dashboard_*.dart` | Tiny `AiraSectionAccent` widget |
| R10 | Treatment form's `_productsUsed = []` typed as `List<Map<String, dynamic>>` | `treatment_form_screen.dart:150` | Define `class ProductUsageEntry` for type safety |
| R11 | `_AppBootstrap` no retry mechanism | `main.dart:112-122` | Wrap in a button "Try again" that re-runs `_bootstrap()` |
| R12 | `MaterialApp` nested twice in `AiraApp.build` | `app.dart:85,103` | Single `MaterialApp.router` with `redirect` for auth gate |

---

## 10. Documentation

| Finding | Sev | File | Note |
|---------|-----|------|------|
| `README.md` accurate but mentions migrations 001-009 (010 missing) | Low | `@/Users/faztycoding/Documents/GitHub/airaMD/README.md:35` | Update |
| `IMPLEMENTATION_PLAN_TH.md` + `IMPLEMENTATION_PLAN_TH_2.md` coexist | Low | repo root | Consolidate |
| `docs/CLIENT_HANDOFF.md` thorough and bilingual | ✅ | — | Last update covers Round 3 |
| `docs/DEMO_WALKTHROUGH.md` | ✅ | — | — |
| `docs/FEATURE_MATRIX.md` | ✅ | — | — |
| `.env.example` checked in | ✅ | — | — |
| No API docs for Supabase RPC contracts | Medium | — | Consider adding `supabase/RPC_CONTRACTS.md` listing every RPC + param + return |
| No troubleshooting guide for common errors | Low | — | "Failed to save treatment" → 5 likely causes, etc. |
| No release / versioning policy | Low | — | `pubspec.yaml` says version 1.0.0+6, no CHANGELOG |

---

## Prioritized Action Plan

### 🔴 Phase 1 — Critical Fixes (must fix BEFORE production rollout)

| # | Effort | File | Fix |
|---|--------|------|-----|
| P1.1 | 5 min | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/auth/login_screen.dart:127` | Replace hardcoded `emailRedirectTo` with `'${AppConstants.supabaseUrl}/auth/v1/verify'` |
| P1.2 | 10 min | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/config/supabase_config.dart:16-23` | Replace `assert()` with `if (...isEmpty) throw StateError(...)` so release builds also fail-fast |
| P1.3 | 30 min | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/auth/pin_lock_screen.dart` | Hash PIN with `crypt` or `bcrypt` (or sync with `staff.pin_hash` server-side) before storing. Bumps PIN format → small migration on first use |
| P1.4 | 1-2 hours | new migration `011_role_locked_writes.sql` | Lock down 12 tables to OWNER+DOCTOR for INSERT/UPDATE/DELETE (see §4.2 table). Patients write may stay open for receptionist |
| P1.5 | 30 min | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/auth/login_screen.dart:152-168` | Wrap clinic + staff create in a SECURITY DEFINER RPC `bootstrap_owner_signup(name, clinic_name)` that does both inserts in one transaction; drop dual policies |
| P1.6 | 30 min | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/core/repositories/patient_repository.dart:43-45` | Either add `is_active` to `patients` table or remove broken `softDelete` |
| P1.7 | 1 hour | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/core/repositories/inventory_repository.dart:24-68` | Manual inventory entries should call `deduct_stock_atomic` / additive update so `products.stock_quantity` stays consistent |
| P1.8 | 30 min | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/core/repositories/course_repository.dart:55-65` | Replace RMW with atomic `UPDATE courses SET sessions_used = sessions_used + 1 WHERE id = $id AND sessions_used < sessions_total RETURNING *` |

**Estimated total: ~5 hours.** Critical fixes block production deploy.

### 🟠 Phase 2 — High-Priority Refactors (within 1-2 sprints)

| # | Effort | File | Fix |
|---|--------|------|-----|
| P2.1 | 1 hour | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/core/services/offline_sync_service.dart` | Switch `enqueue` to a `Mutex` or use a single-writer model. Use UUID instead of `microsecondsSinceEpoch` for op id |
| P2.2 | 30 min | same | Add per-op file storage (one file per pending op in a directory) so iOS Keychain 4KB limit is no longer a single-key bottleneck |
| P2.3 | 2 hours | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/core/repositories/_helpers.dart` (new) | Extract shared `escapeLike`, `numFromJson`, `parseStringList` |
| P2.4 | 4 hours | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/calendar/calendar_screen.dart` | Split god-file (R1) |
| P2.5 | 4 hours | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/treatments/treatment_form_screen.dart` | Split god-file (R2) |
| P2.6 | 2 hours | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/app.dart` | Single `MaterialApp.router` with redirect-based auth/PIN gate |
| P2.7 | 1 hour | various | Replace 9 `throw Exception('...')` with typed `RepositoryException` subtypes |
| P2.8 | 2 hours | tests | Add Playwright-style integration tests against a Supabase test project for the 3 most critical flows: save treatment, sell course, bill patient |
| P2.9 | 1 hour | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/core/services/messaging_service.dart` | Document or vendor the `send-line-message` Edge Function — currently referenced but no source |
| P2.10 | 30 min | `@/Users/faztycoding/Documents/GitHub/airaMD/airamd_app/lib/features/dashboard/dashboard_screen.dart:17-21` | Add 250ms debounce to dashboard search |

**Estimated total: ~18 hours.**

### 🟡 Phase 3 — Nice-to-haves (when time permits)

| # | Effort | Item |
|---|--------|------|
| P3.1 | 2 hours | Color contrast audit + WCAG AA pass on `AiraColors.muted` text |
| P3.2 | 1 hour | Add semanticsLabel to icon-only `AiraTapEffect` call sites |
| P3.3 | 2 hours | Self-host primary Google Fonts as bundled assets |
| P3.4 | 2 hours | Add `--analyze-size` step + bundle-size budget check to CI |
| P3.5 | 4 hours | Dark mode theme |
| P3.6 | 4 hours | Migrate `flutter_lints` → `very_good_analysis` for stricter rules; clean up `deprecated_member_use: ignore` workaround |
| P3.7 | 1 hour | Replace 82 `debugPrint` with `Log.*` calls |
| P3.8 | 2 hours | Add `psql` migration test step in CI against ephemeral PG container |
| P3.9 | 1 hour | Consolidate `IMPLEMENTATION_PLAN_TH.md` + `_2.md` |
| P3.10 | 1 hour | Update README to mention migration 010, current test count, current Flutter version |
| P3.11 | 30 min | Remove duplicate `.flutter-plugins-dependencies 2`, empty `Medical Face Diagram/` folder |
| P3.12 | 2 hours | Multi-clinic doctor support (one staff row → multiple clinics via separate junction table) |
| P3.13 | 4 hours | Portrait support for small iPhone use case |
| P3.14 | 30 min | Schedule quarterly `flutter pub upgrade` + `pub audit` |
| P3.15 | 2 hours | Document API surface in `supabase/RPC_CONTRACTS.md` |
| P3.16 | 1 hour | Add `CHANGELOG.md` + release-tagging policy |

**Estimated total: ~30 hours.**

---

## Summary

**Production readiness:** **80%** — App is functionally complete with strong test coverage and recent hardening rounds. The 8 Critical issues in Phase 1 are concentrated and fixable in one focused day. After Phase 1, the app is genuinely production-ready.

**Strengths**
- Strong, consistent architecture (Riverpod + repository + sealed exceptions)
- Atomic RPCs for race-prone flows (treatment + inventory, stock deduction)
- 191 passing tests, `flutter analyze` clean
- Multi-tenant RLS on every table
- Audit log writes are SECURITY DEFINER (migration 010)
- Offline queue with RPC replay support
- Recent client-feedback fixes (HN year-prefix, atomic save, follow-up appt link, etc.)

**Risks**
- Hardcoded prod URL in source (#1)
- Release-build silent misconfiguration (#2)
- Plaintext PIN despite "secure storage" branding (#3)
- 12 RLS gaps that allow receptionist to mutate clinical data (#4)
- 6 god-files >1000 LOC slow future iteration

---

**Next step:** Tell me which Phase/items to fix first. I recommend tackling Phase 1 entirely (~5 hours) before client demo, then Phase 2 in the first post-demo sprint.
