import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/models/models.dart';
import 'package:airamd/core/services/safety_check_service.dart';
import '../helpers/test_fixtures.dart';

void main() {
  group('SafetyCheckService', () {
    // ─── Drug Allergy Checks ───────────────────────────────

    group('drug allergies', () {
      test('should return danger when product matches allergy', () {
        final patient = TestFixtures.allergyPatient();
        final warnings = SafetyCheckService.checkAll(
          patient: patient,
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
          productsToUse: ['Lidocaine 2%'],
        );

        final dangerWarnings =
            warnings.where((w) => w.level == WarningLevel.danger).toList();
        expect(dangerWarnings, isNotEmpty);
        expect(dangerWarnings.first.title, contains('Lidocaine'));
      });

      test('should return info when patient has allergies but no match', () {
        final patient = TestFixtures.allergyPatient();
        final warnings = SafetyCheckService.checkAll(
          patient: patient,
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
          productsToUse: ['Botulinum Toxin'],
        );

        final infoWarnings =
            warnings.where((w) => w.title.contains('ข้อมูลการแพ้ยา')).toList();
        expect(infoWarnings, isNotEmpty);
      });

      test('should return empty when patient has no allergies', () {
        final patient = TestFixtures.healthyPatient();
        final warnings = SafetyCheckService.checkAll(
          patient: patient,
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
          productsToUse: ['Lidocaine 2%'],
        );

        final allergyWarnings =
            warnings.where((w) => w.title.contains('แพ้ยา')).toList();
        expect(allergyWarnings, isEmpty);
      });
    });

    // ─── Retinoid Checks ───────────────────────────────────

    group('retinoids', () {
      test('should warn when using retinoids with laser', () {
        final patient = TestFixtures.retinoidPatient();
        final warnings = SafetyCheckService.checkAll(
          patient: patient,
          treatmentName: 'IPL',
          category: TreatmentCategory.laser,
          patientHistory: [],
          rules: [],
        );

        final retinoidWarnings =
            warnings.where((w) => w.title.contains('Retinoids')).toList();
        expect(retinoidWarnings, isNotEmpty);
        expect(retinoidWarnings.first.level, WarningLevel.caution);
      });

      test('should warn when using retinoids with treatment', () {
        final patient = TestFixtures.retinoidPatient();
        final warnings = SafetyCheckService.checkAll(
          patient: patient,
          treatmentName: 'Chemical Peel',
          category: TreatmentCategory.treatment,
          patientHistory: [],
          rules: [],
        );

        final retinoidWarnings =
            warnings.where((w) => w.title.contains('Retinoids')).toList();
        expect(retinoidWarnings, isNotEmpty);
      });

      test('should not warn when using retinoids with injectable', () {
        final patient = TestFixtures.retinoidPatient();
        final warnings = SafetyCheckService.checkAll(
          patient: patient,
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
        );

        final retinoidWarnings =
            warnings.where((w) => w.title.contains('Retinoids')).toList();
        expect(retinoidWarnings, isEmpty);
      });

      test('should not warn when patient is not using retinoids', () {
        final patient = TestFixtures.healthyPatient();
        final warnings = SafetyCheckService.checkAll(
          patient: patient,
          treatmentName: 'IPL',
          category: TreatmentCategory.laser,
          patientHistory: [],
          rules: [],
        );

        final retinoidWarnings =
            warnings.where((w) => w.title.contains('Retinoids')).toList();
        expect(retinoidWarnings, isEmpty);
      });
    });

    // ─── Anticoagulant Checks ──────────────────────────────

    group('anticoagulant', () {
      test('should warn when on anticoagulant with injectable', () {
        final patient = TestFixtures.anticoagulantPatient();
        final warnings = SafetyCheckService.checkAll(
          patient: patient,
          treatmentName: 'Filler',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
        );

        final antiWarnings =
            warnings.where((w) => w.title.contains('ละลายลิ่มเลือด')).toList();
        expect(antiWarnings, isNotEmpty);
        expect(antiWarnings.first.level, WarningLevel.caution);
      });

      test('should not warn when on anticoagulant with laser', () {
        final patient = TestFixtures.anticoagulantPatient();
        final warnings = SafetyCheckService.checkAll(
          patient: patient,
          treatmentName: 'IPL',
          category: TreatmentCategory.laser,
          patientHistory: [],
          rules: [],
        );

        final antiWarnings =
            warnings.where((w) => w.title.contains('ละลายลิ่มเลือด')).toList();
        expect(antiWarnings, isEmpty);
      });
    });

    // ─── Timing Rules ──────────────────────────────────────

    group('timing rules', () {
      test('should return danger when below minimum days', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.healthyPatient(),
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [TestFixtures.recentBotox(daysAgo: 30)],
          rules: [TestFixtures.botoxRule()],
        );

        final timingWarnings =
            warnings.where((w) => w.title.contains('ขั้นต่ำ')).toList();
        expect(timingWarnings, isNotEmpty);
        expect(timingWarnings.first.level, WarningLevel.danger);
      });

      test('should return caution when below ideal days but above min', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.healthyPatient(),
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [TestFixtures.recentBotox(daysAgo: 70)],
          rules: [TestFixtures.botoxRule()],
        );

        final timingWarnings =
            warnings.where((w) => w.title.contains('แนะนำ')).toList();
        expect(timingWarnings, isNotEmpty);
        expect(timingWarnings.first.level, WarningLevel.caution);
      });

      test('should not warn when above ideal days', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.healthyPatient(),
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [TestFixtures.recentBotox(daysAgo: 100)],
          rules: [TestFixtures.botoxRule()],
        );

        final timingWarnings = warnings
            .where(
                (w) => w.title.contains('ขั้นต่ำ') || w.title.contains('แนะนำ'))
            .toList();
        expect(timingWarnings, isEmpty);
      });

      test('should not warn when no history', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.healthyPatient(),
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [TestFixtures.botoxRule()],
        );

        final timingWarnings = warnings
            .where(
                (w) => w.title.contains('ขั้นต่ำ') || w.title.contains('แนะนำ'))
            .toList();
        expect(timingWarnings, isEmpty);
      });

      test('should not warn when no matching rule', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.healthyPatient(),
          treatmentName: 'HIFU',
          category: TreatmentCategory.treatment,
          patientHistory: [TestFixtures.recentBotox(daysAgo: 5)],
          rules: [TestFixtures.botoxRule()],
        );

        final timingWarnings = warnings
            .where(
                (w) => w.title.contains('ขั้นต่ำ') || w.title.contains('แนะนำ'))
            .toList();
        expect(timingWarnings, isEmpty);
      });

      test('should check filler timing correctly', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.healthyPatient(),
          treatmentName: 'Filler',
          category: TreatmentCategory.injectable,
          patientHistory: [TestFixtures.recentFiller(daysAgo: 60)],
          rules: [TestFixtures.fillerRule()],
        );

        final dangerWarnings =
            warnings.where((w) => w.level == WarningLevel.danger).toList();
        expect(dangerWarnings, isNotEmpty);
        expect(dangerWarnings.first.message, contains('120'));
      });
    });

    // ─── Contraindications ─────────────────────────────────

    group('contraindications', () {
      test('should show contraindications from rule', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.healthyPatient(),
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [TestFixtures.botoxRule()],
        );

        final contraWarnings = warnings
            .where((w) => w.title.contains('Contraindications'))
            .toList();
        expect(contraWarnings, isNotEmpty);
        expect(contraWarnings.first.message, contains('ตั้งครรภ์'));
      });

      test('should not show contraindications when rule has none', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.healthyPatient(),
          treatmentName: 'Laser',
          category: TreatmentCategory.laser,
          patientHistory: [],
          rules: [TestFixtures.laserRule()],
        );

        final contraWarnings = warnings
            .where((w) => w.title.contains('Contraindications'))
            .toList();
        expect(contraWarnings, isEmpty);
      });
    });

    // ─── Medical Conditions ────────────────────────────────

    group('medical conditions', () {
      test('should warn about diabetes', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.diabeticPatient(),
          treatmentName: 'Filler',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
        );

        final diabetesWarnings =
            warnings.where((w) => w.title.contains('เบาหวาน')).toList();
        expect(diabetesWarnings, isNotEmpty);
        expect(diabetesWarnings.first.level, WarningLevel.caution);
      });

      test('should warn danger about autoimmune with injectable', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.autoImmunePatient(),
          treatmentName: 'Filler',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
        );

        final autoWarnings = warnings
            .where((w) => w.title.contains('ภูมิคุ้มกันทำลายตนเอง'))
            .toList();
        expect(autoWarnings, isNotEmpty);
        expect(autoWarnings.first.level, WarningLevel.danger);
      });
    });

    // ─── Pregnancy Check ───────────────────────────────────

    group('pregnancy age', () {
      test('should warn for young female patient', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.youngFemalePatient(),
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
        );

        final pregnancyWarnings =
            warnings.where((w) => w.title.contains('ตั้งครรภ์')).toList();
        expect(pregnancyWarnings, isNotEmpty);
        expect(pregnancyWarnings.first.level, WarningLevel.info);
      });

      test('should not warn for male patient', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.malePatient(),
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
        );

        final pregnancyWarnings =
            warnings.where((w) => w.title.contains('ตั้งครรภ์')).toList();
        expect(pregnancyWarnings, isEmpty);
      });
    });

    // ─── Keloid History ────────────────────────────────────

    group('keloid history', () {
      test('should warn when keloid patient gets injectable', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.keloidPatient(),
          treatmentName: 'Filler',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
        );

        final keloidWarnings =
            warnings.where((w) => w.title.contains('คีลอยด์')).toList();
        expect(keloidWarnings, isNotEmpty);
        expect(keloidWarnings.first.level, WarningLevel.caution);
      });

      test('should warn when keloid patient gets laser', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.keloidPatient(),
          treatmentName: 'IPL',
          category: TreatmentCategory.laser,
          patientHistory: [],
          rules: [],
        );

        final keloidWarnings =
            warnings.where((w) => w.title.contains('คีลอยด์')).toList();
        expect(keloidWarnings, isNotEmpty);
      });

      test('should not warn when keloid patient gets treatment', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.keloidPatient(),
          treatmentName: 'Facial',
          category: TreatmentCategory.treatment,
          patientHistory: [],
          rules: [],
        );

        final keloidWarnings =
            warnings.where((w) => w.title.contains('คีลอยด์')).toList();
        expect(keloidWarnings, isEmpty);
      });
    });

    // ─── Skin Sensitivity ──────────────────────────────────

    group('skin sensitivity', () {
      test('should warn about eczema with laser', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.keloidPatient(), // has eczema
          treatmentName: 'IPL',
          category: TreatmentCategory.laser,
          patientHistory: [],
          rules: [],
        );

        final skinWarnings =
            warnings.where((w) => w.title.contains('โรคผิวหนัง')).toList();
        expect(skinWarnings, isNotEmpty);
        expect(skinWarnings.first.level, WarningLevel.caution);
      });

      test('should warn about tan/sun exposure with laser', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.tanNotePatient(),
          treatmentName: 'IPL',
          category: TreatmentCategory.laser,
          patientHistory: [],
          rules: [],
        );

        final sunWarnings =
            warnings.where((w) => w.title.contains('ตากแดด')).toList();
        expect(sunWarnings, isNotEmpty);
      });

      test('should not check skin for non-laser', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.keloidPatient(),
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
        );

        final skinWarnings =
            warnings.where((w) => w.title.contains('โรคผิวหนัง')).toList();
        expect(skinWarnings, isEmpty);
      });
    });

    // ─── Combined Scenarios ────────────────────────────────

    group('combined scenarios', () {
      test('should return multiple warnings for high-risk patient', () {
        final patient = Patient(
          id: 'risky',
          clinicId: TestFixtures.clinicId,
          firstName: 'Risky',
          lastName: 'Patient',
          dateOfBirth: DateTime(1995, 1, 1),
          gender: GenderType.female,
          drugAllergies: ['Botox'],
          isUsingRetinoids: true,
          isOnAnticoagulant: true,
          medicalConditions: ['keloid', 'diabetes'],
          notes: 'ตากแดดมาก',
        );

        final warnings = SafetyCheckService.checkAll(
          patient: patient,
          treatmentName: 'Laser',
          category: TreatmentCategory.laser,
          patientHistory: [TestFixtures.recentLaser(daysAgo: 10)],
          rules: [TestFixtures.laserRule()],
          productsToUse: ['Botox cream'],
        );

        // Should have: allergy, retinoids, timing, pregnancy, keloid, eczema-not, skin/tan, diabetes
        expect(warnings.length, greaterThanOrEqualTo(4));
        expect(
          warnings.any((w) => w.level == WarningLevel.danger),
          isTrue,
        );
      });

      test('should return empty for healthy patient with safe timing', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.malePatient(),
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [TestFixtures.recentBotox(daysAgo: 100)],
          rules: [TestFixtures.botoxRule()],
          productsToUse: ['Botulinum Toxin'],
        );

        // Only contraindications info (if any)
        final dangerOrCaution = warnings
            .where((w) =>
                w.level == WarningLevel.danger ||
                w.level == WarningLevel.caution)
            .toList();
        expect(dangerOrCaution, isEmpty);
      });
    });

    // ─── Supplement Interaction Checks ────────────────────
    group('supplement interactions', () {
      test('fish oil should warn caution for injectable', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.supplementPatient(
              medications: ['น้ำมันปลา 1000mg']),
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
        );

        final fishOilWarnings =
            warnings.where((w) => w.title.contains('Fish Oil')).toList();
        expect(fishOilWarnings, isNotEmpty);
        expect(fishOilWarnings.first.level, WarningLevel.caution);
      });

      test('vitamin E should warn caution for laser', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.supplementPatient(
              medications: ['Vitamin E 400IU']),
          treatmentName: 'IPL',
          category: TreatmentCategory.laser,
          patientHistory: [],
          rules: [],
        );

        final vitEWarnings = warnings
            .where((w) => w.title.contains('Vitamin E'))
            .toList();
        expect(vitEWarnings, isNotEmpty);
        expect(vitEWarnings.first.level, WarningLevel.caution);
      });

      test('ginkgo biloba should warn caution for injectable', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.supplementPatient(
              medications: ['Ginkgo Biloba']),
          treatmentName: 'Filler',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
        );

        expect(
          warnings.any((w) => w.title.contains('Ginkgo')),
          isTrue,
        );
      });

      test('ginseng should warn caution for injectable', () {
        final warnings = SafetyCheckService.checkAll(
          patient:
              TestFixtures.supplementPatient(medications: ['โสมเกาหลี']),
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
        );

        expect(warnings.any((w) => w.title.contains('Ginseng')), isTrue);
      });

      test("st. john's wort should warn caution for laser (photosensitivity)",
          () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.supplementPatient(
              medications: ["St. John's Wort"]),
          treatmentName: 'IPL',
          category: TreatmentCategory.laser,
          patientHistory: [],
          rules: [],
        );

        final sjw = warnings
            .where((w) => w.title.contains("St. John's Wort"))
            .toList();
        expect(sjw, isNotEmpty);
        expect(sjw.first.level, WarningLevel.caution);
      });

      test('arnica should return info for injectable (not caution/danger)', () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.supplementPatient(medications: ['Arnica']),
          treatmentName: 'Filler',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
        );

        final arnica =
            warnings.where((w) => w.title.contains('Arnica')).toList();
        expect(arnica, isNotEmpty);
        expect(arnica.first.level, WarningLevel.info);
      });

      test('empty currentMedications should produce no supplement warnings',
          () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.supplementPatient(medications: const []),
          treatmentName: 'Botox',
          category: TreatmentCategory.injectable,
          patientHistory: [],
          rules: [],
        );

        // No warnings should come from supplement check
        final supplementKeywords = [
          'Fish Oil',
          'Vitamin E',
          'Ginkgo',
          'Ginseng',
          'St. John',
          'Arnica',
          'Bromelain',
          'Turmeric',
        ];
        final hits = warnings.where((w) =>
            supplementKeywords.any((k) => w.title.contains(k))).toList();
        expect(hits, isEmpty);
      });

      test('fish oil should NOT warn for non-invasive category (other)',
          () {
        final warnings = SafetyCheckService.checkAll(
          patient: TestFixtures.supplementPatient(
              medications: ['น้ำมันปลา']),
          treatmentName: 'Follow-up',
          category: TreatmentCategory.other,
          patientHistory: [],
          rules: [],
        );

        expect(warnings.any((w) => w.title.contains('Fish Oil')), isFalse);
      });
    });
  });
}
