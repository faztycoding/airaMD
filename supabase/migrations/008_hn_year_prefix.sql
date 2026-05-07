-- ============================================================
-- 008_hn_year_prefix.sql
-- HN format: C-YYYY-NNNNN (year-prefixed, sequence resets per year/clinic)
--
-- Old format (C-NNNNN) is preserved for already-issued patients.
-- New patients receive the new year-prefixed format.
-- ============================================================

CREATE OR REPLACE FUNCTION generate_patient_hn()
RETURNS TRIGGER AS $$
DECLARE
  current_year INT;
  next_num INT;
BEGIN
  IF NEW.hn IS NOT NULL THEN
    RETURN NEW;
  END IF;

  current_year := EXTRACT(YEAR FROM COALESCE(NEW.created_at, now()))::INT;

  -- Sequence is per-clinic and per-year using CE (Christian/Gregorian) year.
  -- Match HN like: 'C-2025-00001' and extract the trailing number.
  SELECT COALESCE(
           MAX(
             CASE
               WHEN hn ~ ('^C-' || current_year::TEXT || '-[0-9]+$')
               THEN CAST(SUBSTRING(hn FROM ('^C-' || current_year::TEXT || '-([0-9]+)$')) AS INT)
               ELSE 0
             END
           ),
           0
         ) + 1
    INTO next_num
    FROM patients
   WHERE clinic_id = NEW.clinic_id;

  NEW.hn := 'C-' || current_year::TEXT || '-' || LPAD(next_num::TEXT, 5, '0');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- (Trigger `patients_auto_hn` already exists from 001_initial_schema.sql
-- and references this function by name, so no trigger change is needed.)
