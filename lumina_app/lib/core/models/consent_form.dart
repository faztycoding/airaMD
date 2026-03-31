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
        consentedItems: _parseStringList(json['consented_items']),
        notes: json['notes'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
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
      };

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}
