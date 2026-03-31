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
airamd/
├── lib/                    # Flutter application source
│   ├── config/             # Theme, routes, constants
│   ├── core/               # Auth, localization, services, shared widgets
│   ├── features/           # Feature modules (dashboard, patients, etc.)
│   └── models/             # Data models
├── supabase/
│   ├── migrations/         # Database schema SQL
│   └── seed.sql            # Demo data
├── IMPLEMENTATION_PLAN.md  # Full feature specification
└── README.md
```

## Getting Started

### Prerequisites
- Flutter SDK 3.x
- Dart SDK 3.x
- Supabase account (free tier)
- Firebase project (for push notifications)

### Setup
1. Clone the repository
2. Run `flutter pub get`
3. Create a Supabase project and run migrations from `supabase/migrations/`
4. Configure `lib/config/supabase_config.dart` with your Supabase URL and anon key
5. Run `flutter run`

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
