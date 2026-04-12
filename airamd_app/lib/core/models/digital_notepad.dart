class DigitalNotepad {
  final String id;
  final String clinicId;
  final String patientId;
  final String? title;
  final Map<String, dynamic> canvasData;
  final String? imageUrl;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DigitalNotepad({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.title,
    this.canvasData = const {},
    this.imageUrl,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory DigitalNotepad.fromJson(Map<String, dynamic> json) => DigitalNotepad(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        patientId: json['patient_id'] as String,
        title: json['title'] as String?,
        canvasData: (json['canvas_data'] as Map<String, dynamic>?) ?? {},
        imageUrl: json['image_url'] as String?,
        createdBy: json['created_by'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'patient_id': patientId,
        if (title != null) 'title': title,
        'canvas_data': canvasData,
        if (imageUrl != null) 'image_url': imageUrl,
        if (createdBy != null) 'created_by': createdBy,
      };

  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'canvas_data': canvasData,
        'image_url': imageUrl,
      };
}
