-- Migration 017: Add license_number to staff
-- Required for OWNER/DOCTOR roles. Displayed under doctor name in
-- treatment form so treating doctor + เลข ว. are visible together.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'staff' AND column_name = 'license_number'
  ) THEN
    ALTER TABLE staff ADD COLUMN license_number TEXT;
    COMMENT ON COLUMN staff.license_number IS
      'Medical license number (เลข ว.) — required for OWNER/DOCTOR roles';
  END IF;
END $$;
