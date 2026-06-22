import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/models/models.dart';
import 'package:airamd/features/patients/consent_form_screen.dart';

void main() {
  group('ConsentForm world-class fields', () {
    test('toInsertJson includes new signing/audit fields', () {
      final form = ConsentForm(
        id: '',
        clinicId: 'c1',
        patientId: 'p1',
        signatureUrl: 'sig.png',
        signedAt: DateTime.parse('2026-06-23T10:00:00Z'),
        doctorId: 'd1',
        doctorSignatureUrl: 'doc.png',
        witnessSignatureUrl: 'wit.png',
        witness2Name: 'พยานสอง',
        witness2SignatureUrl: 'wit2.png',
        signedNameTyped: 'สมหญิง ใจดี',
        templateVersion: 3,
        acknowledgedItems: const ['risk a', 'risk b'],
        deviceInfo: 'iOS',
      );
      final json = form.toInsertJson();
      expect(json['doctor_id'], 'd1');
      expect(json['doctor_signature_url'], 'doc.png');
      expect(json['witness_signature_url'], 'wit.png');
      expect(json['witness2_name'], 'พยานสอง');
      expect(json['witness2_signature_url'], 'wit2.png');
      expect(json['signed_name_typed'], 'สมหญิง ใจดี');
      expect(json['template_version'], 3);
      expect(json['acknowledged_items'], ['risk a', 'risk b']);
      expect(json['device_info'], 'iOS');
    });

    test('fromJson round-trips new fields', () {
      final form = ConsentForm.fromJson({
        'id': 'f1',
        'clinic_id': 'c1',
        'patient_id': 'p1',
        'signature_url': 'sig.png',
        'signed_at': '2026-06-23T10:00:00Z',
        'template_version': 2,
        'acknowledged_items': ['x'],
        'signed_name_typed': 'A B',
      });
      expect(form.templateVersion, 2);
      expect(form.acknowledgedItems, ['x']);
      expect(form.signedNameTyped, 'A B');
    });
  });

  group('ConsentFormTemplate version', () {
    test('defaults to 1 and copyWith bumps version', () {
      const t = ConsentFormTemplate(
        id: 't1',
        clinicId: 'c1',
        name: 'Laser',
        content: 'body',
      );
      expect(t.version, 1);
      expect(t.copyWith(version: t.version + 1).version, 2);
      expect(t.toUpdateJson()['version'], 1);
    });
  });

  group('ClinicDevice model', () {
    test('round-trips via json', () {
      final d = ClinicDevice.fromJson({
        'id': 'dev1',
        'clinic_id': 'c1',
        'name': 'Ulthera Prime',
        'category': 'LASER',
        'is_active': true,
      });
      expect(d.name, 'Ulthera Prime');
      expect(d.category, 'LASER');
      final json = d.toInsertJson();
      expect(json['name'], 'Ulthera Prime');
      expect(json['category'], 'LASER');
    });
  });

  group('parseRiskItems', () {
    test('extracts bullet lines after the เช่น marker', () {
      const content = '''
หัวข้อ
แพทย์อธิบายผลข้างเคียงที่อาจเกิดขึ้นได้ เช่น
อาจมีรอยแดงเล็กน้อย
อาจมีสะเก็ดบางๆ
หนังสือฉบับนี้ทำขึ้น ณ วันที่
''';
      final items = parseRiskItems(content);
      expect(items.length, 2);
      expect(items.first, 'อาจมีรอยแดงเล็กน้อย');
      expect(items.last, 'อาจมีสะเก็ดบางๆ');
    });

    test('returns empty when no marker present', () {
      expect(parseRiskItems('no marker here\njust text'), isEmpty);
    });
  });
}
