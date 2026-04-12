import 'enums.dart';

class FaceDiagram {
  final String id;
  final String clinicId;
  final String patientId;
  final String? treatmentRecordId;
  final String imageUrl;
  final DiagramView viewType;
  final List<dynamic> strokesData;
  final List<dynamic> markersData;
  final DateTime? createdAt;

  const FaceDiagram({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.treatmentRecordId,
    required this.imageUrl,
    this.viewType = DiagramView.front,
    this.strokesData = const [],
    this.markersData = const [],
    this.createdAt,
  });

  factory FaceDiagram.fromJson(Map<String, dynamic> json) => FaceDiagram(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        patientId: json['patient_id'] as String,
        treatmentRecordId: json['treatment_record_id'] as String?,
        imageUrl: json['image_url'] as String,
        viewType: DiagramView.fromDb(json['view_type'] as String?),
        strokesData: (json['strokes_data'] as List<dynamic>?) ?? [],
        markersData: (json['markers_data'] as List<dynamic>?) ?? [],
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'patient_id': patientId,
        if (treatmentRecordId != null) 'treatment_record_id': treatmentRecordId,
        'image_url': imageUrl,
        'view_type': viewType.dbValue,
        'strokes_data': strokesData,
        'markers_data': markersData,
      };

  Map<String, dynamic> toUpdateJson() => {
        'image_url': imageUrl,
        'view_type': viewType.dbValue,
        'strokes_data': strokesData,
        'markers_data': markersData,
      };
}
