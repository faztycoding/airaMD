import 'enums.dart';

class InventoryTransaction {
  final String id;
  final String clinicId;
  final String productId;
  final String? treatmentRecordId;
  final String? patientId;
  final InventoryTransactionType transactionType;
  final double quantity;
  final String? unit;
  final String? batchNo;
  final DateTime? expiryDate;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;

  const InventoryTransaction({
    required this.id,
    required this.clinicId,
    required this.productId,
    this.treatmentRecordId,
    this.patientId,
    required this.transactionType,
    required this.quantity,
    this.unit,
    this.batchNo,
    this.expiryDate,
    this.notes,
    this.createdBy,
    this.createdAt,
  });

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) =>
      InventoryTransaction(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        productId: json['product_id'] as String,
        treatmentRecordId: json['treatment_record_id'] as String?,
        patientId: json['patient_id'] as String?,
        transactionType:
            InventoryTransactionType.fromDb(json['transaction_type'] as String?),
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String?,
        batchNo: json['batch_no'] as String?,
        expiryDate: json['expiry_date'] != null
            ? DateTime.tryParse(json['expiry_date'].toString())
            : null,
        notes: json['notes'] as String?,
        createdBy: json['created_by'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'product_id': productId,
        if (treatmentRecordId != null) 'treatment_record_id': treatmentRecordId,
        if (patientId != null) 'patient_id': patientId,
        'transaction_type': transactionType.dbValue,
        'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (batchNo != null) 'batch_no': batchNo,
        if (expiryDate != null)
          'expiry_date': expiryDate!.toIso8601String().split('T').first,
        if (notes != null) 'notes': notes,
        if (createdBy != null) 'created_by': createdBy,
      };
}
