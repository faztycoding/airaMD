-- Migration 021: Master Catalog Seed (Phase 5)
--
-- Seeds the per-clinic Products + Services catalog with the master list
-- provided by the doctor on May 24, 2026. ~30 products + ~35 services
-- covering injectables, biostimulators, skin boosters, lipolytics,
-- laser/energy devices, treatments and IV drips.
--
-- Idempotent:
--   - Only inserts rows whose (clinic_id, name) does not already exist.
--   - Safe to re-run; no duplicates created.
--
-- Default prices are midpoints of common Thai clinic ranges (B 2026).
-- Doctor can override per-row in the Services / Products screens.
--
-- Applies to ALL clinics in the database — every new clinic gets the
-- same starter catalog. Future per-clinic customisation happens via
-- the in-app catalog screens.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────
-- 1. PRODUCTS (consumable inventory)
-- ─────────────────────────────────────────────────────────────────────
-- Strategy: cross-join clinics × catalog VALUES → INSERT WHERE NOT EXISTS

INSERT INTO products
  (clinic_id, name, brand, category, unit, default_price, stock_quantity, is_active)
SELECT c.id, p.name, p.brand, p.category::product_category, p.unit, p.default_price, 0, true
FROM clinics c
CROSS JOIN (VALUES
  -- ── Fillers (HA-based) ──────────────────────────────────────────
  ('Restylane Vital Light',  'Galderma',  'FILLER', 'cc',       8500.00),
  ('Restylane Classic',      'Galderma',  'FILLER', 'cc',      12500.00),
  ('Restylane Lyft',         'Galderma',  'FILLER', 'cc',      15000.00),
  ('Definisse Touch',        'Relife',    'FILLER', 'cc',      15000.00),
  ('Definisse Restore',      'Relife',    'FILLER', 'cc',      17500.00),
  ('Definisse Core',         'Relife',    'FILLER', 'cc',      20000.00),
  ('Juvederm Volift',        'Allergan',  'FILLER', 'cc',      13500.00),
  ('Juvederm Voluma',        'Allergan',  'FILLER', 'cc',      15000.00),
  ('Yvoire Classic',         'LG Chem',   'FILLER', 'cc',       5500.00),
  ('Yvoire Volume',          'LG Chem',   'FILLER', 'cc',       7000.00),
  ('Yvoire Contour',         'LG Chem',   'FILLER', 'cc',       9000.00),
  ('Hyafillia S+',           'CHA Meditech','FILLER','cc',      5500.00),
  ('Hyafillia M+',           'CHA Meditech','FILLER','cc',      7500.00),
  ('Hyafillia V+',           'CHA Meditech','FILLER','cc',      9500.00),
  -- ── Botulinum Toxin ─────────────────────────────────────────────
  ('Neuronox',               'Medytox',   'BOTOX',  'U',           45.00),
  ('Allergan (Botox)',       'Allergan',  'BOTOX',  'U',           85.00),
  ('Xeomin',                 'Merz',      'BOTOX',  'U',           65.00),
  ('Mbtox',                  'Medytox',   'BOTOX',  'U',           35.00),
  -- ── Biostimulators / Collagen Stimulators ───────────────────────
  ('Profhilo',               'IBSA',      'BIOSTIMULATOR', 'syringe', 8000.00),
  ('Ejal40',                 'IBSA',      'BIOSTIMULATOR', 'syringe', 7000.00),
  ('Belotero Revive',        'Merz',      'BIOSTIMULATOR', 'syringe', 8500.00),
  ('Belluxi',                'Genoss',    'BIOSTIMULATOR', 'syringe', 5500.00),
  ('Radiesse',               'Merz',      'BIOSTIMULATOR', 'cc',     15000.00),
  ('Sculptra',               'Galderma',  'BIOSTIMULATOR', 'vial',   18000.00),
  -- ── Skin Boosters / Polynucleotides ────────────────────────────
  ('L-Collagen',             'Various',   'SKINBOOSTER',   'syringe', 4500.00),
  ('P Extract',              'Various',   'SKINBOOSTER',   'syringe', 3500.00),
  ('Rejuran Healer',         'Pharmos',   'POLYNUCLEOTIDE','syringe', 6000.00),
  -- ── Lipolytics (Fat / Body Solutions) — stored under OTHER until migration 022
  ('Fat Bomb Face',          'Various',   'OTHER',  'vial',   4500.00),
  ('Fat Bomb Body',          'Various',   'OTHER',  'vial',   6500.00),
  ('V Face Solution',        'Various',   'OTHER',  'vial',   4000.00),
  ('V Body Solution',        'Various',   'OTHER',  'vial',   6000.00),
  -- ── Energy Device Cartridges (shot-based) ──────────────────────
  ('Oligio Cartridge',       'Jeisys',    'LASER',  'shots',     NULL),
  ('Ultraformer3 Cartridge', 'Classys',   'LASER',  'shots',     NULL),
  ('Ulthera Prime Cartridge','Merz',      'LASER',  'shots',     NULL)
) AS p(name, brand, category, unit, default_price)
WHERE NOT EXISTS (
  SELECT 1 FROM products
  WHERE clinic_id = c.id AND lower(name) = lower(p.name)
);


