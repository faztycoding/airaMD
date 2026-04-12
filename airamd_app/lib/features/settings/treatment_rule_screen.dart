import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/aira_premium_form.dart';
import '../../core/localization/app_localizations.dart';

// ─── Provider ─────────────────────────────────────────────────
final _treatmentRuleListProvider = FutureProvider<List<TreatmentRule>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(treatmentRuleRepoProvider);
  return repo.list(clinicId: clinicId);
});

class TreatmentRuleScreen extends ConsumerWidget {
  const TreatmentRuleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(_treatmentRuleListProvider);
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AiraColors.cream,
      appBar: AppBar(
        title: Text(l.treatmentRules),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l.isThai ? 'เพิ่มกฎใหม่' : 'Add rule',
            onPressed: () => _showRuleDialog(context, ref, null),
          ),
        ],
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(l.errorMsg('$e'))),
        data: (rules) {
          if (rules.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: AiraColors.woodWash.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.timer_rounded, size: 32, color: AiraColors.muted.withValues(alpha: 0.4)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l.isThai ? 'ยังไม่มีกฎระยะห่าง' : 'No interval rules yet',
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.isThai
                            ? 'ตั้งกฎระยะห่างขั้นต่ำ-เหมาะสม สำหรับหัตถการแต่ละประเภท\nเช่น Botox ทำซ้ำได้ทุก 90 วัน'
                            : 'Set minimum and ideal intervals for each procedure type\ne.g. Botox repeat every 90 days',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted, height: 1.5),
                      ),
                      const SizedBox(height: 28),
                      AiraTapEffect(
                        onTap: () => _showRuleDialog(context, ref, null),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF3D2517), Color(0xFF6B4F3A), Color(0xFF8B6650)]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                l.isThai ? 'เพิ่มกฎใหม่' : 'Add Rule',
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _RuleCard(rule: rules[i]),
          );
        },
      ),
    );
  }

  static void _showRuleDialog(BuildContext context, WidgetRef ref, TreatmentRule? existing) {
    final typeCtrl = TextEditingController(text: existing?.treatmentType ?? '');
    final minDaysCtrl = TextEditingController(text: existing?.repeatMinDays.toString() ?? '30');
    final idealDaysCtrl = TextEditingController(text: existing?.repeatIdealDays.toString() ?? '60');
    final contraCtrl = TextEditingController(text: existing?.contraindications.join(', ') ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AiraColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF3D2517), Color(0xFF5A3E2B), Color(0xFF7B5840)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(children: [
                  Icon(Icons.timer_rounded, size: 22, color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    isEdit
                        ? (context.l10n.isThai ? 'แก้ไขกฎระยะห่าง' : 'Edit Interval Rule')
                        : (context.l10n.isThai ? 'เพิ่มกฎระยะห่างใหม่' : 'New Interval Rule'),
                    style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  )),
                  AiraTapEffect(
                    onTap: () => Navigator.pop(ctx),
                    child: Icon(Icons.close_rounded, size: 20, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ]),
              ),
              // Form
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: typeCtrl,
                        style: airaFieldTextStyle,
                        decoration: airaFieldDecoration(
                          label: context.l10n.isThai ? 'ประเภทหัตถการ *' : 'Treatment Type *',
                          hint: 'Botox, Filler, HIFU...',
                          prefixIcon: Icons.medical_services_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minDaysCtrl,
                              style: airaFieldTextStyle,
                              decoration: airaFieldDecoration(
                                label: context.l10n.isThai ? 'ขั้นต่ำ (วัน)' : 'Min Days',
                                prefixIcon: Icons.hourglass_bottom_rounded,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: idealDaysCtrl,
                              style: airaFieldTextStyle,
                              decoration: airaFieldDecoration(
                                label: context.l10n.isThai ? 'เหมาะสม (วัน)' : 'Ideal Days',
                                prefixIcon: Icons.timer_rounded,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: contraCtrl,
                        style: airaFieldTextStyle,
                        decoration: airaFieldDecoration(
                          label: context.l10n.isThai ? 'ข้อห้าม (คั่นด้วย ,)' : 'Contraindications (comma separated)',
                          hint: context.l10n.isThai ? 'เช่น ตั้งครรภ์, แพ้ Lidocaine' : 'e.g. Pregnancy, Lidocaine allergy',
                          prefixIcon: Icons.block_rounded,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: notesCtrl,
                        style: airaFieldTextStyle,
                        decoration: airaFieldDecoration(
                          label: context.l10n.notes,
                          prefixIcon: Icons.notes_rounded,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Row(children: [
                  if (isEdit) ...[
                    // Delete button
                    AiraTapEffect(
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text(context.l10n.delete),
                            content: Text(context.l10n.isThai ? 'ต้องการลบกฎ "${existing.treatmentType}"?' : 'Delete rule "${existing.treatmentType}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.l10n.cancel)),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: Text(context.l10n.delete, style: TextStyle(color: AiraColors.terra)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          try {
                            await ref.read(treatmentRuleRepoProvider).deleteRule(existing.id);
                            ref.invalidate(_treatmentRuleListProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(context.l10n.saveFailed('$e'))),
                              );
                            }
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AiraColors.terra.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                        child: Icon(Icons.delete_outline_rounded, size: 20, color: AiraColors.terra),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: AiraTapEffect(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: AiraColors.creamDk, borderRadius: BorderRadius.circular(14)),
                        child: Center(child: Text(context.l10n.cancel, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.muted))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: AiraTapEffect(
                      onTap: () async {
                        if (typeCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.l10n.pleaseFillRequired)),
                          );
                          return;
                        }
                        final clinicId = ref.read(currentClinicIdProvider);
                        if (clinicId == null) return;
                        final repo = ref.read(treatmentRuleRepoProvider);

                        final contraList = contraCtrl.text.trim().isEmpty
                            ? <String>[]
                            : contraCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

                        final rule = TreatmentRule(
                          id: existing?.id ?? const Uuid().v4(),
                          clinicId: clinicId,
                          treatmentType: typeCtrl.text.trim(),
                          repeatMinDays: int.tryParse(minDaysCtrl.text.trim()) ?? 30,
                          repeatIdealDays: int.tryParse(idealDaysCtrl.text.trim()) ?? 60,
                          contraindications: contraList,
                          notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                        );

                        try {
                          if (isEdit) {
                            await repo.updateRule(rule);
                          } else {
                            await repo.create(rule);
                          }
                          ref.invalidate(_treatmentRuleListProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.saveSuccess), backgroundColor: AiraColors.sage),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.saveFailed('$e')), backgroundColor: AiraColors.terra),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF3D2517), Color(0xFF6B4F3A), Color(0xFF8B6650)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(context.l10n.save, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleCard extends ConsumerWidget {
  final TreatmentRule rule;
  const _RuleCard({required this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;

    return AiraTapEffect(
      onTap: () => TreatmentRuleScreen._showRuleDialog(context, ref, rule),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.6)),
          boxShadow: AiraShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AiraColors.woodWash.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.timer_rounded, size: 20, color: AiraColors.woodMid),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rule.treatmentType,
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: AiraColors.muted.withValues(alpha: 0.4)),
              ],
            ),
            const SizedBox(height: 12),
            // Interval info
            Row(
              children: [
                _IntervalChip(
                  label: l.isThai ? 'ขั้นต่ำ' : 'Min',
                  value: '${rule.repeatMinDays}',
                  unit: l.isThai ? 'วัน' : 'days',
                  color: AiraColors.terra,
                ),
                const SizedBox(width: 8),
                _IntervalChip(
                  label: l.isThai ? 'เหมาะสม' : 'Ideal',
                  value: '${rule.repeatIdealDays}',
                  unit: l.isThai ? 'วัน' : 'days',
                  color: AiraColors.sage,
                ),
              ],
            ),
            if (rule.contraindications.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: rule.contraindications.map((c) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AiraColors.terra.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AiraColors.terra.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block_rounded, size: 10, color: AiraColors.terra),
                      const SizedBox(width: 4),
                      Text(c, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.terra, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )).toList(),
              ),
            ],
            if (rule.notes != null && rule.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(rule.notes!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}

class _IntervalChip extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _IntervalChip({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 3),
          Text(unit, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: color.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}
