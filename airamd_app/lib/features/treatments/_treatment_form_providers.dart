part of 'treatment_form_screen.dart';

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
