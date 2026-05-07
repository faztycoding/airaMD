import 'patient.dart';
import 'treatment_record.dart';
import 'appointment.dart';
import 'course.dart';

/// Typed wrapper around the JSONB returned by the `get_patient_full` RPC.
///
/// Replaces the 4-5 sequential `FutureProvider` calls the patient profile
/// screen used to make (one for the patient row, one for treatments, one for
/// appointments, one for courses, one for outstanding balance) with a single
/// round trip — substantial latency win on slow / rural connections.
///
/// Tab-specific deep data (messages, notepads, photos) is intentionally
/// NOT bundled here: those are loaded lazily when the user opens the
/// relevant tab so the dashboard render stays cheap.
class PatientProfileBundle {
  final Patient patient;
  final List<TreatmentRecord> recentTreatments;
  final List<Appointment> recentAppointments;
  final List<Course> courses;

  /// Sum of all outstanding charges minus payments. Positive = patient owes
  /// the clinic; negative = clinic owes the patient (rare, e.g. a refund
  /// that hasn't been disbursed yet).
  final double outstandingTotal;

  const PatientProfileBundle({
    required this.patient,
    required this.recentTreatments,
    required this.recentAppointments,
    required this.courses,
    required this.outstandingTotal,
  });

  factory PatientProfileBundle.fromJson(Map<String, dynamic> json) {
    final patientJson = Map<String, dynamic>.from(json['patient'] as Map);
    final treatments = (json['recent_treatments'] as List? ?? const [])
        .cast<Map>()
        .map((m) => TreatmentRecord.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    final appointments = (json['recent_appointments'] as List? ?? const [])
        .cast<Map>()
        .map((m) => Appointment.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    final courses = (json['courses'] as List? ?? const [])
        .cast<Map>()
        .map((m) => Course.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    final outstanding = (json['outstanding_total'] as num?)?.toDouble() ?? 0.0;

    return PatientProfileBundle(
      patient: Patient.fromJson(patientJson),
      recentTreatments: treatments,
      recentAppointments: appointments,
      courses: courses,
      outstandingTotal: outstanding,
    );
  }
}
