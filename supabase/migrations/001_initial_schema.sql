-- ============================================================
-- AIRAMD CLINIC MANAGEMENT APP — Complete Database Schema
-- Supabase PostgreSQL Migration
-- Version: 1.0
-- Date: 2026-03-23
-- ============================================================

-- ============================================================
-- ENUMS (DROP + CREATE for safe re-run)
-- ============================================================

DROP TYPE IF EXISTS staff_role CASCADE;
DROP TYPE IF EXISTS schedule_status CASCADE;
DROP TYPE IF EXISTS gender_type CASCADE;
DROP TYPE IF EXISTS smoking_type CASCADE;
DROP TYPE IF EXISTS alcohol_type CASCADE;
DROP TYPE IF EXISTS patient_status CASCADE;
DROP TYPE IF EXISTS preferred_channel CASCADE;
DROP TYPE IF EXISTS appointment_status CASCADE;
DROP TYPE IF EXISTS service_category CASCADE;
DROP TYPE IF EXISTS doctor_fee_type CASCADE;
DROP TYPE IF EXISTS treatment_category CASCADE;
DROP TYPE IF EXISTS treatment_response CASCADE;
DROP TYPE IF EXISTS commission_status CASCADE;
DROP TYPE IF EXISTS photo_type CASCADE;
DROP TYPE IF EXISTS diagram_view CASCADE;
DROP TYPE IF EXISTS product_category CASCADE;
DROP TYPE IF EXISTS inventory_transaction_type CASCADE;
DROP TYPE IF EXISTS course_status CASCADE;
DROP TYPE IF EXISTS financial_type CASCADE;
DROP TYPE IF EXISTS payment_method CASCADE;
DROP TYPE IF EXISTS message_channel CASCADE;
DROP TYPE IF EXISTS message_template_type CASCADE;
DROP TYPE IF EXISTS message_status CASCADE;

CREATE TYPE staff_role AS ENUM ('OWNER', 'DOCTOR', 'RECEPTIONIST');
CREATE TYPE schedule_status AS ENUM ('ON_DUTY', 'LEAVE', 'HALF_DAY');
CREATE TYPE gender_type AS ENUM ('M', 'F', 'OTHER');
CREATE TYPE smoking_type AS ENUM ('NONE', 'OCCASIONAL', 'REGULAR');
CREATE TYPE alcohol_type AS ENUM ('NONE', 'OCCASIONAL', 'REGULAR');
CREATE TYPE patient_status AS ENUM ('NORMAL', 'VIP', 'STAR');
CREATE TYPE preferred_channel AS ENUM ('LINE', 'WHATSAPP', 'BOTH', 'NONE');
CREATE TYPE appointment_status AS ENUM ('NEW', 'CONFIRMED', 'FOLLOW_UP', 'COMPLETED', 'CANCELLED', 'NO_SHOW');
CREATE TYPE service_category AS ENUM ('HA', 'INJECTABLE', 'LASER', 'TREATMENT', 'OTHER');
CREATE TYPE doctor_fee_type AS ENUM ('FIXED_AMOUNT', 'PERCENTAGE', 'NONE');
CREATE TYPE treatment_category AS ENUM ('INJECTABLE', 'LASER', 'TREATMENT', 'OTHER');
CREATE TYPE treatment_response AS ENUM ('IMPROVED', 'STABLE', 'WORSE', 'N_A');
CREATE TYPE commission_status AS ENUM ('PENDING', 'PAID');
CREATE TYPE photo_type AS ENUM ('BEFORE', 'AFTER_1M', 'AFTER_3M', 'AFTER_6M', 'FOLLOW_UP', 'OTHER');
CREATE TYPE diagram_view AS ENUM ('FRONT', 'SIDE', 'LIP_ZONE');
CREATE TYPE product_category AS ENUM ('BOTOX', 'FILLER', 'BIOSTIMULATOR', 'POLYNUCLEOTIDE', 'SKINBOOSTER', 'LASER', 'OTHER');
CREATE TYPE inventory_transaction_type AS ENUM ('STOCK_IN', 'USED', 'WASTAGE', 'ADJUSTMENT');
CREATE TYPE course_status AS ENUM ('ACTIVE', 'LOW', 'COMPLETED', 'EXPIRED');
CREATE TYPE financial_type AS ENUM ('CHARGE', 'PAYMENT', 'REFUND', 'ADJUSTMENT');
CREATE TYPE payment_method AS ENUM ('CASH', 'TRANSFER', 'CREDIT_CARD', 'DEBIT', 'OTHER');
CREATE TYPE message_channel AS ENUM ('LINE', 'WHATSAPP');
CREATE TYPE message_template_type AS ENUM ('APPOINTMENT', 'CONFIRMATION', 'AFTER_CARE', 'PROMOTION', 'CUSTOM');
CREATE TYPE message_status AS ENUM ('SENT', 'DELIVERED', 'FAILED', 'PENDING');

