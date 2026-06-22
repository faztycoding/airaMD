import '../repositories/_helpers.dart';

class ConsentForm {
  final String id;
  final String clinicId;
  final String patientId;
  final String? treatmentRecordId;
  final String? formTemplateId;
  final String signatureUrl;
  final DateTime signedAt;
  final String? witnessName;
  final String? pdfUrl;
  final String? procedure;
  final List<String> consentedItems;
  final String? notes;
  final DateTime? createdAt;
  // ─── World-class consent fields (migration 025) ───
  final String? doctorId;
  final String? doctorSignatureUrl;
  final String? witnessSignatureUrl;
  final String? witness2Name;
  final String? witness2SignatureUrl;
  final String? signedNameTyped;
  final int? templateVersion;
  final List<String> acknowledgedItems;
  final String? deviceInfo;

  const ConsentForm({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.treatmentRecordId,
    this.formTemplateId,
    required this.signatureUrl,
    required this.signedAt,
    this.witnessName,
    this.pdfUrl,
    this.procedure,
    this.consentedItems = const [],
    this.notes,
    this.createdAt,
    this.doctorId,
    this.doctorSignatureUrl,
    this.witnessSignatureUrl,
    this.witness2Name,
    this.witness2SignatureUrl,
    this.signedNameTyped,
    this.templateVersion,
    this.acknowledgedItems = const [],
    this.deviceInfo,
  });

  factory ConsentForm.fromJson(Map<String, dynamic> json) => ConsentForm(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        patientId: json['patient_id'] as String,
        treatmentRecordId: json['treatment_record_id'] as String?,
        formTemplateId: json['form_template_id'] as String?,
        signatureUrl: json['signature_url'] as String,
        signedAt: DateTime.parse(json['signed_at'].toString()),
        witnessName: json['witness_name'] as String?,
        pdfUrl: json['pdf_url'] as String?,
        procedure: json['procedure'] as String?,
        consentedItems: parseStringList(json['consented_items']),
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        doctorId: json['doctor_id'] as String?,
        doctorSignatureUrl: json['doctor_signature_url'] as String?,
        witnessSignatureUrl: json['witness_signature_url'] as String?,
        witness2Name: json['witness2_name'] as String?,
        witness2SignatureUrl: json['witness2_signature_url'] as String?,
        signedNameTyped: json['signed_name_typed'] as String?,
        templateVersion: json['template_version'] as int?,
        acknowledgedItems: parseStringList(json['acknowledged_items']),
        deviceInfo: json['device_info'] as String?,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'patient_id': patientId,
        if (treatmentRecordId != null) 'treatment_record_id': treatmentRecordId,
        if (formTemplateId != null) 'form_template_id': formTemplateId,
        'signature_url': signatureUrl,
        'signed_at': signedAt.toIso8601String(),
        if (witnessName != null) 'witness_name': witnessName,
        if (pdfUrl != null) 'pdf_url': pdfUrl,
        if (procedure != null) 'procedure': procedure,
        'consented_items': consentedItems,
        if (notes != null) 'notes': notes,
        if (doctorId != null) 'doctor_id': doctorId,
        if (doctorSignatureUrl != null)
          'doctor_signature_url': doctorSignatureUrl,
        if (witnessSignatureUrl != null)
          'witness_signature_url': witnessSignatureUrl,
        if (witness2Name != null) 'witness2_name': witness2Name,
        if (witness2SignatureUrl != null)
          'witness2_signature_url': witness2SignatureUrl,
        if (signedNameTyped != null) 'signed_name_typed': signedNameTyped,
        if (templateVersion != null) 'template_version': templateVersion,
        'acknowledged_items': acknowledgedItems,
        if (deviceInfo != null) 'device_info': deviceInfo,
      };
}
