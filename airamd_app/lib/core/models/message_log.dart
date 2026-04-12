import 'enums.dart';

class MessageLog {
  final String id;
  final String clinicId;
  final String patientId;
  final MessageChannel channel;
  final MessageTemplateType templateType;
  final String? messageContent;
  final MessageStatus status;
  final String? sentBy;
  final DateTime? sentAt;
  final DateTime? createdAt;

  const MessageLog({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.channel,
    this.templateType = MessageTemplateType.custom,
    this.messageContent,
    this.status = MessageStatus.pending,
    this.sentBy,
    this.sentAt,
    this.createdAt,
  });

  factory MessageLog.fromJson(Map<String, dynamic> json) => MessageLog(
        id: json['id'] as String,
        clinicId: json['clinic_id'] as String,
        patientId: json['patient_id'] as String,
        channel: MessageChannel.fromDb(json['channel'] as String?),
        templateType:
            MessageTemplateType.fromDb(json['template_type'] as String?),
        messageContent: json['message_content'] as String?,
        status: MessageStatus.fromDb(json['status'] as String?),
        sentBy: json['sent_by'] as String?,
        sentAt: json['sent_at'] != null
            ? DateTime.tryParse(json['sent_at'].toString())
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'clinic_id': clinicId,
        'patient_id': patientId,
        'channel': channel.dbValue,
        'template_type': templateType.dbValue,
        if (messageContent != null) 'message_content': messageContent,
        'status': status.dbValue,
        if (sentBy != null) 'sent_by': sentBy,
        if (sentAt != null) 'sent_at': sentAt!.toIso8601String(),
      };
}
