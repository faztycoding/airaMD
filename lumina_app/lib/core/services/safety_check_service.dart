import '../models/models.dart';

/// Safety warning levels.
enum WarningLevel { info, caution, danger }

/// A single safety warning.
class SafetyWarning {
  final WarningLevel level;
  final String title;
  final String message;

  const SafetyWarning({
    required this.level,
    required this.title,
    required this.message,
  });
}

/// Pre-treatment safety check service.
/// Validates timing, allergies, contraindications, and treatment sequences.
class SafetyCheckService {
  /// Run all safety checks and return warnings.
  static List<SafetyWarning> checkAll({
    required Patient patient,
    required String treatmentName,
    required TreatmentCategory category,
    required List<TreatmentRecord> patientHistory,
    required List<TreatmentRule> rules,
    List<String> productsToUse = const [],
  }) {
    final warnings = <SafetyWarning>[];

    warnings.addAll(_checkDrugAllergies(patient, productsToUse));
    warnings.addAll(_checkRetinoids(patient, category));
    warnings.addAll(_checkAnticoagulant(patient, category));
    warnings.addAll(_checkTimingRules(treatmentName, patientHistory, rules));
    warnings.addAll(_checkContraindications(treatmentName, rules));
    warnings.addAll(_checkMedicalConditions(patient, category));
    warnings.addAll(_checkPregnancyAge(patient));

    return warnings;
  }

  /// Check drug allergies against products being used.
  static List<SafetyWarning> _checkDrugAllergies(
    Patient patient,
    List<String> productsToUse,
  ) {
    final warnings = <SafetyWarning>[];
    if (patient.drugAllergies.isEmpty) return warnings;

    for (final allergy in patient.drugAllergies) {
      final allergyLower = allergy.toLowerCase();
      for (final product in productsToUse) {
        if (product.toLowerCase().contains(allergyLower) ||
            allergyLower.contains(product.toLowerCase())) {
          warnings.add(SafetyWarning(
            level: WarningLevel.danger,
            title: '⚠️ แพ้ยา: $allergy',
            message:
                'ผู้รับบริการแพ้ "$allergy" — ผลิตภัณฑ์ "$product" อาจเกี่ยวข้อง กรุณาตรวจสอบก่อนใช้',
          ));
        }
      }
    }

    if (patient.drugAllergies.isNotEmpty && warnings.isEmpty) {
      warnings.add(SafetyWarning(
        level: WarningLevel.info,
        title: 'ข้อมูลการแพ้ยา',
        message: 'ผู้รับบริการมีประวัติแพ้: ${patient.drugAllergies.join(", ")}',
      ));
    }

    return warnings;
  }

  /// Check retinoid usage — contraindicated with certain treatments.
  static List<SafetyWarning> _checkRetinoids(
    Patient patient,
    TreatmentCategory category,
  ) {
    if (!patient.isUsingRetinoids) return [];

    if (category == TreatmentCategory.laser ||
        category == TreatmentCategory.treatment) {
      return [
        const SafetyWarning(
          level: WarningLevel.caution,
          title: '💊 ใช้ Retinoids อยู่',
          message:
              'ผู้รับบริการกำลังใช้ Retinoids — อาจเพิ่มความเสี่ยงผิวลอก/แดง จาก Laser/Treatment ควรหยุดก่อนอย่างน้อย 3-7 วัน',
        ),
      ];
    }
    return [];
  }

  /// Check anticoagulant usage — risk of bruising with injectables.
  static List<SafetyWarning> _checkAnticoagulant(
    Patient patient,
    TreatmentCategory category,
  ) {
    if (!patient.isOnAnticoagulant) return [];

    if (category == TreatmentCategory.injectable) {
      return [
        const SafetyWarning(
          level: WarningLevel.caution,
          title: '💉 ทานยาละลายลิ่มเลือด',
          message:
              'ผู้รับบริการทานยาละลายลิ่มเลือด — เพิ่มความเสี่ยงช้ำ/เลือดออกจากการฉีด ควรแจ้งและระวังเป็นพิเศษ',
        ),
      ];
    }
    return [];
  }

