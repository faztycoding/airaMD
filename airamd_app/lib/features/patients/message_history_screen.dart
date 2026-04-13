import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/aira_premium_form.dart';
import '../../core/localization/app_localizations.dart';

// ─── Providers ────────────────────────────────────────────────
final _messagesByPatientProvider =
    FutureProvider.family<List<MessageLog>, String>((ref, patientId) {
  final repo = ref.watch(messageRepoProvider);
  return repo.getByPatient(patientId: patientId);
});

// ═══════════════════════════════════════════════════════════════
// MESSAGE HISTORY TAB — embedded in patient profile
// ═══════════════════════════════════════════════════════════════
class MessageHistoryTab extends ConsumerStatefulWidget {
  final String patientId;
  final Patient? patient;
  const MessageHistoryTab({super.key, required this.patientId, this.patient});

  @override
  ConsumerState<MessageHistoryTab> createState() => _MessageHistoryTabState();
}

class _MessageHistoryTabState extends ConsumerState<MessageHistoryTab> {
  bool _sending = false;

  // ─── Deep link launchers ───
  Future<void> _openLine(String lineId) async {
    final uri = Uri.parse('https://line.me/R/ti/p/$lineId');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ─── Send message + log ───
  Future<void> _sendMessage({
    required MessageChannel channel,
    required MessageTemplateType templateType,
    required String content,
  }) async {
    setState(() => _sending = true);
    final clinicId = ref.read(currentClinicIdProvider);
    if (clinicId == null) {
      setState(() => _sending = false);
      return;
    }

    try {
      final repo = ref.read(messageRepoProvider);
      await repo.create(MessageLog(
        id: const Uuid().v4(),
        clinicId: clinicId,
        patientId: widget.patientId,
        channel: channel,
        templateType: templateType,
        messageContent: content,
        status: MessageStatus.sent,
        sentAt: DateTime.now(),
      ));

      // Open deep link
      final patient = widget.patient;
      if (channel == MessageChannel.line && patient?.lineId != null && patient!.lineId!.isNotEmpty) {
        await _openLine(patient.lineId!);
      } else if (channel == MessageChannel.whatsapp && patient?.phone != null && patient!.phone!.isNotEmpty) {
        await _openWhatsApp(patient.phone!);
      }

      ref.invalidate(_messagesByPatientProvider(widget.patientId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.messageSaved), backgroundColor: AiraColors.sage),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorMsg('$e')), backgroundColor: AiraColors.terra),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSendDialog() {
    final contentCtrl = TextEditingController();
    final l = context.l10n;
    final patient = widget.patient;
    final hasLine = patient?.lineId != null && patient!.lineId!.isNotEmpty;
    final hasPhone = patient?.phone != null && patient!.phone!.isNotEmpty;
    if (!hasLine && !hasPhone) return;

    var channel = hasLine ? MessageChannel.line : MessageChannel.whatsapp;
    var templateType = MessageTemplateType.custom;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l.sendMessage,
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel picker
                Text(l.channel, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _ChannelChip(
                      label: 'LINE',
                      icon: Icons.chat_rounded,
                      selected: channel == MessageChannel.line,
                      enabled: hasLine,
                      onTap: () => setDlg(() => channel = MessageChannel.line),
                    ),
                    const SizedBox(width: 8),
                    _ChannelChip(
                      label: 'WhatsApp',
                      icon: Icons.phone_android_rounded,
                      selected: channel == MessageChannel.whatsapp,
                      enabled: hasPhone,
                      onTap: () => setDlg(() => channel = MessageChannel.whatsapp),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Template type
                Text(l.typeLabel, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted)),
                const SizedBox(height: 6),
                DropdownButtonFormField<MessageTemplateType>(
                  value: templateType,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: MessageTemplateType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(_templateLabel(t, l)),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDlg(() {
                        templateType = v;
                        contentCtrl.text = _templateContent(v, patient, l.isThai);
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                // Content
                TextField(
                  controller: contentCtrl,
                  style: airaFieldTextStyle,
                  decoration: airaFieldDecoration(label: l.message, prefixIcon: Icons.message_rounded),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.cancel, style: GoogleFonts.plusJakartaSans(color: AiraColors.muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AiraColors.woodMid, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (contentCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                _sendMessage(channel: channel, templateType: templateType, content: contentCtrl.text.trim());
              },
              child: Text(l.sendAndLog, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  String _templateLabel(MessageTemplateType t, AppL10n l) => switch (t) {
    MessageTemplateType.appointment => l.templateAppointment,
    MessageTemplateType.confirmation => l.templateConfirmation,
    MessageTemplateType.afterCare => l.templateAfterCare,
    MessageTemplateType.promotion => l.templatePromotion,
    MessageTemplateType.custom => l.templateCustom,
  };

  String _templateContent(MessageTemplateType t, Patient? patient, bool isThai) {
    final name = patient?.firstName ?? '';
    return switch (t) {
      MessageTemplateType.appointment => isThai
          ? 'สวัสดีค่ะ คุณ$name\nขอแจ้งเตือนนัดหมายการรักษาของท่าน\nกรุณามาถึงคลินิกก่อนเวลานัด 15 นาทีค่ะ'
          : 'Hello $name,\nThis is a reminder for your upcoming appointment.\nPlease arrive 15 minutes early.',
      MessageTemplateType.confirmation => isThai
          ? 'สวัสดีค่ะ คุณ$name\nขอยืนยันนัดหมายของท่านเรียบร้อยแล้วค่ะ'
          : 'Hello $name,\nYour appointment has been confirmed.',
      MessageTemplateType.afterCare => isThai
          ? 'สวัสดีค่ะ คุณ$name\nคำแนะนำหลังทำหัตถการ:\n- หลีกเลี่ยงแสงแดดจ้า\n- งดสัมผัสบริเวณที่ทำ 24 ชม.\n- หากมีอาการผิดปกติ กรุณาติดต่อคลินิกค่ะ'
          : 'Hello $name,\nPost-treatment care instructions:\n- Avoid direct sunlight\n- Do not touch treated area for 24h\n- Contact us if you experience any issues.',
      MessageTemplateType.promotion => isThai
          ? 'สวัสดีค่ะ คุณ$name\nมีโปรโมชั่นพิเศษสำหรับท่าน!\nสอบถามรายละเอียดได้ที่คลินิกค่ะ'
          : 'Hello $name,\nWe have a special promotion for you!\nContact us for details.',
      MessageTemplateType.custom => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final msgsAsync = ref.watch(_messagesByPatientProvider(widget.patientId));
    final patient = widget.patient;
    final hasLine = patient?.lineId != null && patient!.lineId!.isNotEmpty;
    final hasPhone = patient?.phone != null && patient!.phone!.isNotEmpty;
    final hasMessagingChannel = hasLine || hasPhone;
    final lineId = patient?.lineId ?? '';
    final phone = patient?.phone ?? '';

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Quick actions — deep links
            if (hasMessagingChannel)
              Row(
                children: [
                  if (hasLine)
                    Expanded(
                      child: _QuickLink(
                        icon: Icons.chat_rounded,
                        label: l.openLine,
                        color: const Color(0xFF06C755),
                        onTap: () => _openLine(lineId),
                      ),
                    ),
                  if (hasPhone) ...[
                    if (hasLine) const SizedBox(width: 10),
                    Expanded(
                      child: _QuickLink(
                        icon: Icons.phone_android_rounded,
                        label: 'WhatsApp',
                        color: const Color(0xFF25D366),
                        onTap: () => _openWhatsApp(phone),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickLink(
                        icon: Icons.phone_rounded,
                        label: l.call,
                        color: AiraColors.woodMid,
                        onTap: () => _openPhone(phone),
                      ),
                    ),
                  ],
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
                ),
                child: Text(
                  l.isThai ? 'ยังไม่มีช่องทางติดต่อสำหรับการส่งข้อความ' : 'No messaging channel is available for this patient.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
                ),
              ),
            const SizedBox(height: 16),

            // Send new message button
            if (hasMessagingChannel)
              AiraTapEffect(
                onTap: _showSendDialog,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        l.sendMessageAndLog,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            if (!hasMessagingChannel)
              const SizedBox(height: 4),
            const SizedBox(height: 20),

            // History
            Text(
              l.messageHistory,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
            ),
            const SizedBox(height: 12),

            msgsAsync.when(
              data: (msgs) {
                if (msgs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.message_outlined, size: 40, color: AiraColors.muted.withValues(alpha: 0.3)),
                        const SizedBox(height: 8),
                        Text(l.noMessagesYet,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
                      ],
                    ),
                  );
                }
                return Column(
                  children: msgs.map((msg) => _MessageCard(msg: msg)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
              error: (e, _) => Text('Error: $e'),
            ),
          ],
        ),
        if (_sending)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickLink({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ChannelChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  const _ChannelChip({required this.label, required this.icon, required this.selected, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AiraColors.woodMid.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AiraColors.woodMid : AiraColors.creamDk.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: enabled ? (selected ? AiraColors.woodMid : AiraColors.charcoal) : AiraColors.muted.withValues(alpha: 0.4)),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: enabled ? AiraColors.charcoal : AiraColors.muted.withValues(alpha: 0.4))),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final MessageLog msg;
  const _MessageCard({required this.msg});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (msg.channel) {
      MessageChannel.line => (Icons.chat_rounded, const Color(0xFF06C755)),
      MessageChannel.whatsapp => (Icons.phone_android_rounded, const Color(0xFF25D366)),
    };

    final statusColor = switch (msg.status) {
      MessageStatus.sent => AiraColors.sage,
      MessageStatus.delivered => AiraColors.sage,
      MessageStatus.failed => AiraColors.terra,
      MessageStatus.pending => AiraColors.gold,
    };

    final dateStr = msg.sentAt != null ? DateFormat('d/M/yy HH:mm').format(msg.sentAt!) : '';
    final l = context.l10n;
    final typeLabel = switch (msg.templateType) {
      MessageTemplateType.appointment => l.apptShort,
      MessageTemplateType.confirmation => l.confirmShort,
      MessageTemplateType.afterCare => l.afterCareShort,
      MessageTemplateType.promotion => l.promoShort,
      MessageTemplateType.custom => l.customShort,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                      child: Text(msg.channel.dbValue, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AiraColors.woodWash.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
                      child: Text(typeLabel, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: AiraColors.woodMid)),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(msg.status.dbValue, style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
                    ),
                  ],
                ),
                if (msg.messageContent != null && msg.messageContent!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(msg.messageContent!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.charcoal, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 4),
                Text(dateStr, style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AiraColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
