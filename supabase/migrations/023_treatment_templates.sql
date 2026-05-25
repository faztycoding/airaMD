-- Migration 023: Treatment Combo Templates (Phase 5E)
--
-- Lets each clinic save reusable "combo" templates that pre-fill the
-- treatment form. Example: "Acne Scar Combo" = Pico MLA pore/scar +
-- Subcission + Rejuran healer, all loaded with one tap.
--
-- 5 starter combos are seeded for every clinic. The clinic can later
-- add/edit/delete its own templates from inside the app.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────
-- 1. Table
-- ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS treatment_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category treatment_category NOT NULL DEFAULT 'TREATMENT',
  description TEXT,
  -- JSONB: [{name: text, brand: text?, quantity: number, unit: text}]
  suggested_products JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- JSONB: [text] — service names that this combo typically includes
  suggested_services JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- One free-text instruction per element
  default_instructions TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_treatment_templates_clinic
  ON treatment_templates(clinic_id);

CREATE INDEX IF NOT EXISTS idx_treatment_templates_clinic_category
  ON treatment_templates(clinic_id, category);

-- updated_at trigger (reuses existing function from migration 001)
DROP TRIGGER IF EXISTS treatment_templates_updated_at ON treatment_templates;
CREATE TRIGGER treatment_templates_updated_at
  BEFORE UPDATE ON treatment_templates
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ─────────────────────────────────────────────────────────────────────
-- 2. RLS — clinic-scoped read/write (mirrors patients/treatment_records)
-- ─────────────────────────────────────────────────────────────────────
ALTER TABLE treatment_templates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS treatment_templates_select ON treatment_templates;
CREATE POLICY treatment_templates_select ON treatment_templates
  FOR SELECT USING (
    clinic_id IN (
      SELECT clinic_id FROM staff WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS treatment_templates_insert ON treatment_templates;
CREATE POLICY treatment_templates_insert ON treatment_templates
  FOR INSERT WITH CHECK (
    clinic_id IN (
      SELECT clinic_id FROM staff WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS treatment_templates_update ON treatment_templates;
CREATE POLICY treatment_templates_update ON treatment_templates
  FOR UPDATE USING (
    clinic_id IN (
      SELECT clinic_id FROM staff WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS treatment_templates_delete ON treatment_templates;
CREATE POLICY treatment_templates_delete ON treatment_templates
  FOR DELETE USING (
    clinic_id IN (
      SELECT clinic_id FROM staff WHERE user_id = auth.uid()
    )
  );


-- ─────────────────────────────────────────────────────────────────────
-- 3. Seed 5 starter combos for every clinic (idempotent)
-- ─────────────────────────────────────────────────────────────────────
INSERT INTO treatment_templates
  (clinic_id, name, category, description, suggested_products, suggested_services, default_instructions)
SELECT c.id, t.name, t.category::treatment_category, t.description,
       t.suggested_products::jsonb, t.suggested_services::jsonb, t.default_instructions
FROM clinics c
CROSS JOIN (VALUES
  (
    'Acne Scar Combo',
    'LASER',
    'Pico MLA pore/scar + Subcission + Rejuran healer — for boxcar/atrophic scars',
    '[{"name":"Rejuran Healer","brand":"Pharmos","quantity":1,"unit":"syringe"}]',
    '["Pico Laser MLA Pore/Scar"]',
    ARRAY[
      'หลีกเลี่ยงแสงแดดจัด 2 สัปดาห์',
      'ทา sunscreen SPF50+ ทุกวัน',
      'อาจมีรอยแดง ช้ำ 3-7 วัน',
      'นัดติดตามผล 4 สัปดาห์'
    ]
  ),
  (
    'Midface Filler',
    'INJECTABLE',
    'Voluma + Lyft โหนกแก้ม + midface lift',
    '[{"name":"Juvederm Voluma","brand":"Allergan","quantity":1,"unit":"cc"},{"name":"Restylane Lyft","brand":"Galderma","quantity":1,"unit":"cc"}]',
    '[]',
    ARRAY[
      'หลีกเลี่ยงนวดบริเวณที่ฉีด 2 สัปดาห์',
      'อาจมีรอยช้ำ 5-7 วัน',
      'ดื่มน้ำมากๆ ช่วยให้ filler integrate'
    ]
  ),
  (
    'Botox Full Face',
    'INJECTABLE',
    'หน้าผาก + กราม + รอบตา',
    '[{"name":"Neuronox","brand":"Medytox","quantity":50,"unit":"U"}]',
    '[]',
    ARRAY[
      'หลีกเลี่ยงนอนคว่ำ 4 ชั่วโมง',
      'ไม่นวดบริเวณที่ฉีด 24 ชั่วโมง',
      'ผลเริ่มเห็นใน 3-7 วัน',
      'ผลเต็มที่ 14 วัน'
    ]
  ),
  (
    'Anti-aging Energy',
    'LASER',
    'Ultraformer3 lift + Profhilo hydration combo',
    '[{"name":"Profhilo","brand":"IBSA","quantity":2,"unit":"cc"}]',
    '["Ultraformer3 600 shots"]',
    ARRAY[
      'อาจมีรอยแดงเล็กน้อย 1-2 ชั่วโมง',
      'ดื่มน้ำมากๆ',
      'เห็นผล lift ค่อยๆ ใน 4-12 สัปดาห์'
    ]
  ),
  (
    'Whitening Combo',
    'LASER',
    'Pico toning + brightening IV — ผิวกระจ่างใส',
    '[]',
    '["Pico Laser Toning","Brightening Injection"]',
    ARRAY[
      'หลีกเลี่ยงแสงแดด 2 สัปดาห์',
      'ทา sunscreen SPF50+ ทุกวัน',
      'งดสครับ/ผลัดเซลล์ผิว 1 สัปดาห์'
    ]
  )
) AS t(name, category, description, suggested_products, suggested_services, default_instructions)
WHERE NOT EXISTS (
  SELECT 1 FROM treatment_templates
  WHERE clinic_id = c.id AND lower(name) = lower(t.name)
);


COMMIT;