  /// Check timing rules — minimum days between treatments.
  static List<SafetyWarning> _checkTimingRules(
    String treatmentName,
    List<TreatmentRecord> history,
    List<TreatmentRule> rules,
  ) {
    final warnings = <SafetyWarning>[];

    final rule = rules.where(
      (r) => r.treatmentType.toLowerCase() == treatmentName.toLowerCase(),
    );

    if (rule.isEmpty) return warnings;

    final matchingRule = rule.first;
    final lastTreatment = history.where(
      (r) => r.treatmentName.toLowerCase() == treatmentName.toLowerCase(),
    );

    if (lastTreatment.isEmpty) return warnings;

    final last = lastTreatment.first;
    final daysSinceLast = DateTime.now().difference(last.date).inDays;

    if (daysSinceLast < matchingRule.repeatMinDays) {
      warnings.add(SafetyWarning(
        level: WarningLevel.danger,
        title: '⏰ ระยะเวลาไม่ถึง (ขั้นต่ำ)',
        message:
            'ทำ "$treatmentName" ล่าสุดเมื่อ $daysSinceLast วันที่แล้ว — ต้องเว้นอย่างน้อย ${matchingRule.repeatMinDays} วัน',
      ));
    } else if (daysSinceLast < matchingRule.repeatIdealDays) {
      warnings.add(SafetyWarning(
        level: WarningLevel.caution,
        title: '⏰ ระยะเวลาน้อยกว่าที่แนะนำ',
        message:
            'ทำ "$treatmentName" ล่าสุดเมื่อ $daysSinceLast วันที่แล้ว — แนะนำเว้น ${matchingRule.repeatIdealDays} วัน',
      ));
    }

    return warnings;
  }

  /// Check contraindications from treatment rules.
  static List<SafetyWarning> _checkContraindications(
    String treatmentName,
    List<TreatmentRule> rules,
  ) {
    final rule = rules.where(
      (r) => r.treatmentType.toLowerCase() == treatmentName.toLowerCase(),
    );

    if (rule.isEmpty || rule.first.contraindications.isEmpty) return [];

    return [
      SafetyWarning(
        level: WarningLevel.info,
        title: '📋 ข้อห้ามใช้ / Contraindications',
        message: rule.first.contraindications.join(', '),
      ),
    ];
  }

  /// Check medical conditions against treatment category.
  static List<SafetyWarning> _checkMedicalConditions(
    Patient patient,
    TreatmentCategory category,
  ) {
    final warnings = <SafetyWarning>[];
    if (patient.medicalConditions.isEmpty) return warnings;

    final conditions = patient.medicalConditions.map((c) => c.toLowerCase()).toList();

    if (conditions.any((c) => c.contains('keloid')) &&
        category == TreatmentCategory.injectable) {
      warnings.add(const SafetyWarning(
        level: WarningLevel.caution,
        title: '🩹 ประวัติ Keloid',
        message: 'ผู้รับบริการมีประวัติ Keloid — ควรระวังการฉีดและแจ้งผู้รับบริการ',
      ));
    }

    if (conditions.any((c) => c.contains('diabetes') || c.contains('เบาหวาน'))) {
      warnings.add(const SafetyWarning(
        level: WarningLevel.caution,
        title: '🩸 โรคเบาหวาน',
        message: 'ผู้รับบริการมีโรคเบาหวาน — การหายของแผลอาจช้ากว่าปกติ',
      ));
    }

    if (conditions.any((c) =>
        c.contains('autoimmune') || c.contains('lupus') || c.contains('sle'))) {
      warnings.add(const SafetyWarning(
        level: WarningLevel.danger,
        title: '🛡️ โรคภูมิคุ้มกันทำลายตนเอง',
        message:
            'ผู้รับบริการมีโรค Autoimmune — Filler/Biostimulator อาจกระตุ้นอาการกำเริบ ต้องปรึกษาแพทย์ก่อน',
      ));
    }

    return warnings;
  }

  /// Check pregnancy risk for young female patients.
  static List<SafetyWarning> _checkPregnancyAge(Patient patient) {
    if (patient.gender != GenderType.female) return [];
    final age = patient.age;
    if (age == null || age < 15 || age > 50) return [];

    return [
      const SafetyWarning(
        level: WarningLevel.info,
        title: '🤰 ตรวจสอบการตั้งครรภ์',
        message: 'ผู้รับบริการเพศหญิงวัยเจริญพันธุ์ — ควรสอบถามเรื่องการตั้งครรภ์/ให้นมบุตรก่อนทำหัตถการ',
      ),
    ];
  }
}
