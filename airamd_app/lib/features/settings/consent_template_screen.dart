import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/models.dart';
import '../../core/widgets/aira_tap_effect.dart';
import 'consent_template_providers.dart';

// ─── Category options ─────────────────────────────────────────
// Mirror TreatmentCategory.dbValue so templates can be filtered per category
// (e.g. show the Laser consent when recording a laser treatment).
const _categoryOptions = <String, ({String th, String en})>{
  'LASER': (th: 'เลเซอร์', en: 'Laser'),
  'TREATMENT': (th: 'ทรีตเมนต์', en: 'Treatment'),
  'INJECTABLE': (th: 'ฉีด (Botox/Filler)', en: 'Injectable'),
  'OTHER': (th: 'อื่นๆ', en: 'Other'),
};

String _categoryLabel(String? cat, bool isThai) {
  if (cat == null) return isThai ? 'ทั่วไป' : 'General';
  final o = _categoryOptions[cat];
  if (o == null) return cat;
  return isThai ? o.th : o.en;
}

// ─── Screen ───────────────────────────────────────────────────
class ConsentTemplateScreen extends ConsumerWidget {
  const ConsentTemplateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final isThai = l.isThai;
    final templatesAsync = ref.watch(consentTemplatesProvider);

    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                AiraTapEffect(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
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
                  onTap: () => _showEditor(context, ref),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: templatesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorState(message: '$e'),
              data: (templates) {
                if (templates.isEmpty) {
                  return _EmptyState(
                    isThai: isThai,
                    onSeed: () => _seedDefaults(context, ref),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: templates.length,
                  itemBuilder: (context, i) => AiraTapEffect(
                    onTap: () => _showPreview(context, templates[i], isThai),
                    child: _TemplateCard(
                      template: templates[i],
                      isThai: isThai,
                      onEdit: () =>
                          _showEditor(context, ref, existing: templates[i]),
                      onDelete: () => _confirmDelete(context, ref, templates[i]),
                    ),
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seedDefaults(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(consentTemplatesProvider.notifier).seedDefaults();
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  /// Read-only full-document preview (tap a template card).
  void _showPreview(
      BuildContext context, ConsentFormTemplate t, bool isThai) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: AiraColors.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AiraColors.woodPale,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  t.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AiraColors.charcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isThai
                      ? 'ตัวอย่างเอกสาร — {clinic_name} จะถูกแทนด้วยชื่อคลินิกจริงตอนใช้งาน'
                      : 'Document preview — {clinic_name} is replaced with the real clinic name in use',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AiraColors.muted,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AiraColors.woodPale.withValues(alpha: 0.3)),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollCtrl,
                      child: SelectableText(
                        t.content,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          height: 1.7,
                          color: AiraColors.charcoal,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ConsentFormTemplate t) async {
    final isThai = context.l10n.isThai;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isThai ? 'ลบเทมเพลต' : 'Delete template'),
        content: Text(
            isThai ? 'ต้องการลบ "${t.name}" หรือไม่?' : 'Delete "${t.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isThai ? 'ลบ' : 'Delete',
                style: const TextStyle(color: AiraColors.terra)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(consentTemplatesProvider.notifier).remove(t.id);
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  void _showEditor(BuildContext context, WidgetRef ref,
      {ConsentFormTemplate? existing}) {
    final isThai = context.l10n.isThai;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    String? category = existing?.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: AiraColors.cream,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AiraColors.woodPale,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        existing == null
                            ? (isThai ? 'เพิ่มเทมเพลต' : 'New template')
                            : (isThai ? 'แก้ไขเทมเพลต' : 'Edit template'),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AiraColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _Label(isThai ? 'ชื่อเทมเพลต' : 'Template name'),
                      TextField(
                        controller: nameCtrl,
                        decoration: _inputDecoration(isThai
                            ? 'เช่น ใบยินยอมเลเซอร์'
                            : 'e.g. Laser consent'),
                      ),
                      const SizedBox(height: 16),
                      _Label(isThai ? 'หมวด' : 'Category'),
                      DropdownButtonFormField<String?>(
                        initialValue: category,
                        decoration: _inputDecoration(
                            isThai ? 'เลือกหมวด' : 'Select category'),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(isThai ? 'ทั่วไป' : 'General'),
                          ),
                          ..._categoryOptions.entries.map(
                            (e) => DropdownMenuItem<String?>(
                              value: e.key,
                              child: Text(isThai ? e.value.th : e.value.en),
                            ),
                          ),
                        ],
                        onChanged: (v) => setSheet(() => category = v),
                      ),
                      const SizedBox(height: 16),
                      _Label(isThai ? 'เนื้อหา' : 'Content'),
                      TextField(
                        controller: contentCtrl,
                        maxLines: 12,
                        minLines: 6,
                        decoration: _inputDecoration(isThai
                            ? 'ข้อความใบยินยอม… ใช้ {clinic_name} แทนชื่อคลินิก'
                            : 'Consent text… use {clinic_name} for clinic name'),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AiraColors.woodDk,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            final content = contentCtrl.text.trim();
                            if (name.isEmpty || content.isEmpty) return;
                            final notifier =
                                ref.read(consentTemplatesProvider.notifier);
                            try {
                              if (existing == null) {
                                await notifier.add(
                                  name: name,
                                  category: category,
                                  content: content,
                                );
                              } else {
                                await notifier.edit(existing.copyWith(
                                  name: name,
                                  category: category,
                                  content: content,
                                ));
                              }
                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                            } catch (e) {
                              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                              if (context.mounted) _showError(context, e);
                            }
                          },
                          child: Text(
                            context.l10n.save,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showError(BuildContext context, Object e) {
    final isThai = context.l10n.isThai;
    final s = '$e';
    final msg = s.contains('row-level security') || s.contains('permission')
        ? (isThai
            ? 'เฉพาะเจ้าของคลินิก (OWNER) เท่านั้นที่แก้ใบยินยอมได้'
            : 'Only the clinic OWNER can manage consent templates')
        : context.l10n.errorMsg(s);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AiraColors.terra),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AiraColors.woodPale),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: AiraColors.woodPale.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AiraColors.woodDk, width: 1.5),
        ),
      );
}

// ─── Sub-widgets ──────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AiraColors.charcoal,
          ),
        ),
      );
}