-- ─────────────────────────────────────────────────────────────────────
-- 2. SERVICES (priced offerings / procedures)
-- ─────────────────────────────────────────────────────────────────────

INSERT INTO services
  (clinic_id, name, category, default_price, is_active)
SELECT c.id, s.name, s.category::service_category, s.default_price, true
FROM clinics c
CROSS JOIN (VALUES
  -- ── Pico Laser ─────────────────────────────────────────────────
  ('Pico Laser Toning',                'LASER',      2500.00),
  ('Pico Laser Rejuvenation',          'LASER',      3000.00),
  ('Pico Laser Lightening',            'LASER',      3500.00),
  ('Pico Laser MLA Rejuvenation',      'LASER',      4000.00),
  ('Pico Laser MLA Pore/Scar',         'LASER',      4500.00),
  -- ── CO2 Laser ──────────────────────────────────────────────────
  ('Fractional CO2',                   'LASER',      5000.00),
  ('CO2 Laser (1 point)',              'LASER',      1000.00),
  ('CO2 Laser (whole face)',           'LASER',      8000.00),
  -- ── Body Energy Devices ────────────────────────────────────────
  ('Fat Freezing',                     'LASER',     10000.00),
  ('Hifem',                            'LASER',      8000.00),
  -- ── Oligio (shot tiers) ────────────────────────────────────────
  ('Oligio 300 shots',                 'LASER',      8000.00),
  ('Oligio 600 shots',                 'LASER',     15000.00),
  ('Oligio 900 shots',                 'LASER',     22000.00),
  -- ── Ultraformer3 (shot tiers) ──────────────────────────────────
  ('Ultraformer3 100 shots',           'LASER',      3500.00),
  ('Ultraformer3 300 shots',           'LASER',      8000.00),
  ('Ultraformer3 600 shots',           'LASER',     15000.00),
  ('Ultraformer3 900 shots',           'LASER',     22000.00),
  ('Ultraformer3 1200 shots',          'LASER',     28000.00),
  -- ── Ulthera Prime (shot tiers) ─────────────────────────────────
  ('Ulthera Prime 100 shots',          'LASER',      8000.00),
  ('Ulthera Prime 300 shots',          'LASER',     20000.00),
  ('Ulthera Prime 600 shots',          'LASER',     35000.00),
  ('Ulthera Prime 900 shots',          'LASER',     48000.00),
  -- ── Acne Treatments ────────────────────────────────────────────
  ('ฉีดสิว (Acne Injection)',           'TREATMENT',   500.00),
  ('กดสิว (Acne Extraction)',           'TREATMENT',   800.00),
  -- ── Peeling ────────────────────────────────────────────────────
  ('Miami Peeling S30',                'TREATMENT',  3500.00),
  ('Miami Peeling Qplus',              'TREATMENT',  4500.00),
  -- ── Whitening / Melasma Injections ─────────────────────────────
  ('Brightening Injection',            'INJECTABLE', 1500.00),
  ('Melasma Basic Injection',          'INJECTABLE', 2500.00),
  ('Melasma Premium Injection',        'INJECTABLE', 4500.00),
  -- ── IV Drips ───────────────────────────────────────────────────
  ('IV Drip — Aurowhite',              'TREATMENT',  3500.00),
  ('IV Drip — Skin Detox',             'TREATMENT',  2500.00),
  ('IV Drip — Skin Booster',           'TREATMENT',  2500.00),
  -- ── PRP & Age Boosters ─────────────────────────────────────────
  ('PRP Basic',                        'TREATMENT',  5000.00),
  ('PRP Premium',                      'TREATMENT',  8000.00),
  ('Age Booster Face',                 'TREATMENT',  4500.00),
  ('Age Booster Body',                 'TREATMENT',  6500.00)
) AS s(name, category, default_price)
WHERE NOT EXISTS (
  SELECT 1 FROM services
  WHERE clinic_id = c.id AND lower(name) = lower(s.name)
);


COMMIT;

-- ─────────────────────────────────────────────────────────────────────
-- Verification (run separately after applying):
--
--   SELECT category, COUNT(*) FROM products GROUP BY category ORDER BY category;
--   SELECT category, COUNT(*) FROM services GROUP BY category ORDER BY category;
-- ─────────────────────────────────────────────────────────────────────