-- ============================================================
-- DROP ALL EXISTING TABLES (for safe re-run)
-- ============================================================

DROP TABLE IF EXISTS treatment_rules CASCADE;
DROP TABLE IF EXISTS digital_notepads CASCADE;
DROP TABLE IF EXISTS audit_logs CASCADE;
DROP TABLE IF EXISTS message_logs CASCADE;
DROP TABLE IF EXISTS financial_records CASCADE;
DROP TABLE IF EXISTS course_sessions CASCADE;
DROP TABLE IF EXISTS courses CASCADE;
DROP TABLE IF EXISTS inventory_transactions CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS consent_forms CASCADE;
DROP TABLE IF EXISTS consent_form_templates CASCADE;
DROP TABLE IF EXISTS face_diagrams CASCADE;
DROP TABLE IF EXISTS patient_photos CASCADE;
DROP TABLE IF EXISTS treatment_records CASCADE;
DROP TABLE IF EXISTS services CASCADE;
DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS patients CASCADE;
DROP TABLE IF EXISTS staff_schedules CASCADE;
DROP TABLE IF EXISTS staff CASCADE;
DROP TABLE IF EXISTS clinics CASCADE;

DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS generate_patient_hn() CASCADE;
DROP FUNCTION IF EXISTS get_my_clinic_ids() CASCADE;

-- ============================================================
-- HELPER: auto-update updated_at trigger
-- ============================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 1. CLINICS
-- ============================================================

CREATE TABLE clinics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  logo_url TEXT,
  address TEXT,
  phone TEXT,
  line_oa_id TEXT,
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TRIGGER clinics_updated_at
  BEFORE UPDATE ON clinics
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 2. STAFF (Doctors & Employees)
-- ============================================================

CREATE TABLE staff (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  full_name TEXT NOT NULL,
  nickname TEXT,
  role staff_role NOT NULL DEFAULT 'DOCTOR',
  base_salary DECIMAL(12,2),
  is_active BOOLEAN NOT NULL DEFAULT true,
  pin_hash TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_staff_clinic ON staff(clinic_id);
CREATE INDEX idx_staff_user ON staff(user_id);

CREATE TRIGGER staff_updated_at
  BEFORE UPDATE ON staff
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 3. STAFF SCHEDULES (Shift / Roster Management)
-- ============================================================

CREATE TABLE staff_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status schedule_status NOT NULL DEFAULT 'ON_DUTY',
  start_time TIME,
  end_time TIME,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(staff_id, date)
);

CREATE INDEX idx_schedule_clinic_date ON staff_schedules(clinic_id, date);
CREATE INDEX idx_schedule_staff_date ON staff_schedules(staff_id, date);

-- ============================================================
-- 4. PATIENTS
-- ============================================================

CREATE TABLE patients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  hn TEXT,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  nickname TEXT,
  date_of_birth DATE,
  gender gender_type,
  national_id TEXT,
  passport_no TEXT,
  phone TEXT,
  line_id TEXT,
  whatsapp TEXT,
  email TEXT,
  address TEXT,
  status patient_status NOT NULL DEFAULT 'NORMAL',
  drug_allergies TEXT[] DEFAULT '{}',
  allergy_symptoms TEXT,
  medical_conditions TEXT[] DEFAULT '{}',
  smoking smoking_type DEFAULT 'NONE',
  alcohol alcohol_type DEFAULT 'NONE',
  is_using_retinoids BOOLEAN DEFAULT false,
  is_on_anticoagulant BOOLEAN DEFAULT false,
  preferred_channel preferred_channel DEFAULT 'NONE',
  profile_photo_url TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE UNIQUE INDEX idx_patient_hn ON patients(clinic_id, hn) WHERE hn IS NOT NULL;
CREATE INDEX idx_patient_clinic ON patients(clinic_id);
CREATE INDEX idx_patient_name ON patients(clinic_id, first_name, last_name);
CREATE INDEX idx_patient_nickname ON patients(clinic_id, nickname);

