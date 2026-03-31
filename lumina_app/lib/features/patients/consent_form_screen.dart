import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/aira_premium_form.dart';

/// Consent Form screen — patient signs with finger/stylus on iPad.
/// Saves signature image + form data to patient record.
class ConsentFormScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String? treatmentRecordId;

  const ConsentFormScreen({
    super.key,
    required this.patientId,
    this.treatmentRecordId,
  });

  @override
  ConsumerState<ConsentFormScreen> createState() => _ConsentFormScreenState();
}

class _ConsentFormScreenState extends ConsumerState<ConsentFormScreen> {
  final _witnessCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late final SignatureController _sigCtrl;
  bool _agreedGeneral = false;
  bool _agreedPhoto = false;
  bool _agreedAnesthesia = false;
  bool _isSaving = false;
  String _selectedProcedure = '';

  static const _procedures = [
    'Botulinum Toxin Injection',
    'Dermal Filler Injection',
    'Laser Treatment',
    'Chemical Peel',
    'Microneedling / Mesotherapy',
    'PRP / Regenerative Treatment',
    'Thread Lift',
    'Surgical Procedure',
    'อื่นๆ (Other)',
  ];

  @override
  void initState() {
    super.initState();
    _sigCtrl = SignatureController(
      penStrokeWidth: 2.5,
      penColor: AiraColors.charcoal,
      exportBackgroundColor: Colors.white,
      exportPenColor: AiraColors.charcoal,
    );
  }

