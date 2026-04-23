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
import '../../core/services/audit_service.dart';
import '../../core/localization/app_localizations.dart';

final _appointmentDoctorsProvider = FutureProvider.family<List<_AppointmentDoctorOption>, DateTime>((ref, date) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return const [];

  final staffRepo = ref.watch(staffRepoProvider);
  final scheduleRepo = ref.watch(scheduleRepoProvider);
  final dateOnly = DateTime(date.year, date.month, date.day);

  final doctors = await staffRepo.getDoctors(clinicId);
  final schedules = await scheduleRepo.getByDate(clinicId: clinicId, date: dateOnly);
  final scheduleByStaffId = <String, StaffSchedule>{
    for (final schedule in schedules) schedule.staffId: schedule,
  };

  final options = doctors
      .map((doctor) => _AppointmentDoctorOption(
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

class _AppointmentDoctorOption {
  final Staff staff;
  final StaffSchedule? schedule;

  const _AppointmentDoctorOption({required this.staff, this.schedule});

  int get sortPriority => switch (schedule?.status) {
        ScheduleStatus.onDuty => 3,
        ScheduleStatus.halfDay => 2,
        ScheduleStatus.leave => 1,
        null => 0,
      };
}

class AppointmentFormScreen extends ConsumerStatefulWidget {
  final String? appointmentId;
  final DateTime? initialDate;

  const AppointmentFormScreen({super.key, this.appointmentId, this.initialDate});

  bool get isEdit => appointmentId != null && appointmentId != 'new';

  @override
  ConsumerState<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends ConsumerState<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  DateTime _date = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay? _endTime;
  AppointmentStatus _status = AppointmentStatus.newAppt;
  String? _selectedPatientId;
  String? _selectedDoctorId;
  String _patientSearch = '';
  bool _doctorSelectionPrimed = false;

  final _treatmentTypeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) _date = widget.initialDate!;
    if (widget.isEdit) _loadExisting();
  }

  @override
  void dispose() {
    _treatmentTypeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final repo = ref.read(appointmentRepoProvider);
    final appt = await repo.get(widget.appointmentId!);
    if (appt == null || !mounted) return;
    setState(() {
      _date = appt.date;
      _startTime = _parseTime(appt.startTime);
      _endTime = appt.endTime != null ? _parseTime(appt.endTime!) : null;
      _status = appt.status;
      _selectedPatientId = appt.patientId;
      _selectedDoctorId = appt.doctorId;
      _doctorSelectionPrimed = appt.doctorId != null && appt.doctorId!.isNotEmpty;
      _treatmentTypeCtrl.text = appt.treatmentType ?? '';
      _notesCtrl.text = appt.notes ?? '';
    });
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectPatient)),
      );
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

    final appt = Appointment(
      id: widget.isEdit ? widget.appointmentId! : const Uuid().v4(),
      clinicId: clinicId,
      patientId: _selectedPatientId!,
      doctorId: _selectedDoctorId,
      date: _date,
      startTime: _formatTime(_startTime),
      endTime: _endTime != null ? _formatTime(_endTime!) : null,
      status: _status,
      treatmentType: _treatmentTypeCtrl.text.trim().isEmpty
          ? null
          : _treatmentTypeCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    try {
      final repo = ref.read(appointmentRepoProvider);
      if (widget.isEdit) {
        await repo.updateAppointment(appt);
      } else {
        await repo.create(appt);
      }
      ref.invalidate(todayAppointmentsProvider);
      ref.invalidate(appointmentsByDateProvider(_date));
      ref.invalidate(todayAppointmentCountProvider);
      ref.invalidate(dashboardStatsProvider);

      // Audit log
      ref.read(auditServiceProvider).log(
        action: widget.isEdit ? 'UPDATE_APPOINTMENT' : 'CREATE_APPOINTMENT',
        entityType: 'appointments',
        entityId: appt.id,
        newData: {'patient_id': appt.patientId, 'doctor_id': appt.doctorId, 'date': appt.date.toIso8601String()},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? context.l10n.appointmentEditSuccess : context.l10n.appointmentSaveSuccess),
            backgroundColor: AiraColors.sage,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saveFailed('$e')), backgroundColor: AiraColors.terra),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _primeDoctorSelection(List<_AppointmentDoctorOption> doctors, Staff? currentStaff) {
    if (_doctorSelectionPrimed || doctors.isEmpty) return;

    _AppointmentDoctorOption? preferred;
    if (currentStaff != null) {
      for (final option in doctors) {
        if (option.staff.id == currentStaff.id) {
          preferred = option;
          break;
        }
      }
    }

    preferred ??= doctors.firstWhere(
      (option) => option.schedule?.status == ScheduleStatus.onDuty,
      orElse: () => doctors.first,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _doctorSelectionPrimed) return;
      setState(() {
        _selectedDoctorId = preferred?.staff.id;
        _doctorSelectionPrimed = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientListProvider);
    final _ = ref.watch(isThaiProvider); // keep provider active for l10n rebuild
    final doctorsAsync = ref.watch(_appointmentDoctorsProvider(_date));
    final currentStaff = ref.watch(currentStaffProvider).valueOrNull;
    final canManageClinicalData = ref.watch(canManageClinicalDataProvider);
    _primeDoctorSelection(doctorsAsync.valueOrNull ?? const [], currentStaff);

    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          AiraPremiumHeader(
            title: widget.isEdit
                ? context.l10n.editAppointment
                : context.l10n.newAppointment,
            subtitle: context.l10n.manageSchedule,
            loading: _loading,
            onBack: () => context.pop(),
            onSave: _loading ? null : _save,
            saveLabel: context.l10n.save,
            steps: premiumSteps([
              (1, context.l10n.patient),
              (2, context.l10n.dateTime),
              (3, context.l10n.status),
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
                      // ─── Patient selection ───
                      AiraSectionHeader(step: 1, icon: Icons.person_rounded, title: context.l10n.patient, subtitle: context.l10n.selectPatientForAppt),
                      _buildPatientSelector(patientsAsync),
                      const SizedBox(height: 28),

                      // ─── Date & Time ───
                      AiraSectionHeader(step: 2, icon: Icons.schedule_rounded, title: context.l10n.dateTime, subtitle: context.l10n.dateTimeSubtitle),
                      _buildDateTimeSection(),
                      const SizedBox(height: 28),

                      // ─── Treatment info ───
                      AiraSectionHeader(step: 0, icon: Icons.medical_services_rounded, title: context.l10n.appointmentInfo, subtitle: context.l10n.appointmentInfoSubtitle),
                      _buildTreatmentSection(doctorsAsync),
                      const SizedBox(height: 28),

                      // ─── Status ───
                      AiraSectionHeader(step: 3, icon: Icons.flag_rounded, title: context.l10n.status, subtitle: context.l10n.selectApptStatus),
                      _buildStatusSection(),
                      const SizedBox(height: 32),

                      AiraPremiumSaveButton(
                        label: _loading
                            ? context.l10n.saving
                            : context.l10n.saveAppointment,
                        loading: _loading,
                        onTap: _save,
                      ),
                      if (widget.isEdit && canManageClinicalData && _selectedPatientId != null) ...[
                        const SizedBox(height: 12),
                        AiraTapEffect(
                          onTap: () => context.push('/patients/${_selectedPatientId!}/treatments/new?appointmentId=${widget.appointmentId}'),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.5)),
                            ),
                            child: Center(
                              child: Text(
                                context.l10n.isThai ? 'เปิดบันทึกการรักษาจากนัดนี้' : 'Open treatment record from this appointment',
                                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.woodDk),
                              ),
                            ),
                          ),
                        ),
                      ],
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
          loading: () => const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
          error: (e, s) => Text('Error: $e'),
          data: (patients) {
            var filtered = patients;
            if (_patientSearch.isNotEmpty) {
              filtered = patients.where((p) =>
                  '${p.firstName} ${p.lastName}'.toLowerCase().contains(_patientSearch) ||
                  (p.nickname?.toLowerCase().contains(_patientSearch) ?? false) ||
                  (p.hn?.toLowerCase().contains(_patientSearch) ?? false) ||
                  (p.phone?.contains(_patientSearch) ?? false)).toList();
            }
            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(context.l10n.patientNotFound, style: GoogleFonts.plusJakartaSans(color: AiraColors.muted)),
              );
            }
            return SizedBox(
              height: 180,
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
                        radius: 18,
                        backgroundColor: selected ? AiraColors.woodDk : AiraColors.woodWash,
                        child: Text(p.firstName.isNotEmpty ? p.firstName[0] : '?', style: TextStyle(color: selected ? Colors.white : AiraColors.woodDk, fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                      title: Text('${p.firstName} ${p.lastName}', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.charcoal)),
                      subtitle: Text(p.hn ?? p.phone ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted)),
                      trailing: selected ? const Icon(Icons.check_circle, color: AiraColors.sage, size: 20) : null,
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

  Widget _buildDateTimeSection() {
    return AiraPremiumCard(
      accentColor: AiraColors.gold,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: AiraTapEffect(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: AbsorbPointer(
              child: TextFormField(
                style: airaFieldTextStyle,
                decoration: airaFieldDecoration(
                  label: 'วันที่',
                  prefixIcon: Icons.calendar_month_rounded,
                  suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16, color: AiraColors.woodMid),
                ),
                controller: TextEditingController(text: DateFormat('dd/MM/yyyy').format(_date)),
              ),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: AiraTapEffect(
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _startTime);
                    if (picked != null) setState(() => _startTime = picked);
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      style: airaFieldTextStyle,
                      decoration: airaFieldDecoration(label: 'เวลาเริ่ม', prefixIcon: Icons.access_time_rounded),
                      controller: TextEditingController(text: _formatTime(_startTime)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: AiraTapEffect(
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: _endTime ?? TimeOfDay(hour: _startTime.hour + 1, minute: _startTime.minute));
                    if (picked != null) setState(() => _endTime = picked);
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      style: airaFieldTextStyle,
                      decoration: airaFieldDecoration(label: 'เวลาสิ้นสุด', prefixIcon: Icons.access_time_rounded),
                      controller: TextEditingController(text: _endTime != null ? _formatTime(_endTime!) : ''),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
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

  Widget _buildTreatmentSection(AsyncValue<List<_AppointmentDoctorOption>> doctorsAsync) {
    return AiraPremiumCard(
      accentColor: AiraColors.woodMid,
      children: [
        TextFormField(
          controller: _treatmentTypeCtrl,
          style: airaFieldTextStyle,
          decoration: airaFieldDecoration(label: 'ประเภทหัตถการ', hint: 'เช่น Botox, Filler, Laser...', prefixIcon: Icons.medical_services_rounded),
        ),
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
              if (doctors.isEmpty) return null;
              if (_selectedDoctorId == null || _selectedDoctorId!.isEmpty) {
                return context.l10n.isThai ? 'กรุณาเลือกแพทย์ผู้รับผิดชอบ' : 'Please select a responsible doctor';
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
        const SizedBox(height: 14),
        TextFormField(
          controller: _notesCtrl,
          maxLines: 3,
          style: airaFieldTextStyle,
          decoration: airaFieldDecoration(label: 'หมายเหตุ', hint: 'รายละเอียดเพิ่มเติม...', prefixIcon: Icons.notes_rounded),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStatusSection() {
    return AiraPremiumCard(
      accentColor: AiraColors.sage,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppointmentStatus.values.map((s) {
            final selected = _status == s;
            final color = _statusColor(s);
            return AiraTapEffect(
              onTap: () => setState(() => _status = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.15) : AiraColors.parchment.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? color : AiraColors.woodPale.withValues(alpha: 0.25),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(
                  _statusLabel(s),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? color : AiraColors.charcoal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  String _statusLabel(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.newAppt: return 'ใหม่';
      case AppointmentStatus.confirmed: return 'ยืนยัน';
      case AppointmentStatus.followUp: return 'ติดตามผล';
      case AppointmentStatus.completed: return 'เสร็จสิ้น';
      case AppointmentStatus.cancelled: return 'ยกเลิก';
      case AppointmentStatus.noShow: return 'ไม่มา';
    }
  }

  Color _statusColor(AppointmentStatus s) {
    switch (s) {
      case AppointmentStatus.newAppt: return AiraColors.woodMid;
      case AppointmentStatus.confirmed: return AiraColors.sage;
      case AppointmentStatus.followUp: return AiraColors.gold;
      case AppointmentStatus.completed: return AiraColors.sage;
      case AppointmentStatus.cancelled: return AiraColors.terra;
      case AppointmentStatus.noShow: return AiraColors.terra;
    }
  }
}
