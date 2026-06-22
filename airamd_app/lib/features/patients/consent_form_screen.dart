import 'dart:typed_data';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
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
import '../../core/localization/app_localizations.dart';
import '../../core/repositories/repository_exceptions.dart';
import '../../core/services/consent_pdf_service.dart';
import '../settings/consent_template_providers.dart';

// ─── In-file providers ────────────────────────────────────────
final _consentDoctorsProvider = FutureProvider<List<Staff>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return const [];
  return ref.watch(staffRepoProvider).getDoctors(clinicId);
});

final _consentClinicProvider = FutureProvider<Clinic?>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return null;
  final data = await ref
      .watch(supabaseClientProvider)
      .from('clinics')
      .select()
      .eq('id', clinicId)
      .maybeSingle();
  return data != null ? Clinic.fromJson(data) : null;
});

/// Extract per-line risk/side-effect items from a consent template so the
/// patient can acknowledge each one individually. Items are the lines that
/// follow the "…เช่น" marker, up to the closing paragraph.
List<String> parseRiskItems(String content) {
  final lines = content.split('\n').map((e) => e.trim()).toList();
  final items = <String>[];
  var collecting = false;
  for (final line in lines) {
    if (!collecting) {
      if (line.contains('เช่น')) collecting = true;
      continue;
    }
    if (line.isEmpty) continue;
    if (line.startsWith('หนังสือฉบับนี้') || line.startsWith('ข้าพเจ้าได้อ่าน')) {
      break;
    }
    items.add(line);
  }
  return items;
}

