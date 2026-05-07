import 'package:flutter_test/flutter_test.dart';
import 'package:airamd/core/models/models.dart';

void main() {
  group('PatientProfileBundle.fromJson', () {
    test('parses the full RPC envelope into typed lists', () {
      final json = {
        'patient': {
          'id': 'p-1',
          'clinic_id': 'c-1',
          'first_name': 'Anna',
          'last_name': 'Test',
          'hn': 'C-2026-00001',
          'gender': 'FEMALE',
          'created_at': '2026-04-01T10:00:00Z',
        },
        'recent_treatments': [
          {
            'id': 'tr-1',
            'clinic_id': 'c-1',
            'patient_id': 'p-1',
            'date': '2026-04-13T09:00:00Z',
            'category': 'INJECTABLE',
            'treatment_name': 'Botox',
            'version': 3,
          },
        ],
        'recent_appointments': [
          {
            'id': 'ap-1',
            'clinic_id': 'c-1',
            'patient_id': 'p-1',
            'date': '2026-05-01',
            'start_time': '10:00',
            'end_time': '10:30',
            'status': 'BOOKED',
          },
        ],
        'courses': [
          {
            'id': 'co-1',
            'clinic_id': 'c-1',
            'patient_id': 'p-1',
            'name': 'Laser Package',
            'total_sessions': 6,
            'sessions_used': 2,
          },
        ],
        'outstanding_total': 1500.5,
      };

      final bundle = PatientProfileBundle.fromJson(json);

      expect(bundle.patient.id, 'p-1');
      expect(bundle.patient.firstName, 'Anna');
      expect(bundle.recentTreatments, hasLength(1));
      expect(bundle.recentTreatments.single.treatmentName, 'Botox');
      expect(bundle.recentTreatments.single.version, 3);
      expect(bundle.recentAppointments, hasLength(1));
      expect(bundle.courses, hasLength(1));
      expect(bundle.outstandingTotal, 1500.5);
    });

    test('handles empty arrays / zero balance gracefully', () {
      final json = {
        'patient': {
          'id': 'p-2',
          'clinic_id': 'c-1',
          'first_name': 'Empty',
          'last_name': 'Patient',
          'hn': 'C-2026-00002',
        },
        'recent_treatments': [],
        'recent_appointments': [],
        'courses': [],
        'outstanding_total': 0,
      };

      final bundle = PatientProfileBundle.fromJson(json);
      expect(bundle.patient.id, 'p-2');
      expect(bundle.recentTreatments, isEmpty);
      expect(bundle.recentAppointments, isEmpty);
      expect(bundle.courses, isEmpty);
      expect(bundle.outstandingTotal, 0);
    });

    test('treats missing optional keys as defaults instead of throwing', () {
      // The RPC always returns the keys, but defensive parsing keeps the
      // app from crashing on a malformed response.
      final json = {
        'patient': {
          'id': 'p-3',
          'clinic_id': 'c-1',
          'first_name': 'Solo',
          'last_name': 'Patient',
          'hn': 'C-2026-00003',
        },
      };
      final bundle = PatientProfileBundle.fromJson(json);
      expect(bundle.recentTreatments, isEmpty);
      expect(bundle.recentAppointments, isEmpty);
      expect(bundle.courses, isEmpty);
      expect(bundle.outstandingTotal, 0);
    });
  });
}
