import 'enums.dart';

class PatientPhoto {
  final String id;
  final String clinicId;
  final String patientId;
  final String? treatmentRecordId;
  final PhotoType imageType;
  final String storagePath;
  final String? thumbnailPath;
  final DateTime? treatmentDate;
  final String? description;
  final int sortOrder;
  final DateTime? createdAt;

  const PatientPhoto({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.treatmentRecordId,
    this.imageType = PhotoType.other,
    required this.storagePath,
    this.thumbnailPath,
    this.treatmentDate,
    this.description,
    this.sortOrder = 0,
    this.createdAt,
  });

  factory PatientPhoto.fromJson(Map<String, dynamic> json) => PatientPhoto(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        patientId: json['patient_id'] as String,
        treatmentRecordId: json['treatment_record_id'] as String?,
        imageType: PhotoType.fromDb(json['image_type'] as String?),
        storagePath: json['storage_path'] as String,
        thumbnailPath: json['thumbnail_path'] as String?,
        treatmentDate: json['treatment_date'] != null
            ? DateTime.tryParse(json['treatment_date'].toString())
            : null,
        description: json['description'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'patient_id': patientId,
        if (treatmentRecordId != null) 'treatment_record_id': treatmentRecordId,
        'image_type': imageType.dbValue,
        'storage_path': storagePath,
        if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
        if (treatmentDate != null)
          'treatment_date': treatmentDate!.toIso8601String().split('T').first,
        if (description != null) 'description': description,
        'sort_order': sortOrder,
      };
}