/// Consent Form screen — patient signs with finger/stylus on iPad.
/// World-class: template-driven legal text, per-item risk acknowledgement,
/// typed-name confirmation, and patient + doctor + witness signatures.
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
  final _witness2Ctrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _typedNameCtrl = TextEditingController();
  late final SignatureController _sigCtrl;
  late final SignatureController _doctorSigCtrl;
  late final SignatureController _witnessSigCtrl;
  late final SignatureController _witness2SigCtrl;

  bool _agreedGeneral = false;
  bool _agreedPhoto = false;
  bool _isSaving = false;

  ConsentFormTemplate? _selectedTemplate;
  String? _selectedDoctorId;
  List<String> _riskItems = const [];
  List<bool> _ackChecked = const [];

  @override
  void initState() {
    super.initState();
    _sigCtrl = _newSig();
    _doctorSigCtrl = _newSig();
    _witnessSigCtrl = _newSig();
    _witness2SigCtrl = _newSig();
  }

  SignatureController _newSig() => SignatureController(
        penStrokeWidth: 2.5,
        penColor: AiraColors.charcoal,
        exportBackgroundColor: Colors.white,
        exportPenColor: AiraColors.charcoal,
      );

  @override
  void dispose() {
    _witnessCtrl.dispose();
    _witness2Ctrl.dispose();
    _notesCtrl.dispose();
    _typedNameCtrl.dispose();
    _sigCtrl.dispose();
    _doctorSigCtrl.dispose();
    _witnessSigCtrl.dispose();
    _witness2SigCtrl.dispose();
    super.dispose();
  }

  void _selectTemplate(ConsentFormTemplate t) {
    setState(() {
      _selectedTemplate = t;
      _riskItems = parseRiskItems(t.content);
      _ackChecked = List<bool>.filled(_riskItems.length, false);
    });
  }

  bool get _allAcknowledged =>
      _ackChecked.isEmpty || _ackChecked.every((v) => v);

  bool get _canSave =>
      _selectedTemplate != null &&
      _agreedGeneral &&
      _allAcknowledged &&
      _typedNameCtrl.text.trim().isNotEmpty &&
      _sigCtrl.isNotEmpty;

  String _clinicName() =>
      ref.read(_consentClinicProvider).valueOrNull?.name ?? 'คลินิก';

  Future<String?> _uploadSig(
      SignatureController ctrl, String clinicId, String tag, int ts) async {
    if (ctrl.isEmpty) return null;
    final bytes = await ctrl.toPngBytes();
    if (bytes == null) return null;
    final path = '$clinicId/${widget.patientId}/${tag}_$ts.png';
    await ref
        .read(supabaseClientProvider)
        .storage
        .from(AppConstants.bucketConsentSignatures)
        .uploadBinary(path, bytes,
            fileOptions:
                const FileOptions(contentType: 'image/png', upsert: false));
    return path;
  }

  Future<void> _save() async {
    if (!_canSave || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final clinicId = ref.read(currentClinicIdProvider);
      if (clinicId == null) throw const MissingContextException('clinic_id');
      final template = _selectedTemplate!;
      final now = DateTime.now();
      final ts = now.millisecondsSinceEpoch;

      // 1. Export signatures
      final Uint8List? sigBytes = await _sigCtrl.toPngBytes();
      if (sigBytes == null) throw const RenderFailureException();
      final Uint8List? docSigBytes =
          _doctorSigCtrl.isNotEmpty ? await _doctorSigCtrl.toPngBytes() : null;
      final Uint8List? witSigBytes =
          _witnessSigCtrl.isNotEmpty ? await _witnessSigCtrl.toPngBytes() : null;
      final Uint8List? wit2SigBytes =
          _witness2SigCtrl.isNotEmpty ? await _witness2SigCtrl.toPngBytes() : null;

      // 2. Upload signature PNGs
      final sigPath = await _uploadSig(_sigCtrl, clinicId, 'sig', ts);
      final docSigPath = await _uploadSig(_doctorSigCtrl, clinicId, 'docsig', ts);
      final witSigPath =
          await _uploadSig(_witnessSigCtrl, clinicId, 'witsig', ts);
      final wit2SigPath =
          await _uploadSig(_witness2SigCtrl, clinicId, 'wit2sig', ts);

      // 3. Resolve doctor + clinic info
      final doctors = ref.read(_consentDoctorsProvider).valueOrNull ?? const [];
      Staff? doctor;
      for (final d in doctors) {
        if (d.id == _selectedDoctorId) doctor = d;
      }
      final clinicName = _clinicName();

      // 4. Acknowledged risk items (all required items the patient checked)
      final acknowledged = <String>[
        for (var i = 0; i < _riskItems.length; i++)
          if (_ackChecked[i]) _riskItems[i],
      ];
      final consentedItems = <String>[
        if (_agreedGeneral) 'GENERAL_CONSENT',
        if (_agreedPhoto) 'PHOTO_CONSENT',
      ];

      // 5. Generate the full legal PDF FIRST (immutable record needs pdf_url
      //    on the single insert — we cannot UPDATE after insert).
      final formForPdf = ConsentForm(
        id: '',
        clinicId: clinicId,
        patientId: widget.patientId,
        treatmentRecordId: widget.treatmentRecordId,
        formTemplateId: template.id,
        signatureUrl: sigPath ?? '',
        signedAt: now,
        witnessName:
            _witnessCtrl.text.trim().isEmpty ? null : _witnessCtrl.text.trim(),
        witness2Name: _witness2Ctrl.text.trim().isEmpty
            ? null
            : _witness2Ctrl.text.trim(),
        procedure: template.name,
        consentedItems: consentedItems,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        doctorId: _selectedDoctorId,
        signedNameTyped: _typedNameCtrl.text.trim(),
        templateVersion: template.version,
        acknowledgedItems: acknowledged,
        deviceInfo: defaultTargetPlatform.name,
      );

      final patient =
          await ref.read(patientByIdProvider(widget.patientId).future);

      String? pdfPath;
      if (patient != null) {
        final pdfBytes = await ConsentPdfService.generate(
          form: formForPdf,
          patient: patient,
          clinicName: clinicName,
          templateContent: template.content,
          documentTitle: template.name,
          doctorName: doctor?.fullName,
          doctorLicenseNo: doctor?.licenseNumber,
          acknowledgedItems: acknowledged,
          signatureBytes: sigBytes,
          doctorSignatureBytes: docSigBytes,
          witnessSignatureBytes: witSigBytes,
          witness2SignatureBytes: wit2SigBytes,
        );
        pdfPath = await ref.read(consentFormRepoProvider).uploadPdf(
              clinicId: clinicId,
              patientId: widget.patientId,
              fileName: 'consent_$ts.pdf',
              bytes: pdfBytes,
            );
      }

      // 6. Single immutable insert with everything (incl. archived pdf_url).
      final form = ConsentForm(
        id: '',
        clinicId: clinicId,
        patientId: widget.patientId,
        treatmentRecordId: widget.treatmentRecordId,
        formTemplateId: template.id,
        signatureUrl: sigPath ?? '',
        signedAt: now,
        witnessName:
            _witnessCtrl.text.trim().isEmpty ? null : _witnessCtrl.text.trim(),
        witness2Name: _witness2Ctrl.text.trim().isEmpty
            ? null
            : _witness2Ctrl.text.trim(),
        pdfUrl: pdfPath,
        procedure: template.name,
        consentedItems: consentedItems,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        doctorId: _selectedDoctorId,
        doctorSignatureUrl: docSigPath,
        witnessSignatureUrl: witSigPath,
        witness2SignatureUrl: wit2SigPath,
        signedNameTyped: _typedNameCtrl.text.trim(),
        templateVersion: template.version,
        acknowledgedItems: acknowledged,
        deviceInfo: defaultTargetPlatform.name,
      );
      await ref.read(consentFormRepoProvider).create(form);

      // 7. Offer to print / share
      if (!mounted) return;
      final exportPdf = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.consentSaved),
          content: Text(context.l10n.isThai
              ? 'ต้องการพิมพ์ / ส่งออก PDF ใบยินยอมหรือไม่?'
              : 'Print / export consent PDF?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.l10n.cancel)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(context.l10n.export_)),
          ],
        ),
      );
      if (exportPdf == true && patient != null && mounted) {
        await ConsentPdfService.printOrShare(
          form: form,
          patient: patient,
          clinicName: clinicName,
          templateContent: template.content,
          documentTitle: template.name,
          doctorName: doctor?.fullName,
          doctorLicenseNo: doctor?.licenseNumber,
          acknowledgedItems: acknowledged,
          signatureBytes: sigBytes,
          doctorSignatureBytes: docSigBytes,
          witnessSignatureBytes: witSigBytes,
          witness2SignatureBytes: wit2SigBytes,
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.errorMsg('$e')),
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
    final _ = ref.watch(isThaiProvider);
    final isThai = context.l10n.isThai;
    final patientAsync = ref.watch(patientByIdProvider(widget.patientId));
    final templatesAsync = ref.watch(consentTemplatesProvider);
    final doctorsAsync = ref.watch(_consentDoctorsProvider);
    final clinicName = ref.watch(_consentClinicProvider).valueOrNull?.name;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          AiraPremiumHeader(
            title: context.l10n.consentFormTitle,
            subtitle: context.l10n.consentSubtitle(DateFormat(
                    isThai ? 'dd/MM/yyyy' : 'MMM d, yyyy',
                    isThai ? 'th' : 'en')
                .format(now)),
            loading: _isSaving,
            onBack: () => context.pop(),
            onSave: _canSave ? _save : null,
            saveLabel: context.l10n.save,
            steps: premiumSteps([
              (1, context.l10n.info),
              (2, context.l10n.procedure),
              (3, context.l10n.consent),
              (4, context.l10n.signature),
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
                      AiraSectionHeader(
                          step: 1,
                          icon: Icons.person_rounded,
                          title: context.l10n.patientInformation),
                      patientAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                        data: (p) => p == null
                            ? const Text('Patient not found')
                            : _buildPatientInfo(p),
                      ),
                      const SizedBox(height: 28),

                      // ─── Template Selection ───
                      AiraSectionHeader(
                          step: 2,
                          icon: Icons.description_rounded,
                          title: isThai ? 'เลือกเอกสารยินยอม' : 'Select consent document'),
                      templatesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                        data: (templates) => _buildTemplatePicker(templates, isThai),
                      ),
                      const SizedBox(height: 16),

                      // ─── Template content + risk acknowledgement ───
                      if (_selectedTemplate != null) ...[
                        _buildContentViewer(clinicName, isThai),
                        const SizedBox(height: 20),
                        if (_riskItems.isNotEmpty) ...[
                          AiraSectionHeader(
                              step: 3,
                              icon: Icons.checklist_rounded,
                              title: isThai
                                  ? 'รับทราบความเสี่ยง (ติ๊กให้ครบทุกข้อ)'
                                  : 'Acknowledge risks (check all)'),
                          ..._buildRiskChecklist(),
                          const SizedBox(height: 16),
                        ],
                      ],

                      // ─── General consent ───
                      AiraSectionHeader(
                          step: 0,
                          icon: Icons.verified_user_rounded,
                          title: context.l10n.consentAgreement),
                      _consentCheckbox(
                        value: _agreedGeneral,
                        onChanged: (v) =>
                            setState(() => _agreedGeneral = v ?? false),
                        title: context.l10n.consentGeneral,
                        required: true,
                      ),
                      const SizedBox(height: 8),
                      _consentCheckbox(
                        value: _agreedPhoto,
                        onChanged: (v) =>
                            setState(() => _agreedPhoto = v ?? false),
                        title: context.l10n.consentPhoto,
                      ),
                      const SizedBox(height: 28),

                      // ─── Doctor ───
                      AiraSectionHeader(
                          step: 0,
                          icon: Icons.medical_services_rounded,
                          title: isThai ? 'แพทย์ผู้ทำการรักษา' : 'Treating doctor'),
                      doctorsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                        data: (doctors) => _buildDoctorPicker(doctors, isThai),
                      ),
                      const SizedBox(height: 28),

                      // ─── Typed name confirmation ───
                      AiraSectionHeader(
                          step: 0,
                          icon: Icons.badge_rounded,
                          title: isThai ? 'พิมพ์ชื่อยืนยัน' : 'Type name to confirm'),
                      AiraPremiumCard(
                        accentColor: AiraColors.sage,
                        children: [
                          TextField(
                            controller: _typedNameCtrl,
                            onChanged: (_) => setState(() {}),
                            style: airaFieldTextStyle,
                            decoration: airaFieldDecoration(
                              label: isThai
                                  ? 'ชื่อ-นามสกุล ผู้รับการรักษา'
                                  : 'Patient full name',
                              hint: isThai
                                  ? 'พิมพ์ชื่อ-นามสกุลเพื่อยืนยัน'
                                  : 'Type full name to confirm',
                              prefixIcon: Icons.badge_rounded,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ─── Patient Signature ───
                      AiraSectionHeader(
                          step: 4,
                          icon: Icons.draw_rounded,
                          title: context.l10n.patientSignature),
                      Text(context.l10n.signBelowInstruction,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, color: AiraColors.muted)),
                      const SizedBox(height: 12),
                      _signaturePad(_sigCtrl),
                      const SizedBox(height: 20),

                      // ─── Doctor Signature ───
                      AiraSectionHeader(
                          step: 0,
                          icon: Icons.draw_rounded,
                          title: isThai ? 'ลายเซ็นแพทย์' : 'Doctor signature'),
                      _signaturePad(_doctorSigCtrl),
                      const SizedBox(height: 20),

                      // ─── Witness 1 ───
                      AiraSectionHeader(
                          step: 0,
                          icon: Icons.person_outline_rounded,
                          title: isThai
                              ? 'พยานคนที่ 1'
                              : 'Witness 1'),
                      AiraPremiumCard(
                        accentColor: AiraColors.woodLt,
                        children: [
                          TextField(
                            controller: _witnessCtrl,
                            style: airaFieldTextStyle,
                            decoration: airaFieldDecoration(
                              label: context.l10n.witness,
                              hint: context.l10n.witnessNameOptional,
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _signaturePad(_witnessSigCtrl),
                      const SizedBox(height: 20),

                      // ─── Witness 2 ───
                      AiraSectionHeader(
                          step: 0,
                          icon: Icons.person_outline_rounded,
                          title: isThai
                              ? 'พยานคนที่ 2'
                              : 'Witness 2'),
                      AiraPremiumCard(
                        accentColor: AiraColors.woodLt,
                        children: [
                          TextField(
                            controller: _witness2Ctrl,
                            style: airaFieldTextStyle,
                            decoration: airaFieldDecoration(
                              label: context.l10n.witness,
                              hint: context.l10n.witnessNameOptional,
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _signaturePad(_witness2SigCtrl),
                      const SizedBox(height: 20),

                      // ─── Notes ───
                      AiraSectionHeader(
                          step: 0,
                          icon: Icons.note_rounded,
                          title: context.l10n.additionalNotes),
                      AiraPremiumCard(
                        accentColor: AiraColors.muted,
                        children: [
                          TextField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            style: airaFieldTextStyle,
                            decoration: airaFieldDecoration(
                              label: context.l10n.notes,
                              hint: context.l10n.notesHint,
                              prefixIcon: Icons.notes_rounded,
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
                            Icon(Icons.access_time_rounded,
                                size: 18, color: AiraColors.muted),
                            const SizedBox(width: 8),
                            Text(
                              '${context.l10n.signedDate} ${DateFormat(isThai ? 'd MMM yyyy HH:mm' : 'MMM d, yyyy HH:mm', isThai ? 'th' : 'en').format(now)}',
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

  Widget _buildTemplatePicker(List<ConsentFormTemplate> templates, bool isThai) {
    if (templates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AiraColors.terra.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isThai
              ? 'ยังไม่มีเทมเพลตใบยินยอม — เพิ่มได้ที่ ตั้งค่า → ใบยินยอม'
              : 'No consent templates — add them in Settings → Consent Forms',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 13, color: AiraColors.terra),
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: templates.where((t) => t.isActive).map((t) {
        final selected = _selectedTemplate?.id == t.id;
        return AiraTapEffect(
          onTap: () => _selectTemplate(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AiraColors.woodDk : AiraColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? AiraColors.woodDk : AiraColors.woodPale),
            ),
            child: Text(
              t.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AiraColors.charcoal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContentViewer(String? clinicName, bool isThai) {
    final text = _selectedTemplate!.content
        .replaceAll('{clinic_name}', clinicName ?? (isThai ? 'คลินิก' : 'the clinic'));
    return Container(
      constraints: const BoxConstraints(maxHeight: 260),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.4)),
      ),
      child: SingleChildScrollView(
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            height: 1.6,
            color: AiraColors.charcoal,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRiskChecklist() {
    return [
      for (var i = 0; i < _riskItems.length; i++) ...[
        _consentCheckbox(
          value: _ackChecked[i],
          onChanged: (v) => setState(() => _ackChecked[i] = v ?? false),
          title: _riskItems[i],
          required: true,
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  Widget _buildDoctorPicker(List<Staff> doctors, bool isThai) {
    return AiraPremiumCard(
      accentColor: AiraColors.woodMid,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedDoctorId,
          isExpanded: true,
          decoration: airaFieldDecoration(
            label: isThai ? 'แพทย์' : 'Doctor',
            hint: isThai ? 'เลือกแพทย์' : 'Select doctor',
            prefixIcon: Icons.person_rounded,
          ),
          items: doctors.map((d) {
            final lic = d.licenseNumber;
            final licLabel = (lic != null && lic.trim().isNotEmpty)
                ? ' • ว.${lic.trim()}'
                : '';
            return DropdownMenuItem(
              value: d.id,
              child: Text('${d.fullName}$licLabel',
                  overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedDoctorId = v),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _signaturePad(SignatureController ctrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AiraColors.woodPale, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: Signature(controller: ctrl, backgroundColor: Colors.white),
            ),
            Divider(height: 1, color: AiraColors.creamDk),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(context.l10n.signature,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: AiraColors.muted)),
                  const Spacer(),
                  AiraTapEffect(
                    onTap: () {
                      ctrl.clear();
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AiraColors.cream,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded,
                              size: 16, color: AiraColors.muted),
                          const SizedBox(width: 4),
                          Text(context.l10n.clear,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AiraColors.muted)),
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
    );
  }

  Widget _buildPatientInfo(dynamic patient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AiraColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiraColors.creamDk),
      ),
      child: Column(
        children: [
          _infoRow(context.l10n.fullName,
              '${patient.firstName} ${patient.lastName}'),
          _infoRow(context.l10n.nickname, patient.nickname ?? '-'),
          _infoRow('HN', patient.hn ?? '-'),
          if (patient.drugAllergies.isNotEmpty)
            _infoRow(context.l10n.allergiesWarning,
                patient.drugAllergies.join(', '),
                isWarning: true),
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
            child: Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isWarning
                        ? const Color(0xFFD32F2F)
                        : AiraColors.muted,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: isWarning
                        ? const Color(0xFFD32F2F)
                        : AiraColors.charcoal,
                    fontWeight:
                        isWarning ? FontWeight.w700 : FontWeight.w500)),
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
          color: value
              ? AiraColors.sage.withValues(alpha: 0.08)
              : AiraColors.white,
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
                    width: 2),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, height: 1.5, color: AiraColors.charcoal)),
            ),
            if (required)
              const Text('*',
                  style: TextStyle(
                      fontSize: 18,
                      color: AiraColors.terra,
                      fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
