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
                        TextFormField(
                          controller: _priceCtrl,
                          style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(label: 'ราคา (฿)', hint: 'เช่น 15000', prefixIcon: Icons.payments_rounded),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                      ]),
                      const SizedBox(height: 28),

                      // ─── Treatment Details ───
                      AiraSectionHeader(step: 0, icon: Icons.medical_services_rounded, title: context.l10n.treatmentDetails, subtitle: context.l10n.treatmentDetailsSubtitle),
                      AiraPremiumCard(accentColor: AiraColors.terra, children: [
                        DropdownButtonFormField<String>(
                          style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(label: context.l10n.treatmentCategory, prefixIcon: Icons.category_rounded),
                          items: [
                            DropdownMenuItem(value: 'laser', child: Text('Laser', style: airaFieldTextStyle)),
                            DropdownMenuItem(value: 'injectable', child: Text('Injectable', style: airaFieldTextStyle)),
                            DropdownMenuItem(value: 'treatment', child: Text('Treatment', style: airaFieldTextStyle)),
                            DropdownMenuItem(value: 'anti_aging', child: Text('Anti-aging', style: airaFieldTextStyle)),
                            DropdownMenuItem(value: 'skincare', child: Text('Skincare', style: airaFieldTextStyle)),
                            DropdownMenuItem(value: 'other', child: Text(context.l10n.other, style: airaFieldTextStyle)),
                          ],
                          onChanged: (_) {},
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(label: context.l10n.responsibleDoctor, hint: context.l10n.doctorHint, prefixIcon: Icons.person_rounded),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(label: context.l10n.treatmentArea, hint: context.l10n.areaHint, prefixIcon: Icons.face_rounded),
                        ),
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
                          )),
                          const SizedBox(width: 14),
                          Expanded(child: TextFormField(
                            controller: _sessionsBonusCtrl,
                            style: airaFieldTextStyle,
                            decoration: airaFieldDecoration(label: 'แถม (ครั้ง)', prefixIcon: Icons.card_giftcard_rounded),
                            keyboardType: TextInputType.number,
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
}
