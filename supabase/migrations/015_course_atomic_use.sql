-- ============================================================
-- 015_course_atomic_use.sql
--
-- Atomic "use a course session" increment.
--
-- The Flutter `CourseRepository.useSession()` did:
--
--   1. SELECT sessions_used FROM courses WHERE id = $id
--   2. Compute sessions_used + 1 + new status client-side
--   3. UPDATE courses SET sessions_used = ..., status = ...
--
-- which is a classic read-modify-write race. Two receptionists
-- marking the same session used in the same minute both saw the
-- pre-increment value and both wrote N+1 — one of the two uses
-- silently disappeared.
--
-- This RPC performs the increment atomically against the current
-- row value using Postgres' RETURNING clause, so concurrent calls
-- serialise naturally via MVCC + row lock.
-- ============================================================

CREATE OR REPLACE FUNCTION use_course_session(p_course_id UUID)
RETURNS courses
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row     courses%ROWTYPE;
  v_total   INT;
  v_new     INT;
  v_status  course_status;
  v_uid     UUID := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '28000';
  END IF;

  -- FOR UPDATE holds the row lock until COMMIT so a concurrent
  -- RPC blocks here instead of reading stale sessions_used.
  SELECT * INTO v_row FROM courses WHERE id = p_course_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'course % not found', p_course_id USING ERRCODE = 'P0002';
  END IF;

  -- Clinical staff / owner gate — mirrors migration 011 RLS.
  IF NOT EXISTS (
    SELECT 1 FROM staff s
    WHERE s.user_id = v_uid
      AND s.clinic_id = v_row.clinic_id
      AND s.is_active = TRUE
      AND s.role IN ('OWNER', 'DOCTOR')
  ) THEN
    RAISE EXCEPTION 'forbidden: course usage requires OWNER or DOCTOR'
      USING ERRCODE = '42501';
  END IF;

  v_total := COALESCE(v_row.sessions_total,
                       v_row.sessions_bought + v_row.sessions_bonus);
  v_new   := v_row.sessions_used + 1;

  IF v_new > v_total THEN
    RAISE EXCEPTION 'course_exhausted: % of % sessions already used',
      v_row.sessions_used, v_total
      USING ERRCODE = 'P0001';
  END IF;

  -- Derive the new status in one place — client no longer does it.
  IF v_new >= v_total THEN
    v_status := 'COMPLETED';
  ELSIF v_total - v_new <= 1 THEN
    v_status := 'LOW';
  ELSE
    v_status := v_row.status;
  END IF;

  UPDATE courses
  SET sessions_used = v_new,
      status        = v_status,
      updated_at    = now()
  WHERE id = p_course_id
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION use_course_session(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION use_course_session(UUID) TO authenticated;

COMMENT ON FUNCTION use_course_session(UUID) IS
  'Atomic increment of courses.sessions_used with auto-status update and role gate. Use in place of client-side read-modify-write.';