class _TemplateCard extends StatelessWidget {
  final ConsentFormTemplate template;
  final bool isThai;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TemplateCard({
    required this.template,
    required this.isThai,
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
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  template.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AiraColors.charcoal,
                  ),
                ),
              ),
              AiraTapEffect(
                onTap: onEdit,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit_rounded,
                      size: 18, color: AiraColors.woodMid),
                ),
              ),
              const SizedBox(width: 8),
              AiraTapEffect(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline_rounded,
                      size: 18, color: AiraColors.terra),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Chip(
                label: _categoryLabel(template.category, isThai),
                color: AiraColors.gold,
              ),
              const SizedBox(width: 8),
              _Chip(label: 'v${template.version}', color: AiraColors.woodMid),
              if (!template.isActive) ...[
                const SizedBox(width: 8),
                _Chip(
                  label: isThai ? 'ปิดใช้งาน' : 'Inactive',
                  color: AiraColors.muted,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            template.content.replaceAll('\n', ' ').trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.5,
              color: AiraColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final bool isThai;
  final VoidCallback onSeed;
  const _EmptyState({required this.isThai, required this.onSeed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined,
                size: 64, color: AiraColors.woodPale.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              isThai ? 'ยังไม่มีเทมเพลตใบยินยอม' : 'No consent templates yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AiraColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isThai
                  ? 'เริ่มต้นด้วยเทมเพลตมาตรฐาน (เลเซอร์ + ทรีตเมนต์) แล้วแก้ไขได้ภายหลัง'
                  : 'Start with the standard templates (Laser + Treatment), edit anytime',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.5,
                color: AiraColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AiraColors.woodDk,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: onSeed,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                isThai ? 'ใช้เทมเพลตมาตรฐาน' : 'Use standard templates',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AiraColors.terra),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AiraColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
