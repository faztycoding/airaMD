import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/repository_providers.dart';
import '../providers/auth_providers.dart';

// ═══════════════════════════════════════════════════════════════
// MESSAGING SERVICE — LINE OA API + WhatsApp + SMS + Deep Links
// ═══════════════════════════════════════════════════════════════

/// Configuration keys for secure storage.
const _lineChannelTokenKey = 'aira_line_channel_token';
const _lineChannelSecretKey = 'aira_line_channel_secret';
const _smsEnabledKey = 'aira_sms_enabled';

/// Result of a send message operation.
class SendMessageResult {
  final bool success;
  final MessageStatus status;
  final String? error;
  final String? externalMessageId;

  const SendMessageResult({
    required this.success,
    required this.status,
    this.error,
    this.externalMessageId,
  });
}

/// Comprehensive messaging service that:
/// 1. Sends via LINE Messaging API (when configured)
/// 2. Falls back to deep links (LINE/WhatsApp)
/// 3. Supports SMS via device
/// 4. Logs all messages to Supabase
class MessagingService {
  final Ref _ref;
  static const _storage = FlutterSecureStorage();

  MessagingService(this._ref);

  // ─── LINE OA API Integration ──────────────────────────────

  /// Send message via LINE Messaging API.
  /// Requires LINE Channel Access Token to be configured.
  Future<SendMessageResult> sendViaLineApi({
    required String lineUserId,
    required String message,
  }) async {
    final token = await getLineChannelToken();
    if (token == null || token.isEmpty) {
      return const SendMessageResult(
        success: false,
        status: MessageStatus.pending,
        error: 'LINE Channel Token not configured',
      );
    }

    try {
      // Call LINE Messaging API via Supabase Edge Function
      final response = await _ref.read(supabaseClientProvider).functions.invoke(
        'send-line-message',
        body: {
          'to': lineUserId,
          'message': message,
          'channel_token': token,
        },
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>?;
        return SendMessageResult(
          success: true,
          status: MessageStatus.sent,
          externalMessageId: data?['message_id'] as String?,
        );
      } else {
        return SendMessageResult(
          success: false,
          status: MessageStatus.failed,
          error: 'LINE API error: ${response.status}',
        );
      }
    } catch (e) {
      debugPrint('[MessagingService] LINE API error: $e');
      return SendMessageResult(
        success: false,
        status: MessageStatus.failed,
        error: '$e',
      );
    }
  }

  // ─── Deep Link Fallback ──────────────────────────────────

