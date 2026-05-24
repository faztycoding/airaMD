-- Migration 020: Add machines_used JSONB column to treatment_records
--
-- Per client feedback (May 24, 2026): laser/device treatments often use
-- multiple machines in a single session, each with its own parameters.
-- The existing scalar columns (device, energy, pulse_spot, total_shots)
-- only capture ONE machine's details; this column lets us record a list
-- of {name, parameters} pairs for additional machines.
--
-- Backwards-compatible: existing rows default to '[]'::jsonb so legacy
-- reads keep working. The pre-existing device/energy/pulse_spot/total_shots
-- columns are kept untouched — this is additive only.

ALTER TABLE treatment_records
  ADD COLUMN IF NOT EXISTS machines_used JSONB NOT NULL DEFAULT '[]'::jsonb;

COMMENT ON COLUMN treatment_records.machines_used IS
  'Array of {name: text, parameters: text} entries for additional machines used in a laser/device session. Added in migration 020 per Round 4 client feedback.';
