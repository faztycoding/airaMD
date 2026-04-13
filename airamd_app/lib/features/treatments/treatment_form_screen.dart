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
import '../../core/services/audit_service.dart';
import '../../core/widgets/aira_feedback.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/aira_premium_form.dart';
import '../../core/localization/app_localizations.dart';

final _availableDoctorsProvider = FutureProvider<List<_DoctorOption>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return const [];

  final staffRepo = ref.watch(staffRepoProvider);
  final scheduleRepo = ref.watch(scheduleRepoProvider);
  final today = DateTime.now();
  final dateOnly = DateTime(today.year, today.month, today.day);

  final doctors = await staffRepo.getDoctors(clinicId);
  final schedules = await scheduleRepo.getByDate(clinicId: clinicId, date: dateOnly);
  final scheduleByStaffId = <String, StaffSchedule>{
    for (final schedule in schedules) schedule.staffId: schedule,
  };

  final options = doctors
      .map((doctor) => _DoctorOption(
            staff: doctor,
            schedule: scheduleByStaffId[doctor.id],
          ))
      .toList();

  options.sort((a, b) {
    final availabilityCompare = b.sortPriority.compareTo(a.sortPriority);
    if (availabilityCompare != 0) return availabilityCompare;
    return a.staff.fullName.compareTo(b.staff.fullName);
  });
  return options;
});

final _preferredAppointmentProvider = FutureProvider.family<Appointment?, ({String patientId, String? appointmentId})>((ref, params) async {
  final repo = ref.watch(appointmentRepoProvider);
  final appointmentId = params.appointmentId;
  if (appointmentId != null && appointmentId.isNotEmpty) {
    return repo.get(appointmentId);
  }

  final appointments = await repo.getByPatient(patientId: params.patientId, limit: 20);
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  Appointment? fallback;
  for (final appointment in appointments) {
    if (appointment.doctorId == null || appointment.doctorId!.isEmpty) continue;
    if (appointment.status == AppointmentStatus.cancelled || appointment.status == AppointmentStatus.noShow) {
      continue;
    }

    final appointmentDate = DateTime(appointment.date.year, appointment.date.month, appointment.date.day);
    if (appointmentDate == todayDate) {
      return appointment;
    }
    fallback ??= appointment;
  }
  return fallback;
});

class _DoctorOption {
  final Staff staff;
  final StaffSchedule? schedule;

  const _DoctorOption({required this.staff, this.schedule});

  bool get isOnDuty => schedule?.status == ScheduleStatus.onDuty;

  int get sortPriority => switch (schedule?.status) {
        ScheduleStatus.onDuty => 3,
        ScheduleStatus.halfDay => 2,
        ScheduleStatus.leave => 1,
        null => 0,
      };
}

class TreatmentFormScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String? treatmentId; // null = new
  final TreatmentCategory? initialCategory;
  final String? appointmentId;

  const TreatmentFormScreen({
    super.key,
    required this.patientId,
    this.treatmentId,
    this.initialCategory,
    this.appointmentId,
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
  late TreatmentCategory _category;
  TreatmentResponse _response = TreatmentResponse.notApplicable;
  String? _selectedDoctorId;
  bool _doctorSelectionPrimed = false;

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
    _category = widget.initialCategory ?? TreatmentCategory.injectable;
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
      _selectedDoctorId = record.doctorId;
      _doctorSelectionPrimed = true;
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
              Text(context.l10n.safetyWarning),
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
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.proceedAnyway,
                  style: const TextStyle(color: Colors.white)),
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

    final stockValidationError = await _validateProductUsage();
    if (stockValidationError != null) {
      if (mounted) {
        AiraFeedback.error(context, stockValidationError);
      }
      setState(() => _loading = false);
      return;
    }

    final record = TreatmentRecord(
      id: widget.isEdit ? widget.treatmentId! : const Uuid().v4(),
      clinicId: clinicId,
      patientId: widget.patientId,
      doctorId: _selectedDoctorId,
      appointmentId: widget.appointmentId,
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
      final stockSyncFailures = <String>[];
      final linkedAppointment = widget.appointmentId != null && widget.appointmentId!.isNotEmpty
          ? await ref.read(
              _preferredAppointmentProvider((
                patientId: widget.patientId,
                appointmentId: widget.appointmentId,
              )).future,
            )
          : null;
      if (widget.isEdit) {
        await repo.updateRecord(record);
      } else {
        await repo.create(record);

        if (widget.appointmentId != null && widget.appointmentId!.isNotEmpty) {
          await ref.read(appointmentRepoProvider).updateStatus(
                widget.appointmentId!,
                AppointmentStatus.completed,
              );
        }

        // ─── Auto-deduct stock for products with product_id ───
        final prodRepo = ref.read(productRepoProvider);
        final invRepo = ref.read(inventoryRepoProvider);
        for (final p in _productsUsed) {
          final productId = p['product_id'] as String?;
          final qty = (p['quantity'] as num?)?.toDouble() ?? 0;
          if (productId != null && qty > 0) {
            try {
              await prodRepo.deductStock(productId, qty);
              await invRepo.create(InventoryTransaction(
                id: const Uuid().v4(),
                clinicId: clinicId,
                productId: productId,
                treatmentRecordId: record.id,
                patientId: widget.patientId,
                transactionType: InventoryTransactionType.used,
                quantity: qty,
                unit: p['unit'] as String? ?? 'U',
                notes: 'Auto-deduct: ${record.treatmentName}',
              ));
            } catch (_) {
              stockSyncFailures.add(p['name']?.toString() ?? productId);
            }
          }
        }

        if (mounted && stockSyncFailures.isNotEmpty) {
          AiraFeedback.warning(
            context,
            context.l10n.isThai
                ? 'บันทึกการรักษาสำเร็จ แต่ซิงค์สต็อกไม่ครบ: ${stockSyncFailures.join(', ')}'
                : 'Treatment saved, but stock sync failed for: ${stockSyncFailures.join(', ')}',
          );
        }
      }
      ref.invalidate(treatmentsByPatientProvider(widget.patientId));
      ref.invalidate(todayTreatmentsProvider);
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(productListProvider);
      ref.invalidate(lowStockAlertsProvider);
      ref.invalidate(appointmentsByPatientProvider(widget.patientId));
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(todayAppointmentCountProvider);
      if (linkedAppointment != null) {
        ref.invalidate(
          appointmentsByDateProvider(
            DateTime(
              linkedAppointment.date.year,
              linkedAppointment.date.month,
              linkedAppointment.date.day,
            ),
          ),
        );
      }

      // Audit log
      ref.read(auditServiceProvider).log(
        action: widget.isEdit ? 'UPDATE_TREATMENT' : 'CREATE_TREATMENT',
        entityType: 'treatment_records',
        entityId: record.id,
        newData: {'treatment_name': record.treatmentName, 'patient_id': record.patientId, 'category': record.category.dbValue, 'doctor_id': record.doctorId, 'appointment_id': record.appointmentId},
      );

      if (mounted) {
        AiraFeedback.success(
          context,
          widget.isEdit
              ? (context.l10n.isThai ? 'อัปเดตบันทึกการรักษาเรียบร้อยแล้ว' : 'Treatment record updated successfully')
              : (context.l10n.isThai ? 'บันทึกการรักษาเรียบร้อยแล้ว' : 'Treatment record saved successfully'),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AiraFeedback.error(context, context.l10n.saveFailed('$e'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _ = ref.watch(isThaiProvider); // keep provider active for l10n rebuild
    final doctorsAsync = ref.watch(_availableDoctorsProvider);
    final currentStaff = ref.watch(currentStaffProvider).valueOrNull;
    final preferredAppointment = ref.watch(
      _preferredAppointmentProvider((patientId: widget.patientId, appointmentId: widget.appointmentId)),
    ).valueOrNull;
    final catLabel = _categoryLabel(_category);
    _primeDoctorSelection(doctorsAsync.valueOrNull ?? const [], currentStaff, preferredAppointment);
    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          AiraPremiumHeader(
            title: widget.isEdit
                ? context.l10n.editRecord(catLabel)
                : context.l10n.newRecord(catLabel),
            subtitle: context.l10n.soapSubtitle,
            loading: _loading,
            onBack: () => context.pop(),
            onSave: _loading ? null : _save,
            saveLabel: context.l10n.save,
            steps: premiumSteps([
              (1, context.l10n.info),
              (2, 'SOAP'),
              (3, context.l10n.products),
              (4, context.l10n.results),
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
                        subtitle: 'ชื่อหัตถการ, หมวดหมู่, แพทย์ผู้รับผิดชอบ',
                      ),
                      _buildTreatmentInfoSection(doctorsAsync, preferredAppointment),
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
                                SnackBar(content: Text(context.l10n.specifyTreatmentFirst)),
                              );
                            }
                          },
                        ),
                      if (_safetyChecked)
                        AiraPremiumSaveButton(
                          label: _loading
                              ? context.l10n.saving
                              : context.l10n.saveTreatment,
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

  double? _parseQuantity(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '');
  }

  Future<String?> _validateProductUsage() async {
    final isThai = context.l10n.isThai;
    final products = await ref.read(productListProvider.future);
    final productById = <String, Product>{
      for (final product in products) product.id: product,
    };

    for (final productUsage in _productsUsed) {
      final name = productUsage['name']?.toString() ?? (isThai ? 'สินค้า' : 'Product');
      final quantity = _parseQuantity(productUsage['quantity']) ?? 0;
      if (quantity <= 0) {
        return isThai
            ? 'กรุณาระบุจำนวนที่ใช้ของ $name ให้มากกว่า 0'
            : 'Please enter a quantity greater than 0 for $name';
      }

      final productId = productUsage['product_id'] as String?;
      if (productId == null) continue;

      final product = productById[productId];
      if (product == null) {
        return isThai
            ? 'ไม่พบข้อมูลสินค้า $name ในคลัง'
            : 'Product $name was not found in inventory';
      }

      if (quantity > product.stockQuantity) {
        return isThai
            ? '$name มีสต็อกไม่พอ (${NumberFormat('#,##0.###').format(product.stockQuantity)} ${product.unit} คงเหลือ)'
            : '$name does not have enough stock (${NumberFormat('#,##0.###').format(product.stockQuantity)} ${product.unit} remaining)';
      }
    }

    return null;
  }

  void _primeDoctorSelection(List<_DoctorOption> doctors, Staff? currentStaff, Appointment? preferredAppointment) {
    if (_doctorSelectionPrimed || doctors.isEmpty) return;

    _DoctorOption? preferred;
    final appointmentDoctorId = preferredAppointment?.doctorId;
    if (appointmentDoctorId != null && appointmentDoctorId.isNotEmpty) {
      for (final option in doctors) {
        if (option.staff.id == appointmentDoctorId) {
          preferred = option;
          break;
        }
      }
    }

    preferred ??= doctors.cast<_DoctorOption?>().firstWhere(
          (option) => option?.staff.id == currentStaff?.id,
          orElse: () => doctors.where((option) => option.isOnDuty).cast<_DoctorOption?>().firstWhere(
                (option) => option != null,
                orElse: () => doctors.first,
              ),
        );

    if (preferred == null) return;
    final selectedDoctorId = preferred.staff.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _doctorSelectionPrimed) return;
      setState(() {
        _selectedDoctorId = selectedDoctorId;
        _doctorSelectionPrimed = true;
      });
    });
  }

  String _doctorStatusLabel(ScheduleStatus? status) {
    switch (status) {
      case ScheduleStatus.onDuty:
        return context.l10n.onDuty;
      case ScheduleStatus.leave:
        return context.l10n.leave;
      case ScheduleStatus.halfDay:
        return context.l10n.halfDay;
      case null:
        return context.l10n.noSchedule;
    }
  }

  Widget _buildTreatmentInfoSection(AsyncValue<List<_DoctorOption>> doctorsAsync, Appointment? preferredAppointment) {
    final preferredAppointmentDate = preferredAppointment?.date;
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
        if ((preferredAppointment?.doctorId ?? '').isNotEmpty && preferredAppointmentDate != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AiraColors.sage.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AiraColors.sage.withValues(alpha: 0.2)),
            ),
            child: Text(
              context.l10n.isThai
                  ? 'อ้างอิงแพทย์จากนัดหมายวันที่ ${DateFormat('d/M/y').format(preferredAppointmentDate)}'
                  : 'Doctor suggested from appointment on ${DateFormat('d/M/y').format(preferredAppointmentDate)}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.sage),
            ),
          ),
        ],
        const SizedBox(height: 14),
        doctorsAsync.when(
          data: (doctors) => DropdownButtonFormField<String>(
            value: doctors.any((option) => option.staff.id == _selectedDoctorId)
                ? _selectedDoctorId
                : null,
            style: airaFieldTextStyle,
            decoration: airaFieldDecoration(
              label: context.l10n.responsibleDoctor,
              hint: context.l10n.doctorHint,
              prefixIcon: Icons.person_rounded,
            ),
            items: doctors
                .map(
                  (option) => DropdownMenuItem(
                    value: option.staff.id,
                    child: Text(
                      '${option.staff.fullName} • ${_doctorStatusLabel(option.schedule?.status)}',
                      style: airaFieldTextStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: doctors.isEmpty
                ? null
                : (value) {
                    setState(() {
                      _selectedDoctorId = value;
                      _doctorSelectionPrimed = true;
                    });
                  },
            validator: (_) {
              if (doctors.isEmpty) {
                return 'ยังไม่มีข้อมูลแพทย์ในระบบ';
              }
              if (_selectedDoctorId == null || _selectedDoctorId!.isEmpty) {
                return 'กรุณาเลือกแพทย์ผู้รับผิดชอบ';
              }
              return null;
            },
          ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
          ),
          error: (e, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AiraColors.terra.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AiraColors.terra.withValues(alpha: 0.2)),
            ),
            child: Text(
              'โหลดรายชื่อแพทย์ไม่สำเร็จ: $e',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.terra),
            ),
          ),
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
        _premiumField('จำนวนหน่วยรวมที่ใช้ (Units)', _unitsUsedCtrl, hint: 'เช่น 20 หรือ 2.5', icon: Icons.straighten_rounded, keyboard: const TextInputType.numberWithOptions(decimal: true)),
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
                Text(context.l10n.addProduct, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.woodMid)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddProductDialog() async {
    final products = await ref.read(productListProvider.future);
    if (!mounted) return;

    Product? selectedProduct;
    final qtyCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'U');
    bool manualMode = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(context.l10n.addProduct, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!manualMode && products.isNotEmpty) ...[
                  Text(context.l10n.selectFromLibrary, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Product>(
                    value: selectedProduct,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal),
                    decoration: InputDecoration(
                      hintText: 'เลือกผลิตภัณฑ์...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: AiraColors.muted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: products.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text('${p.name} (สต็อก: ${NumberFormat('#,##0.###').format(p.stockQuantity)} ${p.unit})', overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (v) {
                      setDlgState(() {
                        selectedProduct = v;
                        if (v != null) unitCtrl.text = v.unit;
                      });
                    },
                  ),
                  if (selectedProduct?.stockPerContainer != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.isThai
                          ? '1 ขวด/กล่อง = ${NumberFormat('#,##0.###').format(selectedProduct!.stockPerContainer)} ${selectedProduct!.unit}'
                          : '1 container = ${NumberFormat('#,##0.###').format(selectedProduct!.stockPerContainer)} ${selectedProduct!.unit}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted),
                    ),
                  ],
                  const SizedBox(height: 8),
                  AiraTapEffect(
                    onTap: () => setDlgState(() => manualMode = true),
                    child: Text(context.l10n.orTypeManually, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.woodMid, decoration: TextDecoration.underline)),
                  ),
                ] else ...[
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'ชื่อผลิตภัณฑ์',
                      hintText: 'เช่น Botulinum Toxin Type A',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  if (products.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    AiraTapEffect(
                      onTap: () => setDlgState(() => manualMode = false),
                      child: Text(context.l10n.selectProduct, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.woodMid, decoration: TextDecoration.underline)),
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        decoration: InputDecoration(labelText: 'จำนวน', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        decoration: InputDecoration(labelText: 'หน่วย', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel, style: GoogleFonts.plusJakartaSans(color: AiraColors.muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AiraColors.woodMid, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                final name = selectedProduct?.name ?? nameCtrl.text.trim();
                final quantity = double.tryParse(qtyCtrl.text.trim()) ?? 0;
                if (name.isEmpty || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.isThai
                            ? 'กรุณาเลือกสินค้าและระบุจำนวนที่มากกว่า 0'
                            : 'Please choose a product and enter a quantity greater than 0',
                      ),
                      backgroundColor: AiraColors.terra,
                    ),
                  );
                  return;
                }
                if (selectedProduct != null && quantity > selectedProduct!.stockQuantity) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.isThai
                            ? 'สต็อกของ ${selectedProduct!.name} ไม่พอ'
                            : 'Not enough stock for ${selectedProduct!.name}',
                      ),
                      backgroundColor: AiraColors.terra,
                    ),
                  );
                  return;
                }
                setState(() {
                  _productsUsed.add({
                    'name': name,
                    'quantity': quantity,
                    'unit': unitCtrl.text.trim(),
                    if (selectedProduct != null) 'product_id': selectedProduct!.id,
                  });
                  _safetyChecked = false;
                });
                Navigator.pop(ctx);
              },
              child: Text(context.l10n.add, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
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