CREATE TRIGGER patients_updated_at
  BEFORE UPDATE ON patients
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto-generate HN on insert
CREATE OR REPLACE FUNCTION generate_patient_hn()
RETURNS TRIGGER AS $$
DECLARE
  next_num INT;
BEGIN
  IF NEW.hn IS NULL THEN
    SELECT COALESCE(MAX(CAST(SUBSTRING(hn FROM 3) AS INT)), 0) + 1
    INTO next_num
    FROM patients
    WHERE clinic_id = NEW.clinic_id AND hn LIKE 'C-%';
    NEW.hn := 'C-' || LPAD(next_num::TEXT, 5, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER patients_auto_hn
  BEFORE INSERT ON patients
  FOR EACH ROW EXECUTE FUNCTION generate_patient_hn();

-- ============================================================
-- 5. APPOINTMENTS
-- ============================================================

CREATE TABLE appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  doctor_id UUID REFERENCES staff(id) ON DELETE SET NULL,
  date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME,
  status appointment_status NOT NULL DEFAULT 'NEW',
  treatment_type TEXT,
  notes TEXT,
  reminder_sent BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_appt_clinic_date ON appointments(clinic_id, date);
CREATE INDEX idx_appt_patient ON appointments(patient_id);
CREATE INDEX idx_appt_doctor_date ON appointments(doctor_id, date);

CREATE TRIGGER appointments_updated_at
  BEFORE UPDATE ON appointments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 6. SERVICES (Treatments / Procedures — Price List)
-- ============================================================

CREATE TABLE services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category service_category NOT NULL DEFAULT 'OTHER',
  default_price DECIMAL(12,2),
  doctor_fee_type doctor_fee_type DEFAULT 'NONE',
  doctor_fee_value DECIMAL(12,2),
  estimated_cost DECIMAL(12,2),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_services_clinic ON services(clinic_id);

CREATE TRIGGER services_updated_at
  BEFORE UPDATE ON services
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 7. TREATMENT RECORDS
-- ============================================================

CREATE TABLE treatment_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  doctor_id UUID REFERENCES staff(id) ON DELETE SET NULL,
  appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
  date TIMESTAMPTZ NOT NULL DEFAULT now(),
  category treatment_category NOT NULL DEFAULT 'OTHER',
  treatment_name TEXT NOT NULL,
  chief_complaint TEXT,
  objective TEXT,
  assessment TEXT,
  plan TEXT,
  vitals JSONB DEFAULT '{}',
  device TEXT,
  energy TEXT,
  pulse_spot TEXT,
  total_shots TEXT,
  products_used JSONB DEFAULT '[]',
  actual_units_used DECIMAL(10,4),
  response_to_previous treatment_response DEFAULT 'N_A',
  adverse_events TEXT[] DEFAULT '{}',
  instructions TEXT[] DEFAULT '{}',
  follow_up_date DATE,
  follow_up_time TIME,
  diagram_url TEXT,
  notes TEXT,
  commission_status commission_status DEFAULT 'PENDING',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_treatment_clinic ON treatment_records(clinic_id);
CREATE INDEX idx_treatment_patient ON treatment_records(patient_id);
CREATE INDEX idx_treatment_doctor ON treatment_records(doctor_id);
CREATE INDEX idx_treatment_date ON treatment_records(clinic_id, date DESC);

CREATE TRIGGER treatment_records_updated_at
  BEFORE UPDATE ON treatment_records
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 8. PATIENT PHOTOS
-- ============================================================

CREATE TABLE patient_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  treatment_record_id UUID REFERENCES treatment_records(id) ON DELETE SET NULL,
  image_type photo_type NOT NULL DEFAULT 'OTHER',
  storage_path TEXT NOT NULL,
  thumbnail_path TEXT,
  treatment_date DATE,
  description TEXT,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_photos_patient ON patient_photos(patient_id);
CREATE INDEX idx_photos_clinic ON patient_photos(clinic_id);

-- ============================================================
-- 9. FACE DIAGRAMS
-- ============================================================

CREATE TABLE face_diagrams (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  treatment_record_id UUID REFERENCES treatment_records(id) ON DELETE SET NULL,
  image_url TEXT NOT NULL,
  view_type diagram_view NOT NULL DEFAULT 'FRONT',
  strokes_data JSONB DEFAULT '[]',
  markers_data JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_diagrams_patient ON face_diagrams(patient_id);

-- ============================================================
-- 10. CONSENT FORM TEMPLATES
-- ============================================================

CREATE TABLE consent_form_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT,
  content TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_consent_templates_clinic ON consent_form_templates(clinic_id);

CREATE TRIGGER consent_templates_updated_at
  BEFORE UPDATE ON consent_form_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 11. CONSENT FORMS (Signed)
-- ============================================================

CREATE TABLE consent_forms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  treatment_record_id UUID REFERENCES treatment_records(id) ON DELETE SET NULL,
  form_template_id UUID REFERENCES consent_form_templates(id) ON DELETE SET NULL,
  signature_url TEXT NOT NULL,
  signed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  witness_name TEXT,
  pdf_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_consent_forms_patient ON consent_forms(patient_id);

-- ============================================================
-- 12. PRODUCTS (Inventory / Product Library)
-- ============================================================

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  brand TEXT,
  category product_category NOT NULL DEFAULT 'OTHER',
  unit TEXT NOT NULL DEFAULT 'U',
  unit_cost DECIMAL(12,2),
  default_price DECIMAL(12,2),
  stock_quantity DECIMAL(12,4) DEFAULT 0,
  stock_per_container DECIMAL(12,4),
  min_stock_alert INT,
  expiry_date DATE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_products_clinic ON products(clinic_id);
CREATE INDEX idx_products_category ON products(clinic_id, category);

CREATE TRIGGER products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 13. INVENTORY TRANSACTIONS
-- ============================================================

CREATE TABLE inventory_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  treatment_record_id UUID REFERENCES treatment_records(id) ON DELETE SET NULL,
  patient_id UUID REFERENCES patients(id) ON DELETE SET NULL,
  transaction_type inventory_transaction_type NOT NULL,
  quantity DECIMAL(12,4) NOT NULL,
  unit TEXT,
  batch_no TEXT,
  expiry_date DATE,
  notes TEXT,
  created_by UUID REFERENCES staff(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_inv_tx_product ON inventory_transactions(product_id);
CREATE INDEX idx_inv_tx_clinic ON inventory_transactions(clinic_id);

-- ============================================================
-- 14. COURSES
-- ============================================================

CREATE TABLE courses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  service_id UUID REFERENCES services(id) ON DELETE SET NULL,
  price DECIMAL(12,2),
  sessions_bought INT NOT NULL DEFAULT 1,
  sessions_bonus INT NOT NULL DEFAULT 0,
  sessions_used INT NOT NULL DEFAULT 0,
  sessions_total INT GENERATED ALWAYS AS (sessions_bought + sessions_bonus) STORED,
  status course_status NOT NULL DEFAULT 'ACTIVE',
  expiry_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_courses_patient ON courses(patient_id);
CREATE INDEX idx_courses_clinic ON courses(clinic_id);

CREATE TRIGGER courses_updated_at
  BEFORE UPDATE ON courses
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 15. COURSE SESSIONS
-- ============================================================

CREATE TABLE course_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  session_number INT NOT NULL,
  is_bonus BOOLEAN NOT NULL DEFAULT false,
  is_used BOOLEAN NOT NULL DEFAULT false,
  used_date DATE,
  treatment_record_id UUID REFERENCES treatment_records(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_course_sessions ON course_sessions(course_id);

-- ============================================================
-- 16. FINANCIAL RECORDS
-- ============================================================

CREATE TABLE financial_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  treatment_record_id UUID REFERENCES treatment_records(id) ON DELETE SET NULL,
  course_id UUID REFERENCES courses(id) ON DELETE SET NULL,
  type financial_type NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  payment_method payment_method,
  description TEXT,
  is_outstanding BOOLEAN NOT NULL DEFAULT false,
  created_by UUID REFERENCES staff(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_financial_patient ON financial_records(patient_id);
CREATE INDEX idx_financial_clinic ON financial_records(clinic_id);
CREATE INDEX idx_financial_outstanding ON financial_records(clinic_id, is_outstanding) WHERE is_outstanding = true;

-- ============================================================
-- 17. MESSAGE LOGS
-- ============================================================

CREATE TABLE message_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  channel message_channel NOT NULL,
  template_type message_template_type NOT NULL DEFAULT 'CUSTOM',
  message_content TEXT,
  status message_status NOT NULL DEFAULT 'PENDING',
  sent_by UUID REFERENCES staff(id) ON DELETE SET NULL,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_messages_patient ON message_logs(patient_id);
CREATE INDEX idx_messages_clinic ON message_logs(clinic_id);

-- ============================================================
-- 18. AUDIT LOGS (PDPA / Data Integrity)
-- ============================================================

CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  user_id UUID REFERENCES staff(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  old_data JSONB,
  new_data JSONB,
  ip_address TEXT,
  timestamp TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_audit_clinic ON audit_logs(clinic_id);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_time ON audit_logs(clinic_id, timestamp DESC);

-- ============================================================
-- 19. DIGITAL NOTEPADS
-- ============================================================

CREATE TABLE digital_notepads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  title TEXT,
  canvas_data JSONB DEFAULT '{}',
  image_url TEXT,
  created_by UUID REFERENCES staff(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_notepads_patient ON digital_notepads(patient_id);

CREATE TRIGGER notepads_updated_at
  BEFORE UPDATE ON digital_notepads
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 20. TREATMENT INTERVAL RULES (Configurable)
-- ============================================================

CREATE TABLE treatment_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  treatment_type TEXT NOT NULL,
  repeat_min_days INT NOT NULL DEFAULT 30,
  repeat_ideal_days INT NOT NULL DEFAULT 60,
  contraindications TEXT[] DEFAULT '{}',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(clinic_id, treatment_type)
);

CREATE TRIGGER treatment_rules_updated_at
  BEFORE UPDATE ON treatment_rules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- HELPER: get current user's clinic IDs (SECURITY DEFINER)
-- Avoids circular RLS reference on staff table
-- ============================================================

CREATE OR REPLACE FUNCTION get_my_clinic_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT clinic_id FROM staff WHERE user_id = auth.uid()
$$;

-- ============================================================
-- ROW-LEVEL SECURITY (RLS) — Multi-tenant isolation
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE clinics ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE treatment_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE face_diagrams ENABLE ROW LEVEL SECURITY;
ALTER TABLE consent_form_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE consent_forms ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE digital_notepads ENABLE ROW LEVEL SECURITY;
ALTER TABLE treatment_rules ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Staff can only access their own clinic's data
-- (Applied to all tables with clinic_id)

CREATE POLICY "Staff access own clinic" ON staff
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Patients access own clinic" ON patients
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Appointments access own clinic" ON appointments
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Services access own clinic" ON services
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Treatment records access own clinic" ON treatment_records
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Photos access own clinic" ON patient_photos
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Diagrams access own clinic" ON face_diagrams
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Consent templates access own clinic" ON consent_form_templates
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Consent forms access own clinic" ON consent_forms
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Products access own clinic" ON products
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Inventory tx access own clinic" ON inventory_transactions
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Courses access own clinic" ON courses
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Course sessions access own clinic" ON course_sessions
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Financial records access own clinic" ON financial_records
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Message logs access own clinic" ON message_logs
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Audit logs access own clinic" ON audit_logs
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Notepads access own clinic" ON digital_notepads
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Schedules access own clinic" ON staff_schedules
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Treatment rules access own clinic" ON treatment_rules
  FOR ALL USING (
    clinic_id IN (SELECT get_my_clinic_ids())
  );

CREATE POLICY "Clinics access own" ON clinics
  FOR ALL USING (
    id IN (SELECT get_my_clinic_ids())
  );

-- ============================================================
-- SEED: Default Treatment Rules
-- ============================================================

-- These will be inserted per-clinic during onboarding
-- Example defaults:
-- INSERT INTO treatment_rules (clinic_id, treatment_type, repeat_min_days, repeat_ideal_days)
-- VALUES
--   (:clinic_id, 'Botox', 60, 90),
--   (:clinic_id, 'Filler', 120, 180),
--   (:clinic_id, 'Laser', 21, 30),
--   (:clinic_id, 'HIFU', 90, 180);

-- ============================================================
-- STORAGE BUCKETS (run via Supabase Dashboard or CLI)
-- ============================================================

-- These must be created via Supabase Storage API/Dashboard:
-- 1. patient-photos    (public: false)
-- 2. face-diagrams     (public: false)
-- 3. consent-signatures (public: false)
-- 4. consent-pdfs      (public: false)
-- 5. notepads          (public: false)
-- 6. clinic-assets     (public: true — logos, etc.)
