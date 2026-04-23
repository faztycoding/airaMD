import 'package:airamd/core/models/models.dart';

/// Shared test fixtures for airaMD unit tests.
class TestFixtures {
  TestFixtures._();

  static const clinicId = 'clinic-001';
  static const staffId = 'staff-001';
  static const patientId = 'patient-001';

  // ─── Staff ─────────────────────────────────────────────────

  static Staff ownerStaff({String? id, String? clinicId}) => Staff(
        id: id ?? staffId,
        clinicId: clinicId ?? TestFixtures.clinicId,
        userId: 'auth-user-001',
        fullName: 'Dr. Somchai',
        nickname: 'หมอชัย',
        role: StaffRole.owner,
        isActive: true,
      );

  static Staff doctorStaff({String? id, String? clinicId}) => Staff(
        id: id ?? 'staff-002',
        clinicId: clinicId ?? TestFixtures.clinicId,
        userId: 'auth-user-002',
        fullName: 'Dr. Ploy',
        nickname: 'หมอพลอย',
        role: StaffRole.doctor,
        isActive: true,
      );

  static Staff receptionistStaff({String? id, String? clinicId}) => Staff(
        id: id ?? 'staff-003',
        clinicId: clinicId ?? TestFixtures.clinicId,
        userId: 'auth-user-003',
        fullName: 'Nong Fah',
        nickname: 'ฟ้า',
        role: StaffRole.receptionist,
        isActive: true,
      );

  // ─── Patient ───────────────────────────────────────────────

  static Patient healthyPatient({String? id}) => Patient(
        id: id ?? patientId,
        clinicId: clinicId,
        firstName: 'สมหญิง',
        lastName: 'ใจดี',
        nickname: 'หญิง',
        dateOfBirth: DateTime(1990, 5, 15),
        gender: GenderType.female,
        phone: '0812345678',
        status: PatientStatus.normal,
      );

  static Patient allergyPatient({String? id}) => Patient(
        id: id ?? 'patient-002',
        clinicId: clinicId,
        firstName: 'สมชาย',
        lastName: 'แพ้ยา',
        dateOfBirth: DateTime(1985, 3, 10),
        gender: GenderType.male,
        drugAllergies: ['Lidocaine', 'Aspirin'],
        allergySymptoms: 'ผื่นแดง หายใจลำบาก',
      );

  static Patient retinoidPatient({String? id}) => Patient(
        id: id ?? 'patient-003',
        clinicId: clinicId,
        firstName: 'วิไล',
        lastName: 'ใช้เรตินอยด์',
        dateOfBirth: DateTime(1995, 8, 20),
        gender: GenderType.female,
        isUsingRetinoids: true,
      );

  static Patient anticoagulantPatient({String? id}) => Patient(
        id: id ?? 'patient-004',
        clinicId: clinicId,
        firstName: 'บุญมี',
        lastName: 'ทานยาเลือด',
        dateOfBirth: DateTime(1960, 1, 1),
        gender: GenderType.male,
        isOnAnticoagulant: true,
      );

  static Patient keloidPatient({String? id}) => Patient(
        id: id ?? 'patient-005',
        clinicId: clinicId,
        firstName: 'นงลักษณ์',
        lastName: 'แผลเป็นนูน',
        dateOfBirth: DateTime(1988, 12, 25),
        gender: GenderType.female,
        medicalConditions: ['keloid', 'eczema'],
      );

  static Patient diabeticPatient({String? id}) => Patient(
        id: id ?? 'patient-006',
        clinicId: clinicId,
        firstName: 'สมศักดิ์',
        lastName: 'เบาหวาน',
        dateOfBirth: DateTime(1965, 7, 7),
        gender: GenderType.male,
        medicalConditions: ['diabetes'],
      );

  static Patient autoImmunePatient({String? id}) => Patient(
        id: id ?? 'patient-007',
        clinicId: clinicId,
        firstName: 'มาลี',
        lastName: 'ภูมิคุ้มกัน',
        dateOfBirth: DateTime(1992, 2, 14),
        gender: GenderType.female,
        medicalConditions: ['SLE', 'lupus'],
      );

  static Patient youngFemalePatient({String? id}) => Patient(
        id: id ?? 'patient-008',
        clinicId: clinicId,
        firstName: 'น้องฝน',
        lastName: 'วัยรุ่น',
        dateOfBirth: DateTime(2000, 6, 1),
        gender: GenderType.female,
      );

  static Patient malePatient({String? id}) => Patient(
        id: id ?? 'patient-009',
        clinicId: clinicId,
        firstName: 'สมปอง',
        lastName: 'ผู้ชาย',
        dateOfBirth: DateTime(1990, 1, 1),
        gender: GenderType.male,
      );

  static Patient tanNotePatient({String? id}) => Patient(
        id: id ?? 'patient-010',
        clinicId: clinicId,
        firstName: 'สุดา',
        lastName: 'ตากแดด',
        dateOfBirth: DateTime(1993, 4, 4),
        gender: GenderType.female,
        notes: 'ผิวคล้ำ ตากแดดบ่อย',
      );

  static Patient supplementPatient({
    String? id,
    List<String> medications = const [],
  }) =>
      Patient(
        id: id ?? 'patient-011',
        clinicId: clinicId,
        firstName: 'ภัทร',
        lastName: 'อาหารเสริม',
        dateOfBirth: DateTime(1988, 8, 8),
        gender: GenderType.female,
        currentMedications: medications,
      );

  // ─── Treatment Records ─────────────────────────────────────

  static TreatmentRecord recentBotox({int daysAgo = 30}) => TreatmentRecord(
        id: 'tr-001',
        clinicId: clinicId,
        patientId: patientId,
        date: DateTime.now().subtract(Duration(days: daysAgo)),
        category: TreatmentCategory.injectable,
        treatmentName: 'Botox',
      );

  static TreatmentRecord recentFiller({int daysAgo = 60}) => TreatmentRecord(
        id: 'tr-002',
        clinicId: clinicId,
        patientId: patientId,
        date: DateTime.now().subtract(Duration(days: daysAgo)),
        category: TreatmentCategory.injectable,
        treatmentName: 'Filler',
      );

  static TreatmentRecord recentLaser({int daysAgo = 14}) => TreatmentRecord(
        id: 'tr-003',
        clinicId: clinicId,
        patientId: patientId,
        date: DateTime.now().subtract(Duration(days: daysAgo)),
        category: TreatmentCategory.laser,
        treatmentName: 'Laser',
      );

  // ─── Treatment Rules ───────────────────────────────────────

  static TreatmentRule botoxRule() => const TreatmentRule(
        id: 'rule-001',
        clinicId: clinicId,
        treatmentType: 'Botox',
        repeatMinDays: 60,
        repeatIdealDays: 90,
        contraindications: ['ตั้งครรภ์', 'ให้นมบุตร', 'โรคกล้ามเนื้ออ่อนแรง'],
      );

  static TreatmentRule fillerRule() => const TreatmentRule(
        id: 'rule-002',
        clinicId: clinicId,
        treatmentType: 'Filler',
        repeatMinDays: 120,
        repeatIdealDays: 180,
        contraindications: ['ตั้งครรภ์', 'Autoimmune'],
      );

  static TreatmentRule laserRule() => const TreatmentRule(
        id: 'rule-003',
        clinicId: clinicId,
        treatmentType: 'Laser',
        repeatMinDays: 21,
        repeatIdealDays: 30,
      );
}
