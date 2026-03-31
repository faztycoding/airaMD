-- ═══════════════════════════════════════════════════════════════════
-- Migration 002: Update preferred_channel enum + add facebook/instagram columns
-- ═══════════════════════════════════════════════════════════════════

-- 1) Add new enum values to preferred_channel
ALTER TYPE preferred_channel ADD VALUE IF NOT EXISTS 'FACEBOOK';
ALTER TYPE preferred_channel ADD VALUE IF NOT EXISTS 'INSTAGRAM';
ALTER TYPE preferred_channel ADD VALUE IF NOT EXISTS 'PHONE';

-- 2) Add facebook and instagram columns to patients table
ALTER TABLE patients ADD COLUMN IF NOT EXISTS facebook TEXT;
ALTER TABLE patients ADD COLUMN IF NOT EXISTS instagram TEXT;

-- 3) Migrate existing WHATSAPP / BOTH preferences to NONE (since those are removed)
UPDATE patients SET preferred_channel = 'NONE' WHERE preferred_channel IN ('WHATSAPP', 'BOTH');
