import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/aira_premium_form.dart';
import '../../core/localization/app_localizations.dart';
import '../treatments/smart_pickers.dart';

class CourseFormScreen extends ConsumerStatefulWidget {
  final String? courseId;
  final String? initialPatientId;
  /// Pre-selects the treatment category when launched from the
  /// injection / laser / treatment tabs (per client request Jun 2026).
  final TreatmentCategory? initialCategory;

  const CourseFormScreen({super.key, this.courseId, this.initialPatientId, this.initialCategory});

  bool get isEdit => courseId != null && courseId != 'new';

  @override
  ConsumerState<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends ConsumerState<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _sessionsBoughtCtrl = TextEditingController(text: '10');
  final _sessionsBonusCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  String? _selectedPatientId;
  String _patientSearch = '';
  CourseStatus _status = CourseStatus.active;
  DateTime? _expiryDate;

  // Per client request (May 17): courses now carry their own treatment
  // category, responsible doctor and a list of products consumed per
  // session. This mirrors the treatment form so the clinic can plan a
  // course end-to-end in one place.
  TreatmentCategory _treatmentCategory = TreatmentCategory.injectable;
  String? _selectedDoctorId;
  final List<Map<String, dynamic>> _productsUsed = [];

  // ─── Discount + auto-charge UX (added per client feedback May 27) ───
  // Quick discount chips on the price field so receptionists can apply
  // 5/10/20% promos without a calculator. Final discounted price is what
  // gets saved to `course.price`; the original subtotal + discount note
  // is appended to the course notes for audit trail.
  int _discountPct = 0; // 0 / 5 / 10 / 20
  // ครั้งเดียว (single) vs คอร์ส (course) — per client requirement (Jun 2026).
  // single => sessionsBought ล็อกเป็น 1, ป้ายราคาเป็น "ราคาต่อครั้ง".
  bool _isCourse = true;
  // When ON (default for new courses), saving the course also creates an
  // outstanding `charge` record in financial_records so the receptionist
  // does NOT have to open the Financial screen separately. This was the
  // single biggest pain point flagged by the clinic team — they kept
  // saying "there's only USE service, not BUY/PRICE/COURSE".
  bool _autoCreateCharge = true;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.initialPatientId;
    if (widget.initialCategory != null) {
      _treatmentCategory = widget.initialCategory!;
    }
    if (widget.isEdit) _loadExisting();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _sessionsBoughtCtrl.dispose();
    _sessionsBonusCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final repo = ref.read(courseRepoProvider);
    final course = await repo.get(widget.courseId!);
    if (course == null || !mounted) return;
    setState(() {
      _nameCtrl.text = course.name;
      _priceCtrl.text = course.price?.toStringAsFixed(0) ?? '';
      _sessionsBoughtCtrl.text = course.sessionsBought.toString();
      _sessionsBonusCtrl.text = course.sessionsBonus.toString();
      _isCourse = (course.sessionsBought + course.sessionsBonus) > 1;
      _notesCtrl.text = course.notes ?? '';
      _selectedPatientId = course.patientId;
      _status = course.status;
      _expiryDate = course.expiryDate;
      if (course.treatmentCategory != null) {
        _treatmentCategory =
            TreatmentCategory.fromDb(course.treatmentCategory!.toUpperCase());
      }
      _selectedDoctorId = course.responsibleDoctorId;
      for (final p in course.productsUsed) {
        if (p is Map) {
          _productsUsed.add(Map<String, dynamic>.from(p));
        }
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.selectPatient)));
      return;
    }

    setState(() => _loading = true);
    final clinicId = ref.read(currentClinicIdProvider);
    if (clinicId == null) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.clinicContextMissing),
            backgroundColor: AiraColors.terra,
          ),
        );
      }
      return;
    }

    // Apply discount to the saved price. Original subtotal is preserved
    // in notes for audit trail.
    final basePrice = double.tryParse(_priceCtrl.text.trim());
    final finalPrice = (basePrice != null && _discountPct > 0)
        ? basePrice * (1 - _discountPct / 100)
        : basePrice;
    final discountTag = (basePrice != null && _discountPct > 0)
        ? 'ส่วนลด $_discountPct% (฿${basePrice.toStringAsFixed(0)} → ฿${finalPrice!.toStringAsFixed(0)})'
        : '';
    final userNotes = _notesCtrl.text.trim();
    final finalNotes = [userNotes, discountTag]
        .where((s) => s.isNotEmpty)
        .join(' • ');

    final courseId = widget.isEdit ? widget.courseId! : const Uuid().v4();
    final course = Course(
      id: courseId,
      clinicId: clinicId,
      patientId: _selectedPatientId!,
      name: _nameCtrl.text.trim(),
      price: finalPrice,
      sessionsBought: _isCourse ? (int.tryParse(_sessionsBoughtCtrl.text.trim()) ?? 1) : 1,
      sessionsBonus: _isCourse ? (int.tryParse(_sessionsBonusCtrl.text.trim()) ?? 0) : 0,
      status: _status,
      expiryDate: _isCourse ? _expiryDate : null,
      notes: finalNotes.isEmpty ? null : finalNotes,
      treatmentCategory: _treatmentCategory.dbValue.toLowerCase(),
      responsibleDoctorId:
          (_selectedDoctorId != null && _selectedDoctorId!.isNotEmpty)
              ? _selectedDoctorId
              : null,
      productsUsed: _productsUsed,
    );

    try {
      final repo = ref.read(courseRepoProvider);
      if (widget.isEdit) {
        await repo.updateCourse(course);
        ref.invalidate(courseByIdProvider(widget.courseId!));
      } else {
        await repo.create(course);
        // Optional: auto-create outstanding charge so the receptionist
        // doesn't have to open the Financial screen separately.
        if (_autoCreateCharge && finalPrice != null && finalPrice > 0) {
          try {
            final finRepo = ref.read(financialRepoProvider);
            await finRepo.create(FinancialRecord(
              id: const Uuid().v4(),
              clinicId: clinicId,
              patientId: _selectedPatientId!,
              courseId: courseId,
              type: FinancialType.charge,
              amount: finalPrice,
              description:
                  'ค่าคอร์ส: ${_nameCtrl.text.trim()}${discountTag.isNotEmpty ? ' • $discountTag' : ''}',
              isOutstanding: true,
            ));
            ref.invalidate(financialListProvider);
            ref.invalidate(outstandingRecordsProvider);
            ref.invalidate(financialsByPatientProvider(_selectedPatientId!));
          } catch (_) {
            // Don't block course creation if charge fails — receptionist
            // can still add the charge manually.
          }
        }
      }
      ref.invalidate(courseListProvider);
      ref.invalidate(coursesByPatientProvider(_selectedPatientId!));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEdit ? context.l10n.courseEditSuccess : context.l10n.courseSaveSuccess), backgroundColor: AiraColors.sage),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.saveFailed('$e')), backgroundColor: AiraColors.terra));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── ครั้งเดียว / คอร์ส segmented toggle ───
  Widget _buildTypeToggle() {
    final isThai = context.l10n.isThai;
    Widget seg(String label, IconData icon, bool selected, VoidCallback onTap) {
      return Expanded(
        child: AiraTapEffect(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AiraColors.woodDk : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 18, color: selected ? Colors.white : AiraColors.muted),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AiraColors.muted,
                ),
              ),
            ]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AiraColors.creamDk,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        seg(isThai ? 'ครั้งเดียว' : 'Single', Icons.bolt_rounded, !_isCourse,
            () => setState(() => _isCourse = false)),
        seg(isThai ? 'คอร์ส' : 'Course', Icons.card_membership_rounded, _isCourse,
            () => setState(() => _isCourse = true)),
      ]),
    );
  }

  // ─── เลือกจากคลังบริการ → auto-fill ชื่อ + ประเภท + ราคา default ───
  Future<void> _onPickService() async {
    final selected = await pickService(context: context, ref: ref);
    if (selected == null || !mounted) return;
    setState(() {
      _nameCtrl.text = selected.name;
      _treatmentCategory = _serviceToTreatmentCategory(selected.category);
      if (selected.defaultPrice != null && selected.defaultPrice! > 0) {
        _priceCtrl.text = selected.defaultPrice!.toStringAsFixed(0);
      }
    });
  }

  TreatmentCategory _serviceToTreatmentCategory(ServiceCategory c) {
    switch (c) {
      case ServiceCategory.ha:
      case ServiceCategory.injectable:
        return TreatmentCategory.injectable;
      case ServiceCategory.laser:
        return TreatmentCategory.laser;
      case ServiceCategory.treatment:
        return TreatmentCategory.treatment;
      case ServiceCategory.other:
        return TreatmentCategory.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientListProvider);
    final _ = ref.watch(isThaiProvider); // keep provider active for l10n rebuild

    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          AiraPremiumHeader(
            title: widget.isEdit
                ? context.l10n.editCourse
                : context.l10n.newCourse,
            subtitle: context.l10n.courseManagementSubtitle,
            loading: _loading,
            onBack: () => context.pop(),
            onSave: _loading ? null : _save,
            saveLabel: context.l10n.save,
            steps: premiumSteps([
              (1, context.l10n.patient),
              (2, context.l10n.isThai ? 'บริการ / คอร์ส' : 'Service / Course'),
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
                      // ─── Patient selector ───
                      AiraSectionHeader(step: 1, icon: Icons.person_rounded, title: context.l10n.patient, subtitle: context.l10n.selectPatientForAppt),
                      _buildPatientSelector(patientsAsync),
                      const SizedBox(height: 28),

                      // ─── บริการ / คอร์ส (ล็อคเดียว — ตาม requirement ลูกค้า Jun 2026) ───
                      AiraSectionHeader(
                        step: 2,
                        icon: Icons.card_membership_rounded,
                        title: context.l10n.isThai ? 'บริการ / คอร์ส' : 'Service / Course',
                        subtitle: context.l10n.isThai
                            ? 'ชื่อบริการ • ครั้ง/คอร์ส • ประเภท • จำนวนครั้ง • ราคา • แพทย์ — ในที่เดียว'
                            : 'Name • single/course • category • sessions • price • doctor — in one place',
                      ),
                      AiraPremiumCard(accentColor: AiraColors.woodMid, children: [
                        // 1) ชื่อบริการ
                        TextFormField(
                          controller: _nameCtrl,
                          style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(
                            label: context.l10n.isThai ? 'ชื่อบริการ *' : 'Service name *',
                            hint: context.l10n.isThai ? 'เช่น Oligio 600 shots, Botox' : 'e.g. Oligio 600 shots',
                            prefixIcon: Icons.medical_services_rounded,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? (context.l10n.isThai ? 'กรุณาระบุชื่อบริการ' : 'Please enter a service name')
                              : null,
                        ),
                        const SizedBox(height: 10),
                        // เลือกจากคลังบริการ → auto-fill ราคา/ประเภท
                        AiraTapEffect(
                          onTap: _onPickService,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AiraColors.woodWash.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AiraColors.woodMid.withValues(alpha: 0.3)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.search_rounded, size: 18, color: AiraColors.woodMid),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.l10n.isThai
                                      ? 'เลือกจากคลังบริการ (เติมราคาให้อัตโนมัติ)'
                                      : 'Pick from Service Library (auto-fills price)',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.woodDk),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: AiraColors.woodMid),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 2) ครั้งเดียว / คอร์ส
                        _buildTypeToggle(),
                        const SizedBox(height: 16),
                        // 3) ประเภท
                        DropdownButtonFormField<TreatmentCategory>(
                          value: _treatmentCategory,
                          isExpanded: true,
                          style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(
                            label: context.l10n.treatmentCategory,
                            prefixIcon: Icons.category_rounded,
                          ),
                          items: TreatmentCategory.values
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(_treatmentCategoryLabel(c), style: airaFieldTextStyle),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _treatmentCategory = v);
                          },
                        ),
                        const SizedBox(height: 14),
                        // 4) จำนวนครั้ง + แถม (เฉพาะคอร์ส)
                        if (_isCourse) ...[
                          Row(children: [
                            Expanded(
                              child: TextFormField(
                                controller: _sessionsBoughtCtrl,
                                style: airaFieldTextStyle,
                                decoration: airaFieldDecoration(label: context.l10n.isThai ? 'จำนวนครั้ง' : 'Sessions', prefixIcon: Icons.confirmation_number_rounded),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _sessionsBonusCtrl,
                                style: airaFieldTextStyle,
                                decoration: airaFieldDecoration(label: context.l10n.isThai ? 'แถม (ครั้ง)' : 'Bonus', prefixIcon: Icons.card_giftcard_rounded),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          Builder(builder: (_) {
                            final bought = int.tryParse(_sessionsBoughtCtrl.text) ?? 0;
                            final bonus = int.tryParse(_sessionsBonusCtrl.text) ?? 0;
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                              decoration: BoxDecoration(
                                color: AiraColors.sage.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AiraColors.sage.withValues(alpha: 0.2)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.summarize_rounded, size: 16, color: AiraColors.sage),
                                const SizedBox(width: 8),
                                Text(context.l10n.totalSessions(bought, bonus), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.sage)),
                              ]),
                            );
                          }),
                          const SizedBox(height: 14),
                        ],
                        // 5) ราคา (label สลับตาม single/course)
                        TextFormField(
                          controller: _priceCtrl,
                          style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(
                            label: '${_isCourse ? context.l10n.pricePerCourse : context.l10n.pricePerSession} (฿) *',
                            hint: 'เช่น 15000',
                            prefixIcon: Icons.payments_rounded,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        // ─── Discount preset chips (5/10/20%) ───
                        Row(
                          children: [
                            const Icon(Icons.local_offer_rounded, size: 16, color: AiraColors.muted),
                            const SizedBox(width: 6),
                            Text(
                              context.l10n.isThai ? 'ส่วนลด' : 'Discount',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.muted),
                            ),
                            const SizedBox(width: 10),
                            ...[0, 5, 10, 20].map((pct) {
                              final selected = _discountPct == pct;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: AiraTapEffect(
                                  onTap: () => setState(() => _discountPct = pct),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: selected ? AiraColors.gold : AiraColors.creamDk,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: selected ? AiraColors.gold : AiraColors.woodPale.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      pct == 0 ? (context.l10n.isThai ? 'ไม่มี' : 'None') : '$pct%',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: selected ? Colors.white : AiraColors.charcoal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                        Builder(builder: (_) {
                          final base = double.tryParse(_priceCtrl.text.trim()) ?? 0;
                          if (_discountPct == 0 || base <= 0) return const SizedBox(height: 14);
                          final finalAmt = base * (1 - _discountPct / 100);
                          final saved = base - finalAmt;
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AiraColors.sage.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AiraColors.sage.withValues(alpha: 0.25)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.check_circle_rounded, size: 16, color: AiraColors.sage),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    context.l10n.isThai
                                        ? 'ราคาหลังหัก $_discountPct%: ฿${finalAmt.toStringAsFixed(0)}  (ลด ฿${saved.toStringAsFixed(0)})'
                                        : 'After $_discountPct% off: ฿${finalAmt.toStringAsFixed(0)}  (saved ฿${saved.toStringAsFixed(0)})',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AiraColors.sage),
                                  ),
                                ),
                              ]),
                            ),
                          );
                        }),
                        // Read-only computed price-per-session (เฉพาะคอร์ส)
                        if (_isCourse) ...[
                        const SizedBox(height: 14),
                        Builder(
                          builder: (_) {
                            final total = double.tryParse(_priceCtrl.text.trim()) ?? 0;
                            final bought = int.tryParse(_sessionsBoughtCtrl.text.trim()) ?? 0;
                            final bonus = int.tryParse(_sessionsBonusCtrl.text.trim()) ?? 0;
                            final sessions = bought + bonus;
                            final perSession = sessions > 0 ? total / sessions : 0;
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AiraColors.gold.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AiraColors.gold.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calculate_rounded,
                                      size: 18, color: AiraColors.gold),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.l10n.pricePerSession,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AiraColors.muted,
                                          ),
                                        ),
                                        Text(
                                          sessions > 0
                                              ? '฿${perSession.toStringAsFixed(0)} × $sessions ${context.l10n.sessionsCountLabel.toLowerCase()}'
                                              : context.l10n.pricePerSessionHint,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AiraColors.charcoal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        ],
                        const SizedBox(height: 14),
                        // 6) แพทย์ที่ทำหัตถการ (อยู่ในล็อคเดียวกัน — ตาม requirement ลูกค้า)
                        _buildDoctorDropdown(),
                        const SizedBox(height: 8),
                        // ─── Auto-create outstanding charge toggle ───
                        // Hidden when editing — only meaningful at sale time.
                        if (!widget.isEdit) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _autoCreateCharge
                                  ? AiraColors.gold.withValues(alpha: 0.08)
                                  : AiraColors.creamDk,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _autoCreateCharge
                                    ? AiraColors.gold.withValues(alpha: 0.35)
                                    : AiraColors.woodPale.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(children: [
                              Icon(Icons.receipt_long_rounded, size: 18, color: _autoCreateCharge ? AiraColors.gold : AiraColors.muted),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n.isThai ? 'บันทึกเป็นค่าใช้จ่ายค้างชำระอัตโนมัติ' : 'Auto-create outstanding charge',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      context.l10n.isThai
                                          ? 'ลูกค้าจะมีรายการค้างชำระเท่ากับราคาคอร์สทันที — ไม่ต้องไปกดเองที่หน้า Financial'
                                          : 'Patient will have an outstanding balance equal to course price — no need to add it manually',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _autoCreateCharge,
                                activeColor: AiraColors.gold,
                                onChanged: (v) => setState(() => _autoCreateCharge = v),
                              ),
                            ]),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 28),

                      // ─── ผลิตภัณฑ์ที่ใช้ (ต่อครั้ง) — ส่วนเสริม ───
                      AiraSectionHeader(
                        step: 0,
                        icon: Icons.inventory_2_rounded,
                        title: context.l10n.isThai ? 'ผลิตภัณฑ์ที่ใช้' : 'Products Used',
                        subtitle: context.l10n.isThai
                            ? 'ผลิตภัณฑ์/ยา ที่ใช้ต่อครั้ง (ไม่บังคับ)'
                            : 'Products / meds used per session (optional)',
                      ),
                      AiraPremiumCard(accentColor: AiraColors.terra, children: [
                        _buildProductsPicker(),
                        const SizedBox(height: 8),
                      ]),
                      const SizedBox(height: 28),

                      // ─── Expiry (เฉพาะคอร์ส) ───
                      if (_isCourse) ...[
                      const AiraSectionHeader(step: 0, icon: Icons.event_rounded, title: 'วันหมดอายุ'),
                      AiraPremiumCard(accentColor: AiraColors.gold, children: [
                        AiraTapEffect(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 1095)),
                            );
                            if (picked != null) setState(() => _expiryDate = picked);
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              style: airaFieldTextStyle,
                              decoration: airaFieldDecoration(
                                label: 'วันหมดอายุ',
                                hint: 'ไม่ระบุ = ไม่หมดอายุ',
                                prefixIcon: Icons.event_rounded,
                                suffixIcon: _expiryDate != null
                                    ? AiraTapEffect(
                                        onTap: () => setState(() => _expiryDate = null),
                                        child: const Icon(Icons.clear, size: 16, color: AiraColors.muted),
                                      )
                                    : const Icon(Icons.calendar_today_rounded, size: 16, color: AiraColors.woodMid),
                              ),
                              controller: TextEditingController(
                                text: _expiryDate != null ? DateFormat('dd/MM/yyyy').format(_expiryDate!) : '',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ]),
                      const SizedBox(height: 28),
                      ],

                      // ─── Notes ───
                      const AiraSectionHeader(step: 0, icon: Icons.note_rounded, title: 'หมายเหตุ'),
                      AiraPremiumCard(accentColor: AiraColors.muted, children: [
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 3,
                          style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(label: 'หมายเหตุเพิ่มเติม', hint: 'หมายเหตุเพิ่มเติม...', prefixIcon: Icons.notes_rounded),
                        ),
                        const SizedBox(height: 8),
                      ]),
                      const SizedBox(height: 32),

                      AiraPremiumSaveButton(
                        label: _loading
                            ? context.l10n.saving
                            : context.l10n.saveCourse,
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

  Widget _buildPatientSelector(AsyncValue<List<Patient>> patientsAsync) {
    return AiraPremiumCard(
      accentColor: AiraColors.woodDk,
      children: [
        TextField(
          style: airaFieldTextStyle,
          decoration: airaFieldDecoration(label: '', hint: 'ค้นหาผู้รับบริการ...', prefixIcon: Icons.search_rounded),
          onChanged: (v) => setState(() => _patientSearch = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 10),
        patientsAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
          error: (e, s) => Text('Error: $e'),
          data: (patients) {
            var filtered = patients;
            if (_patientSearch.isNotEmpty) {
              filtered = patients.where((p) =>
                  '${p.firstName} ${p.lastName}'.toLowerCase().contains(_patientSearch) ||
                  (p.nickname?.toLowerCase().contains(_patientSearch) ?? false) ||
                  (p.phone?.contains(_patientSearch) ?? false)).toList();
            }
            return SizedBox(
              height: 150,
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  final selected = _selectedPatientId == p.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: selected ? AiraColors.woodWash.withValues(alpha: 0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: selected ? Border.all(color: AiraColors.woodMid.withValues(alpha: 0.3)) : null,
                    ),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: selected ? AiraColors.woodDk : AiraColors.woodWash,
                        child: Text(p.firstName.isNotEmpty ? p.firstName[0] : '?', style: TextStyle(color: selected ? Colors.white : AiraColors.woodDk, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      title: Text('${p.firstName} ${p.lastName}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.charcoal)),
                      subtitle: Text(p.hn ?? p.phone ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted)),
                      trailing: selected ? const Icon(Icons.check_circle, color: AiraColors.sage, size: 18) : null,
                      onTap: () => setState(() => _selectedPatientId = p.id),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ─── Helpers added in May 17 round ─────────────────────────

  String _treatmentCategoryLabel(TreatmentCategory c) {
    final isThai = context.l10n.isThai;
    switch (c) {
      case TreatmentCategory.injectable:
        return isThai ? 'ฉีด (Injectable)' : 'Injectable';
      case TreatmentCategory.laser:
        return isThai ? 'เลเซอร์ / เครื่อง (Laser)' : 'Laser / Device';
      case TreatmentCategory.treatment:
        return isThai ? 'ทรีทเมนต์ (Treatment)' : 'Treatment';
      case TreatmentCategory.other:
        return isThai ? 'อื่นๆ (Other)' : 'Other';
    }
  }

  /// Maps a course-level treatment category to the product category
  /// shown in the picker. "Treatment" courses include all skincare-style
  /// SKUs except the obvious laser machines.
  bool _matchesCategory(Product product) {
    switch (_treatmentCategory) {
      case TreatmentCategory.injectable:
        return product.category == ProductCategory.botox ||
            product.category == ProductCategory.filler ||
            product.category == ProductCategory.biostimulator ||
            product.category == ProductCategory.polynucleotide ||
            product.category == ProductCategory.skinbooster;
      case TreatmentCategory.laser:
        return product.category == ProductCategory.laser;
      case TreatmentCategory.treatment:
        // Anything that isn't a laser machine is fair game.
        return product.category != ProductCategory.laser;
      case TreatmentCategory.other:
        return true;
    }
  }

  Widget _buildDoctorDropdown() {
    final clinicId = ref.watch(currentClinicIdProvider);
    if (clinicId == null) {
      return const SizedBox.shrink();
    }
    final doctorsAsync = ref.watch(_courseDoctorsProvider);
    return doctorsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
      ),
      error: (e, _) => Text(
        '${context.l10n.isThai ? "โหลดรายชื่อแพทย์ไม่สำเร็จ" : "Could not load doctors"}: $e',
        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.terra),
      ),
      data: (doctors) {
        final hasSelection = doctors.any((d) => d.id == _selectedDoctorId);
        final selected = hasSelection
            ? doctors.firstWhere((d) => d.id == _selectedDoctorId)
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: hasSelection ? _selectedDoctorId : null,
              isExpanded: true,
              style: airaFieldTextStyle,
              decoration: airaFieldDecoration(
                label: context.l10n.isThai
                    ? 'แพทย์ผู้รับผิดชอบ (Treating Doctor)'
                    : 'Treating Doctor',
                hint: context.l10n.doctorHint,
                prefixIcon: Icons.person_rounded,
              ),
              items: doctors.map((d) {
                final lic = d.licenseNumber;
                final licLabel = (lic != null && lic.trim().isNotEmpty)
                    ? ' • ว.${lic.trim()}'
                    : '';
                return DropdownMenuItem(
                  value: d.id,
                  child: Text(
                    '${d.fullName}$licLabel',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: doctors.isEmpty
                  ? null
                  : (v) => setState(() => _selectedDoctorId = v),
            ),
            if (selected != null && selected.licenseNumber != null &&
                selected.licenseNumber!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.badge_rounded,
                      size: 16, color: AiraColors.gold),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.isThai ? 'เลข ว.' : 'License No.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AiraColors.muted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    selected.licenseNumber!.trim(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AiraColors.charcoal,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildProductsPicker() {
    final productsAsync = ref.watch(productListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.isThai
              ? 'ผลิตภัณฑ์ที่ใช้ในคอร์ส (ต่อครั้ง)'
              : 'Products Used (Per Session)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AiraColors.charcoal,
          ),
        ),
        const SizedBox(height: 8),
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
                const Icon(Icons.inventory_2_rounded,
                    size: 16, color: AiraColors.woodLt),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    p['name']?.toString() ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AiraColors.charcoal,
                    ),
                  ),
                ),
                Text(
                  '${p['quantity'] ?? 0} ${p['unit'] ?? 'U'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AiraColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                AiraTapEffect(
                  onTap: () =>
                      setState(() => _productsUsed.removeAt(i)),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AiraColors.terra.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 14, color: AiraColors.terra),
                  ),
                ),
              ],
            ),
          );
        }),
        productsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
                child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AiraColors.woodMid))),
          ),
          error: (e, _) => Text(
            '${context.l10n.isThai ? "โหลดผลิตภัณฑ์ไม่สำเร็จ" : "Could not load products"}: $e',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: AiraColors.terra),
          ),
          data: (products) {
            final filtered = products.where(_matchesCategory).toList();
            return AiraTapEffect(
              onTap: filtered.isEmpty
                  ? null
                  : () => _showProductPicker(filtered),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: filtered.isEmpty
                      ? AiraColors.muted.withValues(alpha: 0.06)
                      : AiraColors.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AiraColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline_rounded,
                        size: 18,
                        color: filtered.isEmpty
                            ? AiraColors.muted
                            : AiraColors.gold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        filtered.isEmpty
                            ? (context.l10n.isThai
                                ? 'ยังไม่มีผลิตภัณฑ์ในหมวดนี้ — เพิ่มได้ที่หน้าคลังสินค้า'
                                : 'No products in this category yet — add some in Inventory')
                            : (context.l10n.isThai
                                ? 'เพิ่มผลิตภัณฑ์ (${filtered.length} รายการ)'
                                : 'Add Product (${filtered.length} available)'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: filtered.isEmpty
                              ? AiraColors.muted
                              : AiraColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showProductPicker(List<Product> products) async {
    final qtyCtrl = TextEditingController(text: '1');
    Product? selected = products.first;
    final isThai = context.l10n.isThai;

    final added = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isThai ? 'เลือกผลิตภัณฑ์' : 'Select Product',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AiraColors.charcoal,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<Product>(
                value: selected,
                isExpanded: true,
                decoration: airaFieldDecoration(
                  label: isThai ? 'ผลิตภัณฑ์' : 'Product',
                  prefixIcon: Icons.inventory_2_rounded,
                ),
                items: products
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.name}${p.brand != null ? " (${p.brand})" : ""}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setSheet(() => selected = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: airaFieldTextStyle,
                decoration: airaFieldDecoration(
                  label: isThai ? 'จำนวนต่อครั้ง' : 'Quantity per session',
                  prefixIcon: Icons.tag_rounded,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(context.l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AiraColors.woodMid,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (selected == null) {
                          Navigator.pop(ctx);
                          return;
                        }
                        Navigator.pop(ctx, {
                          'product_id': selected!.id,
                          'name': selected!.name,
                          'unit': selected!.unit,
                          'quantity':
                              double.tryParse(qtyCtrl.text.trim()) ?? 1,
                        });
                      },
                      child: Text(
                        context.l10n.save,
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (added != null && mounted) {
      setState(() => _productsUsed.add(added));
    }
  }
}

// ─── Provider: doctors for the current clinic ────────────────
final _courseDoctorsProvider = FutureProvider<List<Staff>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return const [];
  final staffRepo = ref.watch(staffRepoProvider);
  return staffRepo.getDoctors(clinicId);
});