  @override
  void dispose() {
    _witnessCtrl.dispose();
    _notesCtrl.dispose();
    _sigCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _agreedGeneral && _sigCtrl.isNotEmpty && _selectedProcedure.isNotEmpty;

  Future<void> _save() async {
    if (!_canSave || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      // 1. Export signature as PNG bytes
      final Uint8List? sigBytes = await _sigCtrl.toPngBytes();
      if (sigBytes == null) throw Exception('Signature export failed');

      // 2. Build unique storage path
      final clinicId = ref.read(currentClinicIdProvider);
      if (clinicId == null) throw Exception('No clinic ID');
      final now = DateTime.now();
      final ts = now.millisecondsSinceEpoch;
      final storagePath = '$clinicId/${widget.patientId}/sig_$ts.png';

      // 3. Upload signature PNG to Supabase Storage
      await Supabase.instance.client.storage
          .from(AppConstants.bucketConsentSignatures)
          .uploadBinary(
            storagePath,
            sigBytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: false,
            ),
          );

      // 4. Build consented items list
      final consentedItems = <String>[
        if (_agreedGeneral) 'GENERAL_CONSENT',
        if (_agreedPhoto) 'PHOTO_CONSENT',
        if (_agreedAnesthesia) 'ANESTHESIA_CONSENT',
      ];

      // 5. Create ConsentForm record in database
      final form = ConsentForm(
        id: '',
        clinicId: clinicId,
        patientId: widget.patientId,
        treatmentRecordId: widget.treatmentRecordId,
        signatureUrl: storagePath,
        signedAt: now,
        witnessName: _witnessCtrl.text.trim().isEmpty
            ? null
            : _witnessCtrl.text.trim(),
        procedure: _selectedProcedure,
        consentedItems: consentedItems,
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );

      await ref.read(consentFormRepoProvider).create(form);

      // 6. Success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'บันทึกใบยินยอมเรียบร้อย',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AiraColors.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: AiraColors.terra,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isThai = ref.watch(isThaiProvider);
    final patientAsync = ref.watch(patientByIdProvider(widget.patientId));
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          AiraPremiumHeader(
            title: isThai ? 'ใบยินยอมรับการรักษา' : 'Consent Form',
            subtitle: isThai ? 'Informed Consent • ${DateFormat('dd/MM/yyyy').format(now)}' : 'Informed Consent • ${DateFormat('MMM d, yyyy').format(now)}',
            loading: _isSaving,
            onBack: () => context.pop(),
            onSave: _canSave ? _save : null,
            saveLabel: isThai ? 'บันทึก' : 'Save',
            steps: premiumSteps([
              (1, isThai ? 'ข้อมูล' : 'Info'),
              (2, isThai ? 'หัตถการ' : 'Procedure'),
              (3, isThai ? 'ยินยอม' : 'Consent'),
              (4, isThai ? 'ลายเซ็น' : 'Signature'),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Patient Info ───
                      AiraSectionHeader(step: 1, icon: Icons.person_rounded, title: isThai ? 'ข้อมูลผู้ป่วย' : 'Patient Information'),
                      patientAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                        data: (p) {
                          if (p == null) return const Text('Patient not found');
                          return _buildPatientInfo(p, isThai);
                        },
                      ),
                      const SizedBox(height: 28),

                      // ─── Procedure Selection ───
                      AiraSectionHeader(step: 2, icon: Icons.medical_services_rounded, title: isThai ? 'หัตถการที่จะทำ' : 'Procedure'),
                      Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _procedures.map((proc) {
                    final selected = _selectedProcedure == proc;
                    return AiraTapEffect(
                      onTap: () => setState(() => _selectedProcedure = proc),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AiraColors.woodDk : AiraColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AiraColors.woodDk : AiraColors.woodPale,
                          ),
                        ),
                        child: Text(
                          proc,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AiraColors.charcoal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                      const SizedBox(height: 28),

                      // ─── Consent Clauses ───
                      AiraSectionHeader(step: 3, icon: Icons.checklist_rounded, title: isThai ? 'ข้อตกลงยินยอม' : 'Consent Agreement'),
                      _consentCheckbox(
                  value: _agreedGeneral,
                  onChanged: (v) => setState(() => _agreedGeneral = v ?? false),
                  title: isThai
                      ? 'ข้าพเจ้ายินยอมรับการรักษาตามหัตถการที่ระบุข้างต้น โดยได้รับคำอธิบายเกี่ยวกับขั้นตอน ความเสี่ยง ผลข้างเคียงที่อาจเกิดขึ้น และทางเลือกอื่นๆ เป็นที่เข้าใจดีแล้ว'
                      : 'I consent to the procedure described above. Risks, benefits, and alternatives have been explained to me.',
                  required: true,
                ),
                const SizedBox(height: 8),
                      _consentCheckbox(
                  value: _agreedPhoto,
                  onChanged: (v) => setState(() => _agreedPhoto = v ?? false),
                  title: isThai
                      ? 'ข้าพเจ้ายินยอมให้ถ่ายภาพก่อน-หลังการรักษา เพื่อใช้ในการติดตามผลการรักษา'
                      : 'I consent to before/after photography for treatment documentation.',
                ),
                const SizedBox(height: 8),
                      _consentCheckbox(
                  value: _agreedAnesthesia,
                  onChanged: (v) => setState(() => _agreedAnesthesia = v ?? false),
                  title: isThai
                      ? 'ข้าพเจ้ายินยอมรับยาชาเฉพาะที่ (ถ้าจำเป็น)'
                      : 'I consent to local anesthesia if required.',
                ),
                      const SizedBox(height: 28),

                      // ─── Additional Notes ───
                      AiraSectionHeader(step: 0, icon: Icons.note_rounded, title: isThai ? 'หมายเหตุเพิ่มเติม' : 'Additional Notes'),
                      AiraPremiumCard(
                        accentColor: AiraColors.muted,
                        children: [
                          TextField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            style: airaFieldTextStyle,
                            decoration: airaFieldDecoration(
                              label: isThai ? 'หมายเหตุ' : 'Notes',
                              hint: isThai ? 'บันทึกเพิ่มเติม (ถ้ามี)' : 'Additional notes (optional)',
                              prefixIcon: Icons.notes_rounded,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ─── Signature ───
                      AiraSectionHeader(step: 4, icon: Icons.draw_rounded, title: isThai ? 'ลายเซ็นผู้ป่วย' : 'Patient Signature'),
                      Text(
                  isThai ? 'ใช้นิ้วหรือปากกาเซ็นด้านล่าง' : 'Sign below with finger or stylus',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AiraColors.woodPale, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AiraColors.woodDk.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 180,
                          child: Signature(
                            controller: _sigCtrl,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        Divider(height: 1, color: AiraColors.creamDk),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                isThai ? 'ลายเซ็น' : 'Signature',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AiraColors.muted,
                                ),
                              ),
                              const Spacer(),
                              AiraTapEffect(
                                onTap: () {
                                  _sigCtrl.clear();
                                  setState(() {});
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AiraColors.cream,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.refresh_rounded, size: 16, color: AiraColors.muted),
                                      const SizedBox(width: 4),
                                      Text(
                                        isThai ? 'ล้าง' : 'Clear',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AiraColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                      const SizedBox(height: 20),

                      // ─── Witness ───
                      AiraSectionHeader(step: 0, icon: Icons.person_outline_rounded, title: isThai ? 'ชื่อพยาน' : 'Witness Name'),
                      AiraPremiumCard(
                        accentColor: AiraColors.woodLt,
                        children: [
                          TextField(
                            controller: _witnessCtrl,
                            style: airaFieldTextStyle,
                            decoration: airaFieldDecoration(
                              label: isThai ? 'ชื่อพยาน' : 'Witness',
                              hint: isThai ? 'ชื่อพยาน (ถ้ามี)' : 'Witness name (optional)',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ─── Date/Time stamp ───
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AiraColors.parchment,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AiraColors.creamDk),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 18, color: AiraColors.muted),
                            const SizedBox(width: 8),
                            Text(
                              '${isThai ? "วันที่เซ็น:" : "Signed:"} ${DateFormat(isThai ? 'd MMM yyyy HH:mm' : 'MMM d, yyyy HH:mm', isThai ? 'th' : 'en').format(now)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: AiraColors.charcoal,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const AiraBrandingFooter(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfo(dynamic patient, bool isThai) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AiraColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiraColors.creamDk),
      ),
      child: Column(
        children: [
          _infoRow(isThai ? 'ชื่อ-สกุล' : 'Name', '${patient.firstName} ${patient.lastName}'),
          _infoRow(isThai ? 'ชื่อเล่น' : 'Nickname', patient.nickname ?? '-'),
          _infoRow('HN', patient.hn ?? '-'),
          if (patient.drugAllergies.isNotEmpty)
            _infoRow(
              isThai ? '⚠️ แพ้ยา' : '⚠️ Allergies',
              patient.drugAllergies.join(', '),
              isWarning: true,
            ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: isWarning ? const Color(0xFFD32F2F) : AiraColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: isWarning ? const Color(0xFFD32F2F) : AiraColors.charcoal,
                fontWeight: isWarning ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _consentCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String title,
    bool required = false,
  }) {
    return AiraTapEffect(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: value ? AiraColors.sage.withValues(alpha: 0.08) : AiraColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? AiraColors.sage.withValues(alpha: 0.4)
                : required && !value
                    ? AiraColors.terra.withValues(alpha: 0.3)
                    : AiraColors.creamDk,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? AiraColors.sage : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? AiraColors.sage : AiraColors.woodPale,
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.5,
                  color: AiraColors.charcoal,
                ),
              ),
            ),
            if (required)
              Text(
                '*',
                style: TextStyle(
                  fontSize: 18,
                  color: AiraColors.terra,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
