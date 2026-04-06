import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/services/safety_check_service.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/aira_premium_form.dart';

class TreatmentFormScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String? treatmentId; // null = new

  const TreatmentFormScreen({
    super.key,
    required this.patientId,
    this.treatmentId,
  });

  bool get isEdit => treatmentId != null && treatmentId != 'new';

  @override
  ConsumerState<TreatmentFormScreen> createState() =>
      _TreatmentFormScreenState();
}

class _TreatmentFormScreenState extends ConsumerState<TreatmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _safetyChecked = false;
  List<SafetyWarning> _warnings = [];

  // SOAP Fields
  final _treatmentNameCtrl = TextEditingController();
  final _ccCtrl = TextEditingController(); // Chief Complaint
  final _objectiveCtrl = TextEditingController(); // Objective
  final _assessmentCtrl = TextEditingController(); // Assessment
  final _planCtrl = TextEditingController(); // Plan
  final _notesCtrl = TextEditingController();

  // Device / Laser fields
  final _deviceCtrl = TextEditingController();
  final _energyCtrl = TextEditingController();
  final _pulseSpotCtrl = TextEditingController();
  final _totalShotsCtrl = TextEditingController();
  final _unitsUsedCtrl = TextEditingController();

  // Follow-up
  final _followUpTimeCtrl = TextEditingController();
  DateTime? _followUpDate;

  // Dropdowns
  TreatmentCategory _category = TreatmentCategory.injectable;
  TreatmentResponse _response = TreatmentResponse.notApplicable;

  // Products used — list of {name, quantity}
  final List<Map<String, dynamic>> _productsUsed = [];

  // Adverse events & instructions
  final List<String> _adverseEvents = [];
  final List<String> _instructions = [];
  final _adverseCtrl = TextEditingController();
  final _instructionCtrl = TextEditingController();

  @override
  void dispose() {
    _treatmentNameCtrl.dispose();
    _ccCtrl.dispose();
    _objectiveCtrl.dispose();
    _assessmentCtrl.dispose();
    _planCtrl.dispose();
    _notesCtrl.dispose();
    _deviceCtrl.dispose();
    _energyCtrl.dispose();
    _pulseSpotCtrl.dispose();
    _totalShotsCtrl.dispose();
    _unitsUsedCtrl.dispose();
    _followUpTimeCtrl.dispose();
    _adverseCtrl.dispose();
    _instructionCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    final repo = ref.read(treatmentRepoProvider);
    final record = await repo.get(widget.treatmentId!);
    if (record == null || !mounted) return;

    setState(() {
      _treatmentNameCtrl.text = record.treatmentName;
      _ccCtrl.text = record.chiefComplaint ?? '';
      _objectiveCtrl.text = record.objective ?? '';
      _assessmentCtrl.text = record.assessment ?? '';
      _planCtrl.text = record.plan ?? '';
      _notesCtrl.text = record.notes ?? '';
      _deviceCtrl.text = record.device ?? '';
      _energyCtrl.text = record.energy ?? '';
      _pulseSpotCtrl.text = record.pulseSpot ?? '';
      _totalShotsCtrl.text = record.totalShots ?? '';
      _unitsUsedCtrl.text =
          record.actualUnitsUsed?.toString() ?? '';
      _followUpDate = record.followUpDate;
      _followUpTimeCtrl.text = record.followUpTime ?? '';
      _category = record.category;
      _response = record.responseToPrevious;
      _adverseEvents.addAll(record.adverseEvents);
      _instructions.addAll(record.instructions);
      for (final p in record.productsUsed) {
        if (p is Map) {
          _productsUsed.add(Map<String, dynamic>.from(p));
        }
      }
      _safetyChecked = true; // Skip safety for edits
    });
  }

  Future<void> _runSafetyCheck() async {
    final patient =
        await ref.read(patientByIdProvider(widget.patientId).future);
    if (patient == null) return;

    final history =
        await ref.read(treatmentsByPatientProvider(widget.patientId).future);
    final rules = await ref.read(treatmentRulesProvider.future);

    final productNames = _productsUsed.map((p) => p['name']?.toString() ?? '').toList();

    final warnings = SafetyCheckService.checkAll(
      patient: patient,
      treatmentName: _treatmentNameCtrl.text.trim(),
      category: _category,
      patientHistory: history,
      rules: rules,
      productsToUse: productNames,
    );

    setState(() {
      _warnings = warnings;
      _safetyChecked = true;
    });

    if (warnings.any((w) => w.level == WarningLevel.danger)) {
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 28),
              const SizedBox(width: 8),
              const Text('คำเตือนความปลอดภัย'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: warnings
                  .where((w) => w.level == WarningLevel.danger)
                  .map((w) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(w.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(w.message,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('รับทราบและดำเนินการต่อ',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (proceed != true) {
        setState(() => _safetyChecked = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_safetyChecked) {
      await _runSafetyCheck();
      if (!_safetyChecked) return;
    }

    setState(() => _loading = true);

    final clinicId = ref.read(currentClinicIdProvider);
    if (clinicId == null) {
      setState(() => _loading = false);
      return;
    }

    final record = TreatmentRecord(
      id: widget.isEdit ? widget.treatmentId! : const Uuid().v4(),
      clinicId: clinicId,
      patientId: widget.patientId,
      date: DateTime.now(),
      category: _category,
      treatmentName: _treatmentNameCtrl.text.trim(),
      chiefComplaint:
          _ccCtrl.text.trim().isEmpty ? null : _ccCtrl.text.trim(),
      objective: _objectiveCtrl.text.trim().isEmpty
          ? null
          : _objectiveCtrl.text.trim(),
      assessment: _assessmentCtrl.text.trim().isEmpty
          ? null
          : _assessmentCtrl.text.trim(),
      plan:
          _planCtrl.text.trim().isEmpty ? null : _planCtrl.text.trim(),
      device: _deviceCtrl.text.trim().isEmpty
          ? null
          : _deviceCtrl.text.trim(),
      energy: _energyCtrl.text.trim().isEmpty
          ? null
          : _energyCtrl.text.trim(),
      pulseSpot: _pulseSpotCtrl.text.trim().isEmpty
          ? null
          : _pulseSpotCtrl.text.trim(),
      totalShots: _totalShotsCtrl.text.trim().isEmpty
          ? null
          : _totalShotsCtrl.text.trim(),
      productsUsed: _productsUsed,
      actualUnitsUsed: double.tryParse(_unitsUsedCtrl.text.trim()),
      responseToPrevious: _response,
      adverseEvents: _adverseEvents,
      instructions: _instructions,
      followUpDate: _followUpDate,
      followUpTime: _followUpTimeCtrl.text.trim().isEmpty
          ? null
          : _followUpTimeCtrl.text.trim(),
      notes:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    try {
      final repo = ref.read(treatmentRepoProvider);
      if (widget.isEdit) {
        await repo.updateRecord(record);
      } else {
        await repo.create(record);
      }
      ref.invalidate(treatmentsByPatientProvider(widget.patientId));
      ref.invalidate(todayTreatmentsProvider);
      ref.invalidate(dashboardStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit
                ? 'แก้ไขบันทึกการรักษาสำเร็จ'
                : 'บันทึกการรักษาสำเร็จ'),
            backgroundColor: AiraColors.sage,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกไม่สำเร็จ: $e'),
            backgroundColor: AiraColors.terra,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isThai = ref.watch(isThaiProvider);
    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          AiraPremiumHeader(
            title: widget.isEdit
                ? (isThai ? 'แก้ไขบันทึกการรักษา' : 'Edit Treatment')
                : (isThai ? 'บันทึกการรักษาใหม่' : 'New Treatment Record'),
            subtitle: isThai ? 'บันทึก SOAP Notes + ผลิตภัณฑ์' : 'SOAP Notes + Products Used',
            loading: _loading,
            onBack: () => context.pop(),
            onSave: _loading ? null : _save,
            saveLabel: isThai ? 'บันทึก' : 'Save',
            steps: premiumSteps([
              (1, isThai ? 'ข้อมูล' : 'Info'),
              (2, 'SOAP'),
              (3, isThai ? 'ผลิตภัณฑ์' : 'Products'),
              (4, isThai ? 'ผลลัพธ์' : 'Results'),
            ]),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    children: [
                      // Safety warnings banner
                      if (_warnings.isNotEmpty) _buildWarningsBanner(),

                      // ─── Section 1: Treatment Info ───
                      const AiraSectionHeader(
                        step: 1,
                        icon: Icons.medical_services_rounded,
                        title: 'ข้อมูลการรักษา',
                        subtitle: 'ชื่อหัตถการ, หมวดหมู่',
                      ),
                      _buildTreatmentInfoSection(),
                      const SizedBox(height: 28),

                      // ─── Section 2: SOAP Notes ───
                      const AiraSectionHeader(
                        step: 2,
                        icon: Icons.edit_note_rounded,
                        title: 'SOAP Notes',
                        subtitle: 'Chief Complaint, Objective, Assessment, Plan',
                      ),
                      _buildSoapSection(),
                      const SizedBox(height: 28),

                      // ─── Device / Laser section ───
                      if (_category == TreatmentCategory.laser) ...[
                        const AiraSectionHeader(
                          step: 0,
                          icon: Icons.settings_suggest_rounded,
                          title: 'อุปกรณ์ / เลเซอร์',
                          subtitle: 'Device, Energy, Pulse, Shots',
                        ),
                        _buildDeviceSection(),
                        const SizedBox(height: 28),
                      ],

                      // ─── Section 3: Products used ───
                      const AiraSectionHeader(
                        step: 3,
                        icon: Icons.inventory_2_rounded,
                        title: 'ผลิตภัณฑ์ที่ใช้',
                        subtitle: 'ผลิตภัณฑ์, จำนวน, หน่วย',
                      ),
                      _buildProductsSection(),
                      const SizedBox(height: 28),

                      // ─── Section 4: Response + Adverse events ───
                      const AiraSectionHeader(
                        step: 4,
                        icon: Icons.assessment_rounded,
                        title: 'ผลการรักษา',
                        subtitle: 'Response, Adverse Events',
                      ),
                      _buildResponseSection(),
                      const SizedBox(height: 28),

                      // ─── Follow-up ───
                      const AiraSectionHeader(
                        step: 0,
                        icon: Icons.calendar_month_rounded,
                        title: 'นัดติดตามผล',
                        subtitle: 'วันนัด, เวลานัด',
                      ),
                      _buildFollowUpSection(),
                      const SizedBox(height: 28),

                      // ─── Instructions ───
                      const AiraSectionHeader(
                        step: 0,
                        icon: Icons.checklist_rounded,
                        title: 'คำแนะนำหลังทำหัตถการ',
                        subtitle: 'เลือกจากรายการ หรือเพิ่มเอง',
                      ),
                      _buildInstructionsSection(),
                      const SizedBox(height: 28),

                      // ─── Notes ───
                      const AiraSectionHeader(
                        step: 0,
                        icon: Icons.note_rounded,
                        title: 'หมายเหตุเพิ่มเติม',
                      ),
                      AiraPremiumCard(
                        accentColor: AiraColors.muted,
                        children: [
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            style: airaFieldTextStyle,
                            decoration: airaFieldDecoration(label: 'หมายเหตุ', hint: 'หมายเหตุ...', prefixIcon: Icons.notes_rounded),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Safety check + Save buttons
                      if (!_safetyChecked)
                        AiraSafetyCheckButton(
                          onTap: () {
                            if (_treatmentNameCtrl.text.trim().isNotEmpty) {
                              _runSafetyCheck();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('กรุณาระบุชื่อหัตถการก่อน')),
                              );
                            }
                          },
                        ),
                      if (_safetyChecked)
                        AiraPremiumSaveButton(
                          label: _loading
                              ? (isThai ? 'กำลังบันทึก...' : 'Saving...')
                              : (isThai ? 'บันทึกการรักษา' : 'Save Treatment'),
                          loading: _loading,
                          onTap: _save,
                        ),
                      const SizedBox(height: 16),
                      const AiraBrandingFooter(),
                      const SizedBox(height: 40),
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


  Widget _buildWarningsBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _warnings.any((w) => w.level == WarningLevel.danger)
            ? Colors.red.shade50
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _warnings.any((w) => w.level == WarningLevel.danger)
              ? Colors.red.shade200
              : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_rounded,
                size: 18,
                color: _warnings.any((w) => w.level == WarningLevel.danger)
                    ? Colors.red
                    : Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                'ผลตรวจสอบความปลอดภัย (${_warnings.length} รายการ)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...(_warnings.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      w.level == WarningLevel.danger
                          ? Icons.error
                          : w.level == WarningLevel.caution
                              ? Icons.warning_amber_rounded
                              : Icons.info_outline,
                      size: 16,
                      color: w.level == WarningLevel.danger
                          ? Colors.red
                          : w.level == WarningLevel.caution
                              ? Colors.orange
                              : AiraColors.woodMid,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${w.title}: ${w.message}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ))),
        ],
      ),
    );
  }

  Widget _buildTreatmentInfoSection() {
    return AiraPremiumCard(
      accentColor: AiraColors.woodMid,
      children: [
        TextFormField(
          controller: _treatmentNameCtrl,
          style: airaFieldTextStyle,
          decoration: airaFieldDecoration(label: 'ชื่อหัตถการ *', hint: 'เช่น Botox Forehead, Filler Chin...', prefixIcon: Icons.medical_services_rounded),
          validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อหัตถการ' : null,
          onChanged: (_) => setState(() => _safetyChecked = false),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<TreatmentCategory>(
          value: _category,
          style: airaFieldTextStyle,
          decoration: airaFieldDecoration(label: 'หมวดหมู่', prefixIcon: Icons.category_rounded),
          items: TreatmentCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(_categoryLabel(c), style: airaFieldTextStyle))).toList(),
          onChanged: (v) { if (v != null) setState(() => _category = v); },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSoapSection() {
    return AiraPremiumCard(
      accentColor: AiraColors.sage,
      children: [
        _soapField(_ccCtrl, 'S — Subjective (อาการสำคัญ)', 'ผู้รับบริการมาด้วยเรื่อง...', Icons.record_voice_over_rounded),
        _soapField(_objectiveCtrl, 'O — Objective (ตรวจร่างกาย)', 'PE: ผิวหน้า...', Icons.visibility_rounded),
        _soapField(_assessmentCtrl, 'A — Assessment (การวินิจฉัย)', 'Dx: ...', Icons.analytics_rounded),
        _soapField(_planCtrl, 'P — Plan (แผนการรักษา)', 'Plan: Botox 20U forehead...', Icons.assignment_rounded),
      ],
    );
  }

  Widget _soapField(TextEditingController ctrl, String label, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        maxLines: 2,
        style: airaFieldTextStyle,
        decoration: airaFieldDecoration(label: label, hint: hint, prefixIcon: icon),
      ),
    );
  }

  Widget _buildDeviceSection() {
    return AiraPremiumCard(
      accentColor: AiraColors.gold,
      children: [
        Row(children: [
          Expanded(child: _premiumField('เครื่อง/อุปกรณ์', _deviceCtrl, icon: Icons.devices_rounded)),
          const SizedBox(width: 14),
          Expanded(child: _premiumField('Energy / Power', _energyCtrl, icon: Icons.bolt_rounded)),
        ]),
        Row(children: [
          Expanded(child: _premiumField('Pulse / Spot size', _pulseSpotCtrl, icon: Icons.timer_rounded)),
          const SizedBox(width: 14),
          Expanded(child: _premiumField('จำนวน Shots', _totalShotsCtrl, icon: Icons.tag_rounded, keyboard: TextInputType.number)),
        ]),
      ],
    );
  }

  Widget _buildProductsSection() {
    return AiraPremiumCard(
      accentColor: AiraColors.gold,
      children: [
        ..._productsUsed.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AiraColors.parchment.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2_rounded, size: 16, color: AiraColors.woodLt),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Text(p['name'] ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.charcoal)),
                ),
                const SizedBox(width: 8),
                Text('${p['quantity'] ?? 0} ${p['unit'] ?? 'U'}', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                AiraTapEffect(
                  onTap: () { setState(() { _productsUsed.removeAt(i); _safetyChecked = false; }); },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: AiraColors.terra.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.close_rounded, size: 16, color: AiraColors.terra),
                  ),
                ),
              ],
            ),
          );
        }),
        _premiumField('จำนวนหน่วยรวมที่ใช้ (Units)', _unitsUsedCtrl, hint: 'เช่น 20', icon: Icons.straighten_rounded, keyboard: TextInputType.number),
        AiraTapEffect(
          onTap: _showAddProductDialog,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AiraColors.woodWash.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.3), style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 18, color: AiraColors.woodMid),
                const SizedBox(width: 8),
                Text('เพิ่มผลิตภัณฑ์', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.woodMid)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'U');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่มผลิตภัณฑ์'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'ชื่อผลิตภัณฑ์',
                hintText: 'เช่น Botulinum Toxin Type A',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyCtrl,
                    decoration: const InputDecoration(labelText: 'จำนวน'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: unitCtrl,
                    decoration: const InputDecoration(labelText: 'หน่วย'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _productsUsed.add({
                    'name': nameCtrl.text.trim(),
                    'quantity': double.tryParse(qtyCtrl.text.trim()) ?? 0,
                    'unit': unitCtrl.text.trim(),
                  });
                  _safetyChecked = false;
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseSection() {
    return AiraPremiumCard(
      accentColor: AiraColors.terra,
      children: [
        DropdownButtonFormField<TreatmentResponse>(
          value: _response,
          style: airaFieldTextStyle,
          decoration: airaFieldDecoration(label: 'Response to Previous Treatment', prefixIcon: Icons.trending_up_rounded),
          items: TreatmentResponse.values.map((r) => DropdownMenuItem(value: r, child: Text(_responseLabel(r), style: airaFieldTextStyle))).toList(),
          onChanged: (v) { if (v != null) setState(() => _response = v); },
        ),
        const SizedBox(height: 14),
        Text('Adverse Events', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _adverseEvents.map((e) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AiraColors.terra.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AiraColors.terra.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(e, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.terra)),
              const SizedBox(width: 6),
              AiraTapEffect(
                onTap: () => setState(() => _adverseEvents.remove(e)),
                child: Icon(Icons.close_rounded, size: 14, color: AiraColors.terra),
              ),
            ]),
          )).toList(),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _adverseCtrl,
              style: airaFieldTextStyle,
              decoration: airaFieldDecoration(label: '', hint: 'เช่น บวม, แดง, ช้ำ...', prefixIcon: Icons.warning_amber_rounded),
            ),
          ),
          const SizedBox(width: 8),
          AiraTapEffect(
            onTap: () {
              if (_adverseCtrl.text.trim().isNotEmpty) {
                setState(() { _adverseEvents.add(_adverseCtrl.text.trim()); _adverseCtrl.clear(); });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(gradient: AiraColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            ),
          ),
        ]),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildFollowUpSection() {
    return AiraPremiumCard(
      accentColor: AiraColors.woodLt,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AiraTapEffect(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 14)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _followUpDate = picked);
            },
            child: AbsorbPointer(
              child: TextFormField(
                style: airaFieldTextStyle,
                decoration: airaFieldDecoration(
                  label: 'วันนัดติดตามผล',
                  hint: 'เลือกวันที่',
                  prefixIcon: Icons.calendar_month_rounded,
                  suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16, color: AiraColors.woodMid),
                ),
                controller: TextEditingController(
                  text: _followUpDate != null ? DateFormat('dd/MM/yyyy').format(_followUpDate!) : '',
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AiraTapEffect(
            onTap: () async {
              final initial = TimeOfDay(
                hour: int.tryParse(_followUpTimeCtrl.text.split(':').first) ?? 10,
                minute: int.tryParse(_followUpTimeCtrl.text.split(':').last) ?? 0,
              );
              final picked = await showTimePicker(context: context, initialTime: initial);
              if (picked != null) {
                setState(() {
                  _followUpTimeCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                });
              }
            },
            child: AbsorbPointer(
              child: TextFormField(
                controller: _followUpTimeCtrl,
                style: airaFieldTextStyle,
                decoration: airaFieldDecoration(
                  label: 'เวลานัด',
                  hint: 'กดเพื่อเลือกเวลา',
                  prefixIcon: Icons.access_time_rounded,
                  suffixIcon: const Icon(Icons.schedule_rounded, size: 16, color: AiraColors.woodMid),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    const quickInstructions = [
      'ห้ามโดนแดด 2 สัปดาห์',
      'ประคบเย็น 10 นาที',
      'ทาครีมกันแดด SPF50+',
      'งดออกกำลังกายหนัก 24 ชม.',
      'ห้ามนวดหน้า 2 สัปดาห์',
      'งดแอลกอฮอล์ 24 ชม.',
    ];
    return AiraPremiumCard(
      accentColor: AiraColors.sage,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickInstructions.map((instr) {
            final selected = _instructions.contains(instr);
            return AiraTapEffect(
              onTap: () {
                setState(() {
                  if (selected) { _instructions.remove(instr); } else { _instructions.add(instr); }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AiraColors.sage.withValues(alpha: 0.12) : AiraColors.parchment.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? AiraColors.sage : AiraColors.woodPale.withValues(alpha: 0.25)),
                ),
                child: Text(instr, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? AiraColors.sage : AiraColors.charcoal)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Custom instructions
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _instructions.where((i) => !quickInstructions.contains(i)).map((i) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AiraColors.woodWash.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(i, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoal)),
              const SizedBox(width: 6),
              AiraTapEffect(
                onTap: () => setState(() => _instructions.remove(i)),
                child: Icon(Icons.close_rounded, size: 14, color: AiraColors.muted),
              ),
            ]),
          )).toList(),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _instructionCtrl,
              style: airaFieldTextStyle,
              decoration: airaFieldDecoration(label: '', hint: 'เพิ่มคำแนะนำเอง...', prefixIcon: Icons.edit_rounded),
            ),
          ),
          const SizedBox(width: 8),
          AiraTapEffect(
            onTap: () {
              if (_instructionCtrl.text.trim().isNotEmpty) {
                setState(() { _instructions.add(_instructionCtrl.text.trim()); _instructionCtrl.clear(); });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(gradient: AiraColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            ),
          ),
        ]),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _premiumField(String label, TextEditingController ctrl, {String? hint, IconData? icon, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        style: airaFieldTextStyle,
        decoration: airaFieldDecoration(label: label, hint: hint, prefixIcon: icon),
      ),
    );
  }

  String _categoryLabel(TreatmentCategory c) {
    switch (c) {
      case TreatmentCategory.injectable:
        return 'Injectable (ฉีด)';
      case TreatmentCategory.laser:
        return 'Laser (เลเซอร์)';
      case TreatmentCategory.treatment:
        return 'Treatment (ทรีทเมนต์)';
      case TreatmentCategory.other:
        return 'อื่นๆ';
    }
  }

  String _responseLabel(TreatmentResponse r) {
    switch (r) {
      case TreatmentResponse.improved:
        return 'ดีขึ้น (Improved)';
      case TreatmentResponse.stable:
        return 'คงที่ (Stable)';
      case TreatmentResponse.worse:
        return 'แย่ลง (Worse)';
      case TreatmentResponse.notApplicable:
        return 'ไม่ระบุ (N/A)';
    }
  }
}
