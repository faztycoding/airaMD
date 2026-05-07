-- ============================================================
-- Migration 016: Bidirectional treatment ↔ follow-up appointment link
--
-- Problem: treatment_form creates a follow-up appointment but there is
-- no persistent link from the treatment record back to that appointment,
-- and no link from the appointment back to the originating treatment.
-- Client request: "ทำให้มันลิงค์กันได้ไหมนะคะ" (can you link them?)
--
-- Solution:
--   treatment_records.follow_up_appointment_id → appointments.id
--   appointments.treatment_record_id           → treatment_records.id
--
-- Both columns are NULLABLE so existing rows are unaffected.
-- Idempotent: wrapped in IF NOT EXISTS guards.
-- ============================================================

-- 1. Add follow_up_appointment_id to treatment_records
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'treatment_records'
      AND column_name = 'follow_up_appointment_id'
  ) THEN
    ALTER TABLE treatment_records
      ADD COLUMN follow_up_appointment_id UUID
        REFERENCES appointments(id) ON DELETE SET NULL;

    COMMENT ON COLUMN treatment_records.follow_up_appointment_id IS
      'The follow-up appointment auto-created when this treatment was saved. '
      'NULL if no follow-up was scheduled.';
  END IF;
END $$;

-- 2. Add treatment_record_id to appointments
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'appointments'
      AND column_name = 'treatment_record_id'
  ) THEN
    ALTER TABLE appointments
      ADD COLUMN treatment_record_id UUID
        REFERENCES treatment_records(id) ON DELETE SET NULL;

    COMMENT ON COLUMN appointments.treatment_record_id IS
      'The treatment record that triggered the creation of this follow-up '
      'appointment. NULL for manually-booked appointments.';
  END IF;
END $$;

-- 3. Indexes for common lookup patterns
CREATE INDEX IF NOT EXISTS idx_treatment_followup_appt
  ON treatment_records(follow_up_appointment_id)
  WHERE follow_up_appointment_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_appt_treatment_record
  ON appointments(treatment_record_id)
  WHERE treatment_record_id IS NOT NULL;
