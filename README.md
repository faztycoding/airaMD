# airaMD — Clinic Management App

ระบบจัดการคลินิกความงามครบวงจร พัฒนาด้วย Flutter + Supabase

## Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter 3.x (Dart) |
| **Backend** | Supabase (PostgreSQL + Auth + Storage + Edge Functions) |
| **State Management** | Riverpod |
| **Navigation** | GoRouter |
| **Target Platform** | iPad / Tablet (primary), iOS & Android (secondary) |

## Project Structure

```
airaMD/
├── airamd_app/                       # Flutter application
│   ├── lib/
│   │   ├── config/                   # Theme, routes, constants, Supabase init
│   │   ├── core/
│   │   │   ├── localization/         # Bilingual TH / EN strings
│   │   │   ├── models/               # Data models
│   │   │   ├── providers/            # Riverpod providers (DI / state)
│   │   │   ├── repositories/         # Supabase data access layer
│   │   │   ├── services/             # Cross-feature services (sync, push, safety)
│   │   │   └── widgets/              # Shared premium widgets
│   │   ├── features/                 # Feature modules (auth, calendar, courses,
│   │   │                             #   dashboard, financial, patients,
│   │   │                             #   settings, treatments)
│   │   └── main.dart
│   └── test/                         # Unit / widget / integration tests
├── supabase/
│   └── migrations/                   # Database schema SQL (001 → 009)
├── docs/                             # Demo walkthrough, feature matrix, handoff
├── .github/workflows/ci.yml          # Lint / analyze / test / build pipeline
├── IMPLEMENTATION_PLAN_TH.md         # Full feature specification (Thai)
└── README.md
```

## Getting Started

### Prerequisites
- Flutter SDK **3.41.x** (matches CI; older versions may miss
  `RawGestureDetector` improvements used by the face diagram)
- Dart SDK 3.x
- Supabase project (free tier is fine for dev)
- Firebase project (for push notifications)

### Setup

```bash
# 1. Clone & enter the app directory
git clone <repo-url> && cd airaMD/airamd_app

# 2. Install Flutter dependencies
flutter pub get

# 3. Apply the database schema to your Supabase project
#    (run all files under ../supabase/migrations/ in numeric order, 001 → 009)
#    e.g. with the Supabase CLI:
#       supabase link --project-ref <ref>
#       supabase db push

# 4. Run the app — credentials are passed at build time via --dart-define,
#    NOT hard-coded into source.
flutter run \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key> \
  --dart-define=ENV=development
```

The dashboard will not show data unless your authenticated user has a
matching row in the `staff` table linking them to a clinic — see
`supabase/migrations/004_drop_dev_rls.sql` for the bootstrap policy that
allows first-time clinic + staff creation.

## Features

### Phase 1 — Digital Clinic
- Patient management (EMR)
- Appointment scheduling with doctor shift management
- Treatment recording (SOAP notes)
- Face diagram drawing
- Before/After photo comparison (synchronized zoom)
- Consent forms with digital signature
- PIN Lock + Biometric security

### Phase 2 — Business Logic
- Course system (Buy X Get Y)
- Financial tracking (payments, outstanding balances)
- Price list management
- Inventory control with unit conversion

### Phase 3 — Smart System
- Treatment warning system
- LINE / WhatsApp messaging integration
- Push notifications
- Offline sync indicator

## Design

Warm beige/brown luxury theme optimized for iPad usage. Bilingual (Thai/English).

## License

Proprietary — All rights reserved by the client.