  /// Open LINE chat via deep link.
  Future<bool> openLineDeepLink(String lineId) async {
    final uri = Uri.parse('https://line.me/R/ti/p/$lineId');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  /// Open WhatsApp via deep link with pre-filled message.
  Future<bool> openWhatsAppDeepLink(String phone, {String? message}) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final encoded = message != null ? Uri.encodeComponent(message) : '';
    final url = message != null
        ? 'https://wa.me/$cleaned?text=$encoded'
        : 'https://wa.me/$cleaned';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  /// Open SMS with pre-filled message.
  Future<bool> openSms(String phone, {String? message}) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = message != null
        ? Uri.parse('sms:$cleaned?body=${Uri.encodeComponent(message)}')
        : Uri.parse('sms:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  /// Open phone call.
  Future<bool> openPhone(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'[^0-9+]'), '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    return false;
  }

  // ─── Unified Send ────────────────────────────────────────

  /// Send a message through the specified channel.
  /// Attempts API-based sending first, falls back to deep links.
  /// Always logs the message.
  Future<SendMessageResult> sendMessage({
    required String patientId,
    required Patient patient,
    required MessageChannel channel,
    required MessageTemplateType templateType,
    required String content,
  }) async {
    final clinicId = _ref.read(currentClinicIdProvider);
    if (clinicId == null) {
      return const SendMessageResult(
        success: false,
        status: MessageStatus.failed,
        error: 'No clinic ID',
      );
    }

    SendMessageResult result;

    // Try API-based sending first
    if (channel == MessageChannel.line && patient.lineId != null) {
      result = await sendViaLineApi(
        lineUserId: patient.lineId!,
        message: content,
      );

      // If API not configured, fall back to deep link
      if (!result.success && result.error?.contains('not configured') == true) {
        final opened = await openLineDeepLink(patient.lineId!);
        result = SendMessageResult(
          success: opened,
          status: opened ? MessageStatus.sent : MessageStatus.failed,
          error: opened ? null : 'Could not open LINE',
        );
      }
    } else if (channel == MessageChannel.whatsapp && patient.phone != null) {
      final opened = await openWhatsAppDeepLink(patient.phone!, message: content);
      result = SendMessageResult(
        success: opened,
        status: opened ? MessageStatus.sent : MessageStatus.failed,
        error: opened ? null : 'Could not open WhatsApp',
      );
    } else {
      result = const SendMessageResult(
        success: false,
        status: MessageStatus.failed,
        error: 'No contact info for this channel',
      );
    }

    // Log the message regardless of outcome
    try {
      final repo = _ref.read(messageRepoProvider);
      await repo.create(MessageLog(
        id: const Uuid().v4(),
        clinicId: clinicId,
        patientId: patientId,
        channel: channel,
        templateType: templateType,
        messageContent: content,
        status: result.status,
        sentAt: result.success ? DateTime.now() : null,
      ));
    } catch (e) {
      debugPrint('[MessagingService] Log error: $e');
    }

    return result;
  }

  // ─── LINE Configuration ──────────────────────────────────

  /// Get stored LINE Channel Access Token.
  static Future<String?> getLineChannelToken() async {
    return _storage.read(key: _lineChannelTokenKey);
  }

  /// Store LINE Channel Access Token.
  static Future<void> setLineChannelToken(String token) async {
    await _storage.write(key: _lineChannelTokenKey, value: token);
  }

  /// Get stored LINE Channel Secret.
  static Future<String?> getLineChannelSecret() async {
    return _storage.read(key: _lineChannelSecretKey);
  }

  /// Store LINE Channel Secret.
  static Future<void> setLineChannelSecret(String secret) async {
    await _storage.write(key: _lineChannelSecretKey, value: secret);
  }

  /// Check if LINE API is configured.
  static Future<bool> isLineApiConfigured() async {
    final token = await getLineChannelToken();
    return token != null && token.isNotEmpty;
  }

  // ─── SMS Configuration ───────────────────────────────────

  /// Check if SMS is enabled.
  static Future<bool> isSmsEnabled() async {
    final v = await _storage.read(key: _smsEnabledKey);
    return v == 'true';
  }

  /// Toggle SMS.
  static Future<void> setSmsEnabled(bool enabled) async {
    await _storage.write(key: _smsEnabledKey, value: enabled.toString());
  }

  // ─── Template Helpers ────────────────────────────────────

  /// Generate message content from template.
  static String generateFromTemplate({
    required MessageTemplateType templateType,
    required String patientName,
    String? clinicName,
    DateTime? appointmentTime,
    String? treatmentName,
    bool isThai = true,
  }) {
    final name = patientName;
    final clinic = clinicName ?? '';

    return switch (templateType) {
      MessageTemplateType.appointment => isThai
          ? 'สวัสดีค่ะ คุณ$name\nขอแจ้งเตือนนัดหมายการรักษาของท่าน'
            '${appointmentTime != null ? '\nวันที่: ${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year}' : ''}'
            '${treatmentName != null ? '\nหัตถการ: $treatmentName' : ''}'
            '\nกรุณามาถึงคลินิกก่อนเวลานัด 15 นาทีค่ะ'
            '${clinic.isNotEmpty ? '\n\n$clinic' : ''}'
          : 'Hello $name,\nThis is a reminder for your upcoming appointment.'
            '${appointmentTime != null ? '\nDate: ${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year}' : ''}'
            '${treatmentName != null ? '\nProcedure: $treatmentName' : ''}'
            '\nPlease arrive 15 minutes early.'
            '${clinic.isNotEmpty ? '\n\n$clinic' : ''}',
      MessageTemplateType.confirmation => isThai
          ? 'สวัสดีค่ะ คุณ$name\nขอยืนยันนัดหมายของท่านเรียบร้อยแล้วค่ะ'
            '${appointmentTime != null ? '\nวันที่: ${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year}' : ''}'
            '${clinic.isNotEmpty ? '\n\n$clinic' : ''}'
          : 'Hello $name,\nYour appointment has been confirmed.'
            '${appointmentTime != null ? '\nDate: ${appointmentTime.day}/${appointmentTime.month}/${appointmentTime.year}' : ''}'
            '${clinic.isNotEmpty ? '\n\n$clinic' : ''}',
      MessageTemplateType.afterCare => isThai
          ? 'สวัสดีค่ะ คุณ$name\nคำแนะนำหลังทำหัตถการ:\n- หลีกเลี่ยงแสงแดดจ้า 2 สัปดาห์\n- งดสัมผัสบริเวณที่ทำ 24 ชม.\n- ทาครีมกันแดด SPF 30+ ทุกวัน\n- หากมีอาการผิดปกติ กรุณาติดต่อคลินิกค่ะ'
            '${clinic.isNotEmpty ? '\n\n$clinic' : ''}'
          : 'Hello $name,\nPost-treatment care instructions:\n- Avoid direct sunlight for 2 weeks\n- Do not touch treated area for 24h\n- Apply sunscreen SPF 30+ daily\n- Contact us if you experience any issues.'
            '${clinic.isNotEmpty ? '\n\n$clinic' : ''}',
      MessageTemplateType.promotion => isThai
          ? 'สวัสดีค่ะ คุณ$name\nมีโปรโมชั่นพิเศษสำหรับท่าน!\nสอบถามรายละเอียดได้ที่คลินิกค่ะ'
            '${clinic.isNotEmpty ? '\n\n$clinic' : ''}'
          : 'Hello $name,\nWe have a special promotion for you!\nContact us for details.'
            '${clinic.isNotEmpty ? '\n\n$clinic' : ''}',
      MessageTemplateType.custom => '',
    };
  }
}

// ─── Riverpod Provider ──────────────────────────────────────

final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService(ref);
});

/// Whether LINE API is configured.
final lineApiConfiguredProvider = FutureProvider<bool>((ref) async {
  return MessagingService.isLineApiConfigured();
});
