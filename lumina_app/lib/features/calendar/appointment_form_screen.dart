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
  String _patientSearch = '';

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
        const SnackBar(content: Text('กรุณาเลือกผู้รับบริการ')),
      );
      return;
    }

    setState(() => _loading = true);
    final clinicId = ref.read(currentClinicIdProvider);
    if (clinicId == null) {
      setState(() => _loading = false);
      return;
    }

    final appt = Appointment(
      id: widget.isEdit ? widget.appointmentId! : const Uuid().v4(),
      clinicId: clinicId,
      patientId: _selectedPatientId!,
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
        newData: {'patient_id': appt.patientId, 'date': appt.date.toIso8601String()},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? 'แก้ไขนัดหมายสำเร็จ' : 'สร้างนัดหมายสำเร็จ'),
            backgroundColor: AiraColors.sage,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e'), backgroundColor: AiraColors.terra),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientListProvider);
    final isThai = ref.watch(isThaiProvider);

    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          AiraPremiumHeader(
            title: widget.isEdit
                ? (isThai ? 'แก้ไขนัดหมาย' : 'Edit Appointment')
                : (isThai ? 'นัดหมายใหม่' : 'New Appointment'),
            subtitle: isThai ? 'จัดการตารางนัดหมาย' : 'Manage appointment schedule',
            loading: _loading,
            onBack: () => context.pop(),
            onSave: _loading ? null : _save,
            saveLabel: isThai ? 'บันทึก' : 'Save',
            steps: premiumSteps([
              (1, isThai ? 'ผู้รับบริการ' : 'Patient'),
              (2, isThai ? 'วัน-เวลา' : 'DateTime'),
              (3, isThai ? 'สถานะ' : 'Status'),
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
                      const AiraSectionHeader(step: 1, icon: Icons.person_rounded, title: 'ผู้รับบริการ', subtitle: 'เลือกผู้รับบริการสำหรับนัดหมาย'),
                      _buildPatientSelector(patientsAsync),
                      const SizedBox(height: 28),

                      // ─── Date & Time ───
                      const AiraSectionHeader(step: 2, icon: Icons.schedule_rounded, title: 'วัน-เวลา', subtitle: 'วันที่, เวลาเริ่ม, เวลาสิ้นสุด'),
                      _buildDateTimeSection(),
                      const SizedBox(height: 28),

                      // ─── Treatment info ───
                      const AiraSectionHeader(step: 0, icon: Icons.medical_services_rounded, title: 'ข้อมูลนัดหมาย', subtitle: 'ประเภทหัตถการ, หมายเหตุ'),
                      _buildTreatmentSection(),
                      const SizedBox(height: 28),

                      // ─── Status ───
                      const AiraSectionHeader(step: 3, icon: Icons.flag_rounded, title: 'สถานะ', subtitle: 'เลือกสถานะนัดหมาย'),
                      _buildStatusSection(),
                      const SizedBox(height: 32),

                      AiraPremiumSaveButton(
                        label: _loading
                            ? (isThai ? 'กำลังบันทึก...' : 'Saving...')
                            : (isThai ? 'บันทึกนัดหมาย' : 'Save Appointment'),
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
                child: Text('ไม่พบผู้รับบริการ', style: GoogleFonts.plusJakartaSans(color: AiraColors.muted)),
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

  Widget _buildTreatmentSection() {
    return AiraPremiumCard(
      accentColor: AiraColors.woodMid,
      children: [
        TextFormField(
          controller: _treatmentTypeCtrl,
          style: airaFieldTextStyle,
          decoration: airaFieldDecoration(label: 'ประเภทหัตถการ', hint: 'เช่น Botox, Filler, Laser...', prefixIcon: Icons.medical_services_rounded),
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
