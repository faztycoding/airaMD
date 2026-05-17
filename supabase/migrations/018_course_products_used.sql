-- Migration 018: Add products_used JSONB + treatment_category to courses
--
-- Per client request: when creating a course we want to attach the
-- products/devices used per category (Injectable / Laser / Treatment),
-- mirroring how treatment_records.products_used works.
--
-- products_used is a JSON array of { product_id, name, quantity }.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'courses' AND column_name = 'products_used'
  ) THEN
    ALTER TABLE courses
      ADD COLUMN products_used JSONB NOT NULL DEFAULT '[]'::jsonb;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'courses' AND column_name = 'treatment_category'
  ) THEN
    ALTER TABLE courses
      ADD COLUMN treatment_category TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'courses' AND column_name = 'responsible_doctor_id'
  ) THEN
    ALTER TABLE courses
      ADD COLUMN responsible_doctor_id UUID
        REFERENCES staff(id) ON DELETE SET NULL;
  END IF;
END $$;

COMMENT ON COLUMN courses.products_used IS
  'JSON array of products consumed per session. Format: [{product_id, name, quantity}]';
COMMENT ON COLUMN courses.treatment_category IS
  'Course category: injectable | laser | treatment | anti_aging | skincare | other';
