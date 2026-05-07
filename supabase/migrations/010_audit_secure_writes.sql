-- ============================================================
-- Migration 010: Tamper-resistant audit log writes
--
-- Why:
--   The previous policy allowed any authenticated client in a clinic to
--   INSERT directly into audit_logs. That meant a malicious / buggy client
--   could:
--     * spoof user_id to blame another staff member
--     * back-date or future-date the `timestamp`
--     * inject fake actions to mislead PDPA reviewers
--     * skip writing audit rows entirely
--
--   This migration removes direct INSERT access on audit_logs and routes all
--   writes through a SECURITY DEFINER function that:
--     * verifies the caller is a member of `p_clinic_id` (RLS-equivalent)
--     * forces `user_id` to the row in `staff` linked to auth.uid()
--     * forces `timestamp = now()`
--   so the only fields the client controls are the ones it should: action,
--   entity_type, entity_id, old_data, new_data.
--
-- All statements idempotent.
-- ============================================================

-- ── 1. Drop the broad write policy from migration 005 ─────────
DROP POLICY IF EXISTS "Audit logs write own clinic" ON audit_logs;

-- ── 2. SECURITY DEFINER write function ────────────────────────
CREATE OR REPLACE FUNCTION record_audit_log(
  p_clinic_id   UUID,
  p_action      TEXT,
  p_entity_type TEXT  DEFAULT NULL,
  p_entity_id   UUID  DEFAULT NULL,
  p_old_data    JSONB DEFAULT NULL,
  p_new_data    JSONB DEFAULT NULL
)
RETURNS audit_logs
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_row     audit_logs;
BEGIN
  -- The caller must belong to the target clinic. We re-implement the RLS
  -- check explicitly because SECURITY DEFINER bypasses RLS on the audit
  -- table — without this, any logged-in user could write to any clinic.
  IF NOT EXISTS (
    SELECT 1
      FROM staff
     WHERE user_id = (SELECT auth.uid())
       AND is_active = true
       AND clinic_id = p_clinic_id
  ) THEN
    RAISE EXCEPTION 'audit_log_forbidden'
      USING ERRCODE = '42501', -- insufficient_privilege
            HINT    = 'Caller is not an active member of clinic';
  END IF;

  -- Resolve the staff row that owns this auth user inside the target clinic
  -- so user_id always reflects WHO actually performed the action — not
  -- whatever the client claimed.
  SELECT id
    INTO v_user_id
    FROM staff
   WHERE user_id = (SELECT auth.uid())
     AND clinic_id = p_clinic_id
     AND is_active = true
   LIMIT 1;

  INSERT INTO audit_logs (
    clinic_id, user_id, action, entity_type, entity_id,
    old_data, new_data, timestamp
  )
  VALUES (
    p_clinic_id, v_user_id, p_action, p_entity_type, p_entity_id,
    p_old_data, p_new_data, now()
  )
  RETURNING * INTO v_row;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION record_audit_log(UUID, TEXT, TEXT, UUID, JSONB, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION record_audit_log(UUID, TEXT, TEXT, UUID, JSONB, JSONB) TO authenticated;

-- ── 3. Lock down direct INSERT, keep SELECT for the clinic ────
-- SELECT policy already exists from migration 005 ("Audit logs read own
-- clinic"). We add an *empty* INSERT policy so PostgREST returns 401
-- instead of "no policy" 500 errors when something tries to insert
-- directly. UPDATE/DELETE remain forbidden (no policy at all).
DROP POLICY IF EXISTS "Audit logs no direct write" ON audit_logs;
CREATE POLICY "Audit logs no direct write" ON audit_logs
  FOR INSERT
  WITH CHECK (false);

-- ── 4. Revoke direct table grants from authenticated role ─────
-- This is the actual lock — even if a future migration accidentally adds a
-- permissive INSERT policy, the role lacks the underlying table privilege.
REVOKE INSERT, UPDATE, DELETE ON audit_logs FROM authenticated;
GRANT SELECT ON audit_logs TO authenticated;

-- ── 5. Helpful comment for future maintainers ────────────────
COMMENT ON FUNCTION record_audit_log IS
  'Tamper-resistant audit log writer. user_id and timestamp are forced from '
  'auth.uid() / now() so the client cannot spoof them. Direct INSERT into '
  'audit_logs is REVOKEd from `authenticated` — write only through this '
  'function.';
