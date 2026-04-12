import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/aira_tap_effect.dart';

// ─── Model ────────────────────────────────────────────────────
class ConsentTemplate {
  final String id;
  String title;
  String bodyText;
  bool photoConsent;
  bool anesthesiaConsent;
  DateTime updatedAt;

  ConsentTemplate({
    required this.id,
    required this.title,
    required this.bodyText,
    this.photoConsent = true,
    this.anesthesiaConsent = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  ConsentTemplate copyWith({
    String? title,
    String? bodyText,
    bool? photoConsent,
    bool? anesthesiaConsent,
  }) =>
      ConsentTemplate(
        id: id,
        title: title ?? this.title,
        bodyText: bodyText ?? this.bodyText,
        photoConsent: photoConsent ?? this.photoConsent,
        anesthesiaConsent: anesthesiaConsent ?? this.anesthesiaConsent,
        updatedAt: DateTime.now(),
      );
}

// ─── Provider ─────────────────────────────────────────────────
final consentTemplateProvider =
    StateNotifierProvider<ConsentTemplateNotifier, List<ConsentTemplate>>(
  (ref) => ConsentTemplateNotifier(),
);

class ConsentTemplateNotifier extends StateNotifier<List<ConsentTemplate>> {
  ConsentTemplateNotifier()
      : super([
          ConsentTemplate(
            id: 'default_general',
            title: 'General Consent',
            bodyText:
                'ข้าพเจ้ายินยอมรับการรักษาตามหัตถการที่ระบุ โดยได้รับคำอธิบายเกี่ยวกับขั้นตอน ความเสี่ยง ผลข้างเคียงที่อาจเกิดขึ้น และทางเลือกอื่นๆ เป็นที่เข้าใจดีแล้ว',
          ),
          ConsentTemplate(
            id: 'default_botox',
            title: 'Botox / Filler Consent',
            bodyText:
                'ข้าพเจ้ายินยอมรับการฉีด Botulinum Toxin / Dermal Filler ตามบริเวณที่ระบุ '
                'โดยทราบดีว่าอาจมีอาการบวม ช้ำ หรือผลข้างเคียงอื่นๆ ชั่วคราว',
          ),
          ConsentTemplate(
            id: 'default_laser',
            title: 'Laser Consent',
            bodyText:
                'ข้าพเจ้ายินยอมรับการรักษาด้วยเลเซอร์ตามที่แพทย์แนะนำ '
                'โดยทราบดีว่าอาจมีอาการแดง บวม หรือรอยไหม้ชั่วคราว',
          ),
        ]);

  void add(ConsentTemplate t) => state = [...state, t];

  void update(String id, ConsentTemplate updated) {
    state = [
      for (final t in state)
        if (t.id == id) updated else t,
    ];
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}

// ─── Screen ───────────────────────────────────────────────────
class ConsentTemplateScreen extends ConsumerWidget {
  const ConsentTemplateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final templates = ref.watch(consentTemplateProvider);

    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          // ─── Header ───
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B4F3A), Color(0xFF8B6650)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B4F3A).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                AiraTapEffect(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.consentTemplates,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        l.consentTemplateSubtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                AiraTapEffect(
                  onTap: () => _showEditor(context, ref, null),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // ─── List ───
          Expanded(
            child: templates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.description_outlined,
                            size: 48,
                            color: AiraColors.muted.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(l.noConsentFormsHint,
                            style: GoogleFonts.plusJakartaSans(
                                color: AiraColors.muted)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
                    itemCount: templates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final t = templates[i];
                      return _TemplateCard(
                        template: t,
                        onEdit: () => _showEditor(context, ref, t),
                        onDelete: () => _confirmDelete(context, ref, t),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditor(
      BuildContext context, WidgetRef ref, ConsentTemplate? existing) {
    final titleCtrl =
        TextEditingController(text: existing?.title ?? '');
    final bodyCtrl =
        TextEditingController(text: existing?.bodyText ?? '');
    bool photo = existing?.photoConsent ?? true;
    bool anesthesia = existing?.anesthesiaConsent ?? true;
    final l = context.l10n;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AiraColors.cream,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AiraColors.woodPale,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                existing == null ? l.create : l.edit,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AiraColors.charcoal),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: l.consentFormTitle,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l.consentAgreement,
                  hintText: l.notesHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                title: Text(l.consentPhoto,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                value: photo,
                activeColor: AiraColors.woodMid,
                onChanged: (v) => setSt(() => photo = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile.adaptive(
                title: Text(l.consentAnesthesia,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                value: anesthesia,
                activeColor: AiraColors.woodMid,
                onChanged: (v) => setSt(() => anesthesia = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  final notifier =
                      ref.read(consentTemplateProvider.notifier);
                  if (existing != null) {
                    notifier.update(
                      existing.id,
                      existing.copyWith(
                        title: titleCtrl.text.trim(),
                        bodyText: bodyCtrl.text.trim(),
                        photoConsent: photo,
                        anesthesiaConsent: anesthesia,
                      ),
                    );
                  } else {
                    notifier.add(ConsentTemplate(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleCtrl.text.trim(),
                      bodyText: bodyCtrl.text.trim(),
                      photoConsent: photo,
                      anesthesiaConsent: anesthesia,
                    ));
                  }
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AiraColors.woodMid,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l.save,
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ConsentTemplate t) {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteAll),
        content: Text(t.title),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () {
              ref.read(consentTemplateProvider.notifier).remove(t.id);
              Navigator.pop(ctx);
            },
            child:
                Text(l.delete, style: TextStyle(color: AiraColors.terra)),
          ),
        ],
      ),
    );
  }
}

// ─── Template Card ────────────────────────────────────────────
class _TemplateCard extends StatelessWidget {
  final ConsentTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AiraColors.creamDk.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AiraColors.woodDk.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AiraColors.woodWash.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.description_rounded,
                    size: 18, color: AiraColors.woodMid),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  template.title,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AiraColors.charcoal),
                ),
              ),
              AiraTapEffect(
                onTap: onEdit,
                child: Icon(Icons.edit_rounded,
                    size: 18, color: AiraColors.woodMid),
              ),
              const SizedBox(width: 12),
              AiraTapEffect(
                onTap: onDelete,
                child: Icon(Icons.delete_outline_rounded,
                    size: 18, color: AiraColors.terra),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            template.bodyText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AiraColors.charcoal.withValues(alpha: 0.7),
                height: 1.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              if (template.photoConsent)
                _chip(Icons.camera_alt_rounded, 'Photo'),
              if (template.anesthesiaConsent)
                _chip(Icons.medical_services_rounded, 'Anesthesia'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AiraColors.woodWash.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AiraColors.woodMid),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: AiraColors.woodMid)),
        ],
      ),
    );
  }
}
