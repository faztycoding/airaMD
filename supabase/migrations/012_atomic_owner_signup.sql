-- ============================================================
-- 012_atomic_owner_signup.sql
--
-- Atomic owner signup. Replaces the two-step client-side signup
-- that ran:
--
--   1. INSERT INTO clinics ...
--   2. INSERT INTO staff ... (role = OWNER)
--
-- from `login_screen.dart`. That sequence wasn't transactional —
-- if step 2 failed (network blip, duplicate user_id, RLS) we were
-- left with an orphan clinic no one could log into.
--
-- This RPC wraps both inserts in a single transaction under
-- SECURITY DEFINER so:
--   * The whole signup either succeeds or neither row survives.
--   * The caller's `auth.uid()` is used verbatim — no way to
--     create a staff row for someone else.
--   * The function can be narrowly granted to authenticated only.
--
-- The function is idempotent: running it twice with the same
-- authenticated user returns the existing clinic/staff pair so
-- client retries don't create duplicates.
-- ============================================================

CREATE OR REPLACE FUNCTION bootstrap_owner_signup(
  p_full_name TEXT,
  p_clinic_name TEXT
)
RETURNS TABLE (
  clinic_id UUID,
  staff_id  UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid       UUID := auth.uid();
  v_existing  RECORD;
  v_clinic_id UUID;
  v_staff_id  UUID;
  v_trim_name TEXT;
  v_trim_clinic TEXT;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  v_trim_name   := NULLIF(BTRIM(COALESCE(p_full_name, '')), '');
  v_trim_clinic := NULLIF(BTRIM(COALESCE(p_clinic_name, '')), '');

  IF v_trim_name IS NULL THEN
    RAISE EXCEPTION 'Full name required' USING ERRCODE = '22023';
  END IF;

  -- Idempotency: if this user already has an active OWNER staff row,
  -- return it instead of creating a second clinic/staff pair.
  SELECT s.clinic_id, s.id INTO v_existing
  FROM staff s
  WHERE s.user_id = v_uid
    AND s.role = 'OWNER'
    AND s.is_active = TRUE
  ORDER BY s.created_at ASC
  LIMIT 1;

  IF FOUND THEN
    clinic_id := v_existing.clinic_id;
    staff_id  := v_existing.id;
    RETURN NEXT;
    RETURN;
  END IF;

  -- Insert clinic first — then staff pointing at it. If the staff
  -- insert fails, the enclosing transaction rolls back the clinic
  -- row automatically, so no orphan row survives.
  INSERT INTO clinics (name)
  VALUES (COALESCE(v_trim_clinic, v_trim_name || ' Clinic'))
  RETURNING id INTO v_clinic_id;

  INSERT INTO staff (clinic_id, user_id, full_name, role, is_active)
  VALUES (v_clinic_id, v_uid, v_trim_name, 'OWNER', TRUE)
  RETURNING id INTO v_staff_id;

  clinic_id := v_clinic_id;
  staff_id  := v_staff_id;
  RETURN NEXT;
END;
$$;

-- Lock down execution: only authenticated sessions may call this.
REVOKE ALL ON FUNCTION bootstrap_owner_signup(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION bootstrap_owner_signup(TEXT, TEXT) TO authenticated;

COMMENT ON FUNCTION bootstrap_owner_signup(TEXT, TEXT) IS
  'Atomic owner+clinic signup. Returns (clinic_id, staff_id). Idempotent — reruns return the existing OWNER staff row.';
