---
description: Run the final client demo and handoff workflow for airaMD
---

1. Open `docs/DEMO_WALKTHROUGH.md` and review the recommended presentation order.
2. Open `docs/FEATURE_MATRIX.md` and confirm the talking points for ready-now scope versus future enhancement scope.
3. Open `docs/CLIENT_HANDOFF.md` and use the handoff checklist before the meeting.
4. Run code health verification.
// turbo
5. Run `flutter analyze --no-fatal-infos --no-fatal-warnings` from the `airamd_app` project root.
6. Prepare demo seed data:
   - at least 1 patient
   - at least 1 appointment with assigned doctor
   - at least 1 product with stock and expiry
   - at least 1 treatment-linked inventory deduction example
7. Demo in this order:
   - Dashboard
   - Patients
   - Calendar
   - Treatment from appointment
   - Patient profile
   - Messaging
   - Financial
   - Inventory
   - Settings
8. Close by highlighting:
   - doctor ownership
   - appointment-to-treatment completion loop
   - permission-aware design
   - inventory safeguards
   - future enhancements are already clearly identified and separated from current scope
