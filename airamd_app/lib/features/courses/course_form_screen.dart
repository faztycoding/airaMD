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

class CourseFormScreen extends ConsumerStatefulWidget {
  final String? courseId;
  final String? initialPatientId;

  const CourseFormScreen({super.key, this.courseId, this.initialPatientId});

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

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.initialPatientId;
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

    final course = Course(
      id: widget.isEdit ? widget.courseId! : const Uuid().v4(),
      clinicId: clinicId,
      patientId: _selectedPatientId!,
      name: _nameCtrl.text.trim(),
      price: double.tryParse(_priceCtrl.text.trim()),
      sessionsBought: int.tryParse(_sessionsBoughtCtrl.text.trim()) ?? 1,
      sessionsBonus: int.tryParse(_sessionsBonusCtrl.text.trim()) ?? 0,
      status: _status,
      expiryDate: _expiryDate,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
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
              (2, context.l10n.course),
              (3, context.l10n.sessions),
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

                      // ─── Course info ───
                      AiraSectionHeader(step: 2, icon: Icons.card_membership_rounded, title: context.l10n.course, subtitle: context.l10n.courseManagementSubtitle),
                      AiraPremiumCard(accentColor: AiraColors.woodMid, children: [
                        TextFormField(
                          controller: _nameCtrl,
                          style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(label: 'ชื่อคอร์ส *', hint: 'เช่น Botox Forehead x10', prefixIcon: Icons.card_membership_rounded),
                          validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อคอร์ส' : null,
                        ),
                        const SizedBox(height: 14),
                        // Per-course total price (saved to DB).
                        TextFormField(
                          controller: _priceCtrl,
                          style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(
                            label: '${context.l10n.pricePerCourse} (฿) *',
                            hint: 'เช่น 15000',
                            prefixIcon: Icons.payments_rounded,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        // Read-only computed price-per-session for instant
                        // visibility while pricing the course. Updates as
                        // either the price or session counts change.
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
                        const SizedBox(height: 8),
                      ]),
                      const SizedBox(height: 28),

                      // ─── Treatment Details + Products (รวมเป็นกลุ่มเดียว) ───
                      // Per client feedback (May 17): they want product
                      // picker INSIDE the course form, grouped under the
                      // treatment category. Selecting "Injectable" shows
                      // injectables; "Laser" shows devices; "Treatment"
                      // shows treatment products.
                      AiraSectionHeader(
                        step: 0,
                        icon: Icons.medical_services_rounded,
                        title: context.l10n.treatmentDetails,
                        subtitle: context.l10n.isThai
                            ? 'ประเภท, แพทย์, ผลิตภัณฑ์ที่ใช้ในคอร์ส'
                            : 'Category, doctor and products used per session',
                      ),
                      AiraPremiumCard(accentColor: AiraColors.terra, children: [
                        DropdownButtonFormField<TreatmentCategory>(
                          value: _treatmentCategory,
                          isExpanded: true,
                          style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(
                            label: context.l10n.treatmentCategory,
                            prefixIcon: Icons.category_rounded,
                          ),
                          items: TreatmentCategory.values
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    _treatmentCategoryLabel(c),
                                    style: airaFieldTextStyle,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _treatmentCategory = v);
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildDoctorDropdown(),
                        const SizedBox(height: 14),
                        _buildProductsPicker(),
                        const SizedBox(height: 8),
                      ]),
                      const SizedBox(height: 28),

                      // ─── Sessions ───
                      const AiraSectionHeader(step: 3, icon: Icons.confirmation_number_rounded, title: 'จำนวนเซสชั่น', subtitle: 'ซื้อ + แถม'),
                      AiraPremiumCard(accentColor: AiraColors.sage, children: [
                        Row(children: [
                          Expanded(child: TextFormField(
                            controller: _sessionsBoughtCtrl,
                            style: airaFieldTextStyle,
                            decoration: airaFieldDecoration(label: 'ซื้อ (ครั้ง)', prefixIcon: Icons.shopping_bag_rounded),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          )),
                          const SizedBox(width: 14),
                          Expanded(child: TextFormField(
                            controller: _sessionsBonusCtrl,
                            style: airaFieldTextStyle,
                            decoration: airaFieldDecoration(label: 'แถม (ครั้ง)', prefixIcon: Icons.card_giftcard_rounded),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          )),
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
                              Icon(Icons.summarize_rounded, size: 16, color: AiraColors.sage),
                              const SizedBox(width: 8),
                              Text(context.l10n.totalSessions(bought, bonus), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.sage)),
                            ]),
                          );
                        }),
                        const SizedBox(height: 8),
                      ]),
                      const SizedBox(height: 28),

                      // ─── Expiry ───
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
