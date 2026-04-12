class AuditLog {
  final String id;
  final String clinicId;
  final String? userId;
  final String action;
  final String? entityType;
  final String? entityId;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String? ipAddress;
  final DateTime? timestamp;

  const AuditLog({
    required this.id,
    required this.clinicId,
    this.userId,
    required this.action,
    this.entityType,
    this.entityId,
    this.oldData,
    this.newData,
    this.ipAddress,
    this.timestamp,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        userId: json['user_id'] as String?,
        action: json['action'] as String,
        entityType: json['entity_type'] as String?,
        entityId: json['entity_id'] as String?,
        oldData: json['old_data'] as Map<String, dynamic>?,
        newData: json['new_data'] as Map<String, dynamic>?,
        ipAddress: json['ip_address'] as String?,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        if (userId != null) 'user_id': userId,
        'action': action,
        if (entityType != null) 'entity_type': entityType,
        if (entityId != null) 'entity_id': entityId,
        if (oldData != null) 'old_data': oldData,
        if (newData != null) 'new_data': newData,
        if (ipAddress != null) 'ip_address': ipAddress,
      };
}
