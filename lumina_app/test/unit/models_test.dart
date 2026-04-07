import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/models/models.dart';

void main() {
  // ─── Patient Model ───────────────────────────────────────

  group('Patient', () {
    test('fullName should combine first and last name', () {
      const patient = Patient(
        id: '1',
        clinicId: 'c1',
        firstName: 'สมหญิง',
        lastName: 'ใจดี',
      );
      expect(patient.fullName, 'สมหญิง ใจดี');
    });

    test('displayName should show nickname in parentheses', () {
      const patient = Patient(
        id: '1',
        clinicId: 'c1',
        firstName: 'สมหญิง',
        lastName: 'ใจดี',
        nickname: 'หญิง',
      );
      expect(patient.displayName, 'สมหญิง (หญิง)');
    });

    test('displayName should fallback to firstName when no nickname', () {
      const patient = Patient(
        id: '1',
        clinicId: 'c1',
        firstName: 'สมหญิง',
        lastName: 'ใจดี',
      );
      expect(patient.displayName, 'สมหญิง');
    });

    test('age should calculate correctly', () {
      final patient = Patient(
        id: '1',
        clinicId: 'c1',
        firstName: 'Test',
        lastName: 'Patient',
        dateOfBirth: DateTime(2000, 1, 1),
      );
      final expectedAge = DateTime.now().year - 2000 -
          (DateTime.now().isBefore(DateTime(DateTime.now().year, 1, 1))
              ? 1
              : 0);
      expect(patient.age, expectedAge);
    });

    test('age should return null when no date of birth', () {
      const patient = Patient(
        id: '1',
        clinicId: 'c1',
        firstName: 'Test',
        lastName: 'Patient',
      );
      expect(patient.age, isNull);
    });

    test('fromJson should parse all fields correctly', () {
      final json = {
        'id': 'p-001',
        'clinic_id': 'c-001',
        'hn': 'HN-0001',
        'first_name': 'สมชาย',
        'last_name': 'ทดสอบ',
        'nickname': 'ชาย',
        'date_of_birth': '1990-05-15',
        'gender': 'M',
        'phone': '0812345678',
        'status': 'VIP',
        'drug_allergies': ['Aspirin', 'Penicillin'],
        'medical_conditions': ['diabetes'],
        'smoking': 'OCCASIONAL',
        'alcohol': 'NONE',
        'is_using_retinoids': true,
        'is_on_anticoagulant': false,
        'preferred_channel': 'LINE',
        'is_active': true,
      };

      final patient = Patient.fromJson(json);

      expect(patient.id, 'p-001');
      expect(patient.clinicId, 'c-001');
      expect(patient.hn, 'HN-0001');
      expect(patient.firstName, 'สมชาย');
      expect(patient.lastName, 'ทดสอบ');
      expect(patient.nickname, 'ชาย');
      expect(patient.gender, GenderType.male);
      expect(patient.status, PatientStatus.vip);
      expect(patient.drugAllergies, ['Aspirin', 'Penicillin']);
      expect(patient.medicalConditions, ['diabetes']);
      expect(patient.smoking, SmokingType.occasional);
      expect(patient.isUsingRetinoids, true);
      expect(patient.isOnAnticoagulant, false);
      expect(patient.preferredChannel, PreferredChannel.line);
    });

    test('fromJson should handle null lists gracefully', () {
      final json = {
        'id': 'p-001',
        'clinic_id': 'c-001',
        'first_name': 'Test',
        'last_name': 'Null',
        'drug_allergies': null,
        'medical_conditions': null,
      };

      final patient = Patient.fromJson(json);
      expect(patient.drugAllergies, isEmpty);
      expect(patient.medicalConditions, isEmpty);
    });

    test('toInsertJson should produce correct map', () {
      const patient = Patient(
        id: 'p-001',
        clinicId: 'c-001',
        firstName: 'สมหญิง',
        lastName: 'ใจดี',
        nickname: 'หญิง',
        gender: GenderType.female,
        drugAllergies: ['Aspirin'],
        isUsingRetinoids: true,
      );

      final json = patient.toInsertJson();
      expect(json['clinic_id'], 'c-001');
      expect(json['first_name'], 'สมหญิง');
      expect(json['nickname'], 'หญิง');
      expect(json['gender'], 'F');
      expect(json['drug_allergies'], ['Aspirin']);
      expect(json['is_using_retinoids'], true);
      expect(json.containsKey('id'), false); // id not in insert
    });

    test('copyWith should override specified fields', () {
      const patient = Patient(
        id: '1',
        clinicId: 'c1',
        firstName: 'Original',
        lastName: 'Name',
        status: PatientStatus.normal,
      );

      final updated = patient.copyWith(
        firstName: 'Updated',
        status: PatientStatus.vip,
      );

      expect(updated.firstName, 'Updated');
      expect(updated.status, PatientStatus.vip);
      expect(updated.lastName, 'Name'); // unchanged
      expect(updated.id, '1'); // unchanged
    });
  });

  // ─── Staff Model ─────────────────────────────────────────

  group('Staff', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 's-001',
        'clinic_id': 'c-001',
        'user_id': 'auth-001',
        'full_name': 'Dr. Somchai',
        'nickname': 'หมอชัย',
        'role': 'OWNER',
        'is_active': true,
      };

      final staff = Staff.fromJson(json);
      expect(staff.id, 's-001');
      expect(staff.fullName, 'Dr. Somchai');
      expect(staff.role, StaffRole.owner);
      expect(staff.isActive, true);
    });

    test('copyWith should override role', () {
      const staff = Staff(
        id: 's-001',
        clinicId: 'c-001',
        fullName: 'Dr. Test',
        role: StaffRole.doctor,
      );

      final updated = staff.copyWith(role: StaffRole.receptionist);
      expect(updated.role, StaffRole.receptionist);
      expect(updated.fullName, 'Dr. Test');
    });

    test('toInsertJson should exclude id', () {
      const staff = Staff(
        id: 's-001',
        clinicId: 'c-001',
        fullName: 'Dr. Test',
        role: StaffRole.doctor,
      );

      final json = staff.toInsertJson();
      expect(json.containsKey('id'), false);
      expect(json['clinic_id'], 'c-001');
      expect(json['role'], 'DOCTOR');
    });
  });

  // ─── TreatmentRecord Model ───────────────────────────────

  group('TreatmentRecord', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 'tr-001',
        'clinic_id': 'c-001',
        'patient_id': 'p-001',
        'date': '2025-01-15T10:00:00Z',
        'category': 'INJECTABLE',
        'treatment_name': 'Botox',
        'vitals': {'temp': 36.5, 'pulse': 72},
        'adverse_events': ['ผิวแดง'],
        'instructions': ['หลีกเลี่ยงแดด'],
      };

      final record = TreatmentRecord.fromJson(json);
      expect(record.id, 'tr-001');
      expect(record.treatmentName, 'Botox');
      expect(record.category, TreatmentCategory.injectable);
      expect(record.vitals['temp'], 36.5);
      expect(record.adverseEvents, ['ผิวแดง']);
      expect(record.instructions, ['หลีกเลี่ยงแดด']);
    });

    test('toInsertJson should include required fields', () {
      final record = TreatmentRecord(
        id: 'tr-001',
        clinicId: 'c-001',
        patientId: 'p-001',
        date: DateTime(2025, 1, 15),
        treatmentName: 'Filler',
        category: TreatmentCategory.injectable,
      );

      final json = record.toInsertJson();
      expect(json['clinic_id'], 'c-001');
      expect(json['patient_id'], 'p-001');
      expect(json['treatment_name'], 'Filler');
      expect(json['category'], 'INJECTABLE');
    });
  });

  // ─── TreatmentRule Model ─────────────────────────────────

  group('TreatmentRule', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 'r-001',
        'clinic_id': 'c-001',
        'treatment_type': 'Botox',
        'repeat_min_days': 60,
        'repeat_ideal_days': 90,
        'contraindications': ['ตั้งครรภ์', 'ให้นมบุตร'],
      };

      final rule = TreatmentRule.fromJson(json);
      expect(rule.treatmentType, 'Botox');
      expect(rule.repeatMinDays, 60);
      expect(rule.repeatIdealDays, 90);
      expect(rule.contraindications, ['ตั้งครรภ์', 'ให้นมบุตร']);
    });

    test('fromJson should use defaults for missing values', () {
      final json = {
        'id': 'r-001',
        'clinic_id': 'c-001',
        'treatment_type': 'Test',
      };

      final rule = TreatmentRule.fromJson(json);
      expect(rule.repeatMinDays, 30); // default
      expect(rule.repeatIdealDays, 60); // default
      expect(rule.contraindications, isEmpty);
    });
  });

  // ─── Enums ───────────────────────────────────────────────

  group('Enums', () {
    test('StaffRole.fromDb should handle all values', () {
      expect(StaffRole.fromDb('OWNER'), StaffRole.owner);
      expect(StaffRole.fromDb('DOCTOR'), StaffRole.doctor);
      expect(StaffRole.fromDb('RECEPTIONIST'), StaffRole.receptionist);
      expect(StaffRole.fromDb(null), StaffRole.doctor); // default
      expect(StaffRole.fromDb('UNKNOWN'), StaffRole.doctor); // default
    });

    test('GenderType.fromDb should handle all values', () {
      expect(GenderType.fromDb('M'), GenderType.male);
      expect(GenderType.fromDb('F'), GenderType.female);
      expect(GenderType.fromDb('OTHER'), GenderType.other);
      expect(GenderType.fromDb(null), GenderType.other); // default
    });

    test('PatientStatus.fromDb should handle all values', () {
      expect(PatientStatus.fromDb('NORMAL'), PatientStatus.normal);
      expect(PatientStatus.fromDb('VIP'), PatientStatus.vip);
      expect(PatientStatus.fromDb('STAR'), PatientStatus.star);
    });

    test('TreatmentCategory.fromDb should handle all values', () {
      expect(
          TreatmentCategory.fromDb('INJECTABLE'), TreatmentCategory.injectable);
      expect(TreatmentCategory.fromDb('LASER'), TreatmentCategory.laser);
      expect(
          TreatmentCategory.fromDb('TREATMENT'), TreatmentCategory.treatment);
      expect(TreatmentCategory.fromDb('OTHER'), TreatmentCategory.other);
    });
  });
}
