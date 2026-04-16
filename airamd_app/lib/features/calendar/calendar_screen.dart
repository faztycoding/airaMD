import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/localization/app_localizations.dart';

/// Shared state: currently selected date on calendar.
final _selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// Appointments for the visible month range.
final _monthAppointmentsProvider =
    FutureProvider.family<List<Appointment>, ({DateTime start, DateTime end})>(
        (ref, range) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(appointmentRepoProvider);
  return repo.getByDateRange(clinicId: clinicId, from: range.start, to: range.end);
});

final _staffRosterProvider = FutureProvider.family<List<_StaffRosterEntry>, DateTime>((ref, date) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final staffRepo = ref.watch(staffRepoProvider);
  final scheduleRepo = ref.watch(scheduleRepoProvider);
  final activeStaff = await staffRepo.list(clinicId: clinicId, activeOnly: true);
  final schedules = await scheduleRepo.getByDate(clinicId: clinicId, date: DateTime(date.year, date.month, date.day));
  final scheduleByStaffId = <String, StaffSchedule>{
    for (final schedule in schedules) schedule.staffId: schedule,
  };
  final entries = activeStaff
      .map((staff) => _StaffRosterEntry(staff: staff, schedule: scheduleByStaffId[staff.id]))
      .toList();
  entries.sort((a, b) {
    final orderCompare = a.sortOrder.compareTo(b.sortOrder);
    if (orderCompare != 0) return orderCompare;
    return a.staff.fullName.compareTo(b.staff.fullName);
  });
  return entries;
});

final _calendarDoctorProvider = FutureProvider.family<Staff?, String>((ref, staffId) async {
  final repo = ref.watch(staffRepoProvider);
  return repo.get(staffId);
});

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  DateTime get _rangeStart =>
      DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
  DateTime get _rangeEnd =>
      DateTime(_focusedDay.year, _focusedDay.month + 2, 0);

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(_selectedDateProvider);
    final isThai = context.l10n.isThai;
    final locale = isThai ? 'th' : 'en';
    final staffRosterAsync = ref.watch(_staffRosterProvider(DateTime(selectedDate.year, selectedDate.month, selectedDate.day)));
    final monthApptsAsync = ref.watch(
      _monthAppointmentsProvider((start: _rangeStart, end: _rangeEnd)),
    );
    final dayApptsAsync = ref.watch(appointmentsByDateProvider(selectedDate));

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final maxCalendarWidth = isWide ? 480.0 : 420.0;

          return Column(
            children: [
              // ─── Top header bar ───
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 1060.0 : 860.0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                  children: [
                    // Title with accent bar
                    Container(
                      width: 4, height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B6650), Color(0xFFB8957A)],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.l10n.calendarTitle,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26, fontWeight: FontWeight.w700, color: AiraColors.charcoal,
                      ),
                    ),
                    const Spacer(),
                    // TH/EN Toggle
                    _LanguageToggle(isThai: isThai, onToggle: (val) {
                      ref.read(localeProvider.notifier).state =
                          val ? const Locale('th', 'TH') : const Locale('en', 'US');
                    }),
                  ],
                ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ─── Body ───
              Expanded(
                child: _buildVerticalLayout(selectedDate, monthApptsAsync, dayApptsAsync, staffRosterAsync, maxCalendarWidth, locale, isThai, isWide),
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Vertical layout — calendar on top, details below
  // Wide: detail + roster side by side | Narrow: stacked
  // ══════════════════════════════════════════════════════════════
  Widget _buildVerticalLayout(
    DateTime selectedDate,
    AsyncValue<List<Appointment>> monthApptsAsync,
    AsyncValue<List<Appointment>> dayApptsAsync,
    AsyncValue<List<_StaffRosterEntry>> staffRosterAsync,
    double maxCalendarWidth,
    String locale,
    bool isThai,
    bool isWide,
  ) {
    final maxW = isWide ? 1060.0 : 860.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 0, isWide ? 24 : 16, 0),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: Column(
            children: [
              // ─── Calendar card — centered, constrained ───
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxCalendarWidth),
                  child: _buildCalendarCard(selectedDate, monthApptsAsync, locale, isThai),
                ),
              ),
              const SizedBox(height: 16),
              // ─── Quick actions — same width as calendar ───
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxCalendarWidth),
                  child: _buildQuickActions(selectedDate, isThai),
                ),
              ),
              const SizedBox(height: 20),
              // ─── Detail section ───
              if (isWide)
                // Wide: day detail + staff roster side by side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildDayDetailCard(selectedDate, dayApptsAsync, locale, isThai),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: _buildStaffRosterCard(selectedDate, staffRosterAsync, isThai),
                    ),
                  ],
                )
              else ...[
                // Narrow: stacked
                _buildDayDetailCard(selectedDate, dayApptsAsync, locale, isThai),
                const SizedBox(height: 16),
                _buildStaffRosterCard(selectedDate, staffRosterAsync, isThai),
              ],
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Calendar Card — Google Calendar style, centered, big text
  // ══════════════════════════════════════════════════════════════
  Widget _buildCalendarCard(
    DateTime selectedDate,
    AsyncValue<List<Appointment>> monthApptsAsync,
    String locale,
    bool isThai,
  ) {
    // Build event map for markers
    final events = <DateTime, List<Appointment>>{};
    monthApptsAsync.whenData((appts) {
      for (final a in appts) {
        final day = DateTime(a.date.year, a.date.month, a.date.day);
        events.putIfAbsent(day, () => []).add(a);
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AiraColors.woodDk.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AiraColors.woodDk.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ─── Custom month header ───
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MonthNavButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                    });
                  },
                ),
                AiraTapEffect(
                  onTap: () {
                    setState(() => _focusedDay = DateTime.now());
                    ref.read(_selectedDateProvider.notifier).state = DateTime.now();
                  },
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMMM', locale).format(_focusedDay).toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AiraColors.woodMid,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isThai
                            ? '${_focusedDay.year + 543}'
                            : '${_focusedDay.year}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AiraColors.charcoal,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                _MonthNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: () {
                    setState(() {
                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
          ),

          // ─── Divider ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: AiraColors.creamDk.withValues(alpha: 0.5), height: 1),
          ),

          // ─── Table Calendar (no built-in header) ───
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: TableCalendar<Appointment>(
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime(2035, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(selectedDate, day),
              onDaySelected: (selected, focused) {
                ref.read(_selectedDateProvider.notifier).state = selected;
                setState(() => _focusedDay = focused);
              },
              onFormatChanged: (format) => setState(() => _calendarFormat = format),
              onPageChanged: (focused) {
                setState(() => _focusedDay = focused);
              },
              eventLoader: (day) {
                final key = DateTime(day.year, day.month, day.day);
                return events[key] ?? [];
              },
              locale: isThai ? 'th_TH' : 'en_US',
              startingDayOfWeek: StartingDayOfWeek.sunday,
              headerVisible: false,
              daysOfWeekHeight: 44,
              rowHeight: 52,
              daysOfWeekStyle: DaysOfWeekStyle(
                dowTextFormatter: (date, locale) {
                  final fmt = DateFormat.E(locale).format(date);
                  return fmt.substring(0, isThai ? fmt.length.clamp(0, 2) : 3);
                },
                weekdayStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AiraColors.muted,
                ),
                weekendStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AiraColors.terra.withValues(alpha: 0.5),
                ),
              ),
              calendarStyle: CalendarStyle(
                cellMargin: const EdgeInsets.all(4),
                // Today — soft warm circle
                todayDecoration: BoxDecoration(
                  color: AiraColors.woodMid.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AiraColors.woodDk,
                ),
                // Selected — solid warm circle
                selectedDecoration: const BoxDecoration(
                  color: AiraColors.woodDk,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                // Default
                defaultTextStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AiraColors.charcoal,
                ),
                // Weekend
                weekendTextStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AiraColors.terra.withValues(alpha: 0.6),
                ),
                // Outside month
                outsideTextStyle: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AiraColors.muted.withValues(alpha: 0.35),
                ),
                // Event markers
                markerDecoration: const BoxDecoration(
                  color: AiraColors.sage,
                  shape: BoxShape.circle,
                ),
                markerSize: 6,
                markersMaxCount: 3,
                markerMargin: const EdgeInsets.only(top: 1),
              ),
              calendarBuilders: CalendarBuilders(
                // Custom "today + selected" builder for polish
                todayBuilder: (context, day, focused) {
                  final isSelected = isSameDay(ref.read(_selectedDateProvider), day);
                  if (isSelected) return null; // let selectedBuilder handle
                  return Center(
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AiraColors.woodMid.withValues(alpha: 0.13),
                        shape: BoxShape.circle,
                        border: Border.all(color: AiraColors.woodMid.withValues(alpha: 0.3), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AiraColors.woodDk,
                        ),
                      ),
                    ),
                  );
                },
                selectedBuilder: (context, day, focused) {
                  final isToday = isSameDay(day, DateTime.now());
                  return Center(
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        gradient: AiraColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AiraColors.woodDk.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${day.day}',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
                            ),
                          ),
                          if (isToday)
                            Container(
                              width: 4, height: 4, margin: const EdgeInsets.only(top: 1),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  final isSelected = isSameDay(ref.read(_selectedDateProvider), day);
                  return Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        events.length.clamp(0, 3),
                        (i) => Container(
                          width: 5, height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withValues(alpha: 0.8) : AiraColors.sage,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Quick Action Buttons (Today + New Appointment)
  // ══════════════════════════════════════════════════════════════
  Widget _buildQuickActions(DateTime selectedDate, bool isThai) {
    return Row(
      children: [
        // Today button
        Expanded(
          child: AiraTapEffect(
            onTap: () {
              setState(() => _focusedDay = DateTime.now());
              ref.read(_selectedDateProvider.notifier).state = DateTime.now();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AiraColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AiraColors.woodDk.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.today_rounded, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.today,
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // New appointment button
        Expanded(
          child: AiraTapEffect(
            onTap: () => context.push('/appointments/new?date=${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AiraColors.woodPale, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AiraColors.woodDk.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 20, color: AiraColors.woodDk),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.newAppointment,
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.woodDk),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Day Detail Card — appointments list for selected day
  // ══════════════════════════════════════════════════════════════
  Widget _buildDayDetailCard(
    DateTime selectedDate,
    AsyncValue<List<Appointment>> dayApptsAsync,
    String locale,
    bool isThai,
  ) {
    final dateStr = isThai
        ? '${DateFormat('d MMMM', 'th').format(selectedDate)} ${selectedDate.year + 543}'
        : DateFormat('MMMM d, yyyy', 'en').format(selectedDate);
    final dayName = DateFormat('EEEE', locale).format(selectedDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AiraColors.woodDk.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Detail header ───
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AiraColors.parchment, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                // Date circle
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    gradient: AiraColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AiraColors.woodDk.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${selectedDate.day}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.w700, color: AiraColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted),
                      ),
                    ],
                  ),
                ),
                dayApptsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                  data: (appts) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: appts.isEmpty
                          ? AiraColors.muted.withValues(alpha: 0.1)
                          : AiraColors.sage.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.l10n.apptCount(appts.length),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: appts.isEmpty ? AiraColors.muted : AiraColors.sage,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ─── Appointments list ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: dayApptsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
              ),
              error: (e, s) => Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    '${context.l10n.error}: $e',
                    style: TextStyle(color: AiraColors.terra, fontSize: 15),
                  ),
                ),
              ),
              data: (appts) {
                if (appts.isEmpty) {
                  return SizedBox(
                    width: double.infinity,
                    child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: AiraColors.cream,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.event_available_rounded, size: 32, color: AiraColors.muted.withValues(alpha: 0.4)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.noAppointmentsToday,
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AiraColors.muted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.tapNewAppt,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 16),
                        AiraTapEffect(
                          onTap: () => context.push('/appointments/new?date=${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: AiraColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AiraColors.woodDk.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  context.l10n.addAppointment,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    ),
                  );
                }
                return Column(
                  children: appts.asMap().entries.map((entry) {
                    final i = entry.key;
                    final appt = entry.value;
                    final isLast = i == appts.length - 1;
                    return _AppointmentTimelineRow(appt: appt, isLast: isLast, isThai: isThai);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffRosterCard(
    DateTime selectedDate,
    AsyncValue<List<_StaffRosterEntry>> staffRosterAsync,
    bool isThai,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AiraColors.woodDk.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: staffRosterAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
          ),
          error: (e, s) => Center(
            child: Text(
              context.l10n.failedLoadRoster,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.terra),
            ),
          ),
          data: (entries) {
            final onDutyCount = entries.where((entry) => entry.status == ScheduleStatus.onDuty).length;
            final leaveCount = entries.where((entry) => entry.status == ScheduleStatus.leave).length;
            final halfDayCount = entries.where((entry) => entry.status == ScheduleStatus.halfDay).length;
            return Column(
              crossAxisAlignment: entries.isEmpty ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AiraColors.sage.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.badge_rounded, color: AiraColors.sage),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.staffRoster,
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.staffStatusForDate(DateFormat(context.l10n.isThai ? 'd/M/y' : 'MMM d, y', context.l10n.isThai ? 'th' : 'en').format(selectedDate)),
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RosterStatChip(label: context.l10n.onDutyCount(onDutyCount), color: AiraColors.sage),
                      _RosterStatChip(label: context.l10n.leaveCount(leaveCount), color: AiraColors.terra),
                      _RosterStatChip(label: context.l10n.halfDayCount(halfDayCount), color: AiraColors.gold),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (entries.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Icon(Icons.people_outline_rounded, size: 36, color: AiraColors.muted.withValues(alpha: 0.3)),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.noStaffFound,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ...entries.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => _showScheduleSheet(context, e.value, selectedDate),
                        child: _RosterRow(entry: e.value, doctorIndex: e.key),
                      ),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Schedule Management Bottom Sheet ──────────────────────
  void _showScheduleSheet(
    BuildContext ctx,
    _StaffRosterEntry entry,
    DateTime date,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleSheet(
        entry: entry,
        date: date,
        onSaved: () {
          // Invalidate roster to refresh
          ref.invalidate(_staffRosterProvider);
        },
      ),
    );
  }
}

class _StaffRosterEntry {
  final Staff staff;
  final StaffSchedule? schedule;
  const _StaffRosterEntry({required this.staff, required this.schedule});

  ScheduleStatus? get status => schedule?.status;

  int get sortOrder {
    switch (status) {
      case ScheduleStatus.onDuty:
        return 0;
      case ScheduleStatus.halfDay:
        return 1;
      case ScheduleStatus.leave:
        return 2;
      case null:
        return 3;
    }
  }
}

class _RosterStatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _RosterStatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// Doctor-specific color palette for easy visual identification
const _doctorColors = [
  Color(0xFF4A90D9), // ฟ้า (Blue)
  Color(0xFFE06B8F), // ชมพู (Pink)
  Color(0xFF7A9070), // เขียว (Green / sage)
  Color(0xFFC4922A), // ทอง (Gold)
  Color(0xFF9B59B6), // ม่วง (Purple)
  Color(0xFFE67E22), // ส้ม (Orange)
  Color(0xFF2ECC71), // เขียวสด (Emerald)
  Color(0xFF1ABC9C), // เทอร์ควอยซ์ (Teal)
];

Color _doctorColor(int index) => _doctorColors[index % _doctorColors.length];

class _RosterRow extends StatelessWidget {
  final _StaffRosterEntry entry;
  final int doctorIndex;
  const _RosterRow({required this.entry, this.doctorIndex = 0});

  @override
  Widget build(BuildContext context) {
    final status = entry.status;
    // Use doctor-specific color for the avatar & left accent
    final personalColor = _doctorColor(doctorIndex);
    final statusColor = switch (status) {
      ScheduleStatus.onDuty => AiraColors.sage,
      ScheduleStatus.leave => AiraColors.terra,
      ScheduleStatus.halfDay => AiraColors.gold,
      null => AiraColors.muted,
    };
    final statusLabel = switch (status) {
      ScheduleStatus.onDuty => context.l10n.onDuty,
      ScheduleStatus.leave => context.l10n.leave,
      ScheduleStatus.halfDay => context.l10n.halfDay,
      null => context.l10n.noSchedule,
    };
    final roleLabel = switch (entry.staff.role) {
      StaffRole.owner => context.l10n.ownerRole,
      StaffRole.doctor => context.l10n.doctorRole,
      StaffRole.receptionist => context.l10n.staffRole,
    };
    final timeLabel = entry.schedule == null
        ? context.l10n.noShiftTime
        : '${entry.schedule?.startTime ?? '--:--'} - ${entry.schedule?.endTime ?? '--:--'}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AiraColors.parchment,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: personalColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // Left color accent bar
          Container(
            width: 4,
            height: 48,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: personalColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: personalColor.withValues(alpha: 0.14),
            child: Text(
              entry.staff.fullName.isEmpty ? '?' : entry.staff.fullName.characters.first,
              style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: personalColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.staff.fullName,
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: personalColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$roleLabel • $timeLabel',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
                ),
                if (entry.schedule?.note != null && entry.schedule!.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    entry.schedule!.note!,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Schedule Management Bottom Sheet
// ═══════════════════════════════════════════════════════════════
class _ScheduleSheet extends ConsumerStatefulWidget {
  final _StaffRosterEntry entry;
  final DateTime date;
  final VoidCallback onSaved;

  const _ScheduleSheet({
    required this.entry,
    required this.date,
    required this.onSaved,
  });

  @override
  ConsumerState<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends ConsumerState<_ScheduleSheet> {
  late ScheduleStatus _status;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.entry.schedule;
    _status = s?.status ?? ScheduleStatus.onDuty;
    _startTime = _parseTime(s?.startTime);
    _endTime = _parseTime(s?.endTime);
    _noteController.text = s?.note ?? '';
  }

  TimeOfDay? _parseTime(String? t) {
    if (t == null || t.isEmpty) return null;
    final parts = t.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
  }

  String? _formatTime(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final scheduleRepo = ref.read(scheduleRepoProvider);
      final existing = widget.entry.schedule;

      if (existing != null) {
        await scheduleRepo.updateSchedule(StaffSchedule(
          id: existing.id,
          clinicId: existing.clinicId,
          staffId: existing.staffId,
          date: widget.date,
          status: _status,
          startTime: _formatTime(_startTime),
          endTime: _formatTime(_endTime),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        ));
      } else {
        final clinicId = ref.read(currentClinicIdProvider);
        if (clinicId == null) return;
        await scheduleRepo.create(StaffSchedule(
          id: '', // auto-generated
          clinicId: clinicId,
          staffId: widget.entry.staff.id,
          date: widget.date,
          status: _status,
          startTime: _formatTime(_startTime),
          endTime: _formatTime(_endTime),
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        ));
      }
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.shiftSaved),
            backgroundColor: AiraColors.sage,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AiraColors.terra),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.entry.schedule;
    if (existing == null) return;
    setState(() => _saving = true);
    try {
      final scheduleRepo = ref.read(scheduleRepoProvider);
      await scheduleRepo.deleteSchedule(existing.id);
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.shiftDeleted),
            backgroundColor: AiraColors.terra,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AiraColors.terra),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = (isStart ? _startTime : _endTime) ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: AiraColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AiraColors.woodPale,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Text(
              l10n.manageShiftFor(widget.entry.staff.fullName),
              style: AiraFonts.heading(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Status selector
            Text(l10n.shiftStatus, style: AiraFonts.label()),
            const SizedBox(height: 8),
            Row(
              children: ScheduleStatus.values.map((s) {
                final selected = s == _status;
                final color = switch (s) {
                  ScheduleStatus.onDuty => AiraColors.sage,
                  ScheduleStatus.leave => AiraColors.terra,
                  ScheduleStatus.halfDay => AiraColors.gold,
                };
                final label = switch (s) {
                  ScheduleStatus.onDuty => l10n.onDuty,
                  ScheduleStatus.leave => l10n.leave,
                  ScheduleStatus.halfDay => l10n.halfDay,
                };
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _status = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? color.withValues(alpha: 0.18) : AiraColors.parchment,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? color : AiraColors.woodPale.withValues(alpha: 0.5),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              switch (s) {
                                ScheduleStatus.onDuty => Icons.check_circle_rounded,
                                ScheduleStatus.leave => Icons.cancel_rounded,
                                ScheduleStatus.halfDay => Icons.timelapse_rounded,
                              },
                              color: selected ? color : AiraColors.muted,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                color: selected ? color : AiraColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Time pickers row
            Row(
              children: [
                Expanded(
                  child: _TimePickerTile(
                    label: l10n.startTime,
                    value: _startTime,
                    onTap: () => _pickTime(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePickerTile(
                    label: l10n.endTime,
                    value: _endTime,
                    onTap: () => _pickTime(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Note
            Text(l10n.shiftNote, style: AiraFonts.label()),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: AiraFonts.body(fontSize: 16),
              decoration: InputDecoration(
                hintText: l10n.shiftNote,
                filled: true,
                fillColor: AiraColors.parchment,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              height: AiraSizes.buttonHeight,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.saveShift),
              ),
            ),

            // Delete button (only when editing)
            if (widget.entry.schedule != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: AiraSizes.buttonHeight,
                child: OutlinedButton(
                  onPressed: _saving ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AiraColors.terra,
                    side: const BorderSide(color: AiraColors.terra),
                  ),
                  child: Text(l10n.deleteShift),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final VoidCallback onTap;
  const _TimePickerTile({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final display = value != null
        ? '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}'
        : '--:--';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AiraColors.parchment,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
            const SizedBox(height: 4),
            Text(
              display,
              style: AiraFonts.numeric(fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Language Toggle Widget — TH / EN
// ═══════════════════════════════════════════════════════════════
class _LanguageToggle extends StatelessWidget {
  final bool isThai;
  final ValueChanged<bool> onToggle;
  const _LanguageToggle({required this.isThai, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AiraColors.cream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AiraColors.creamDk),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _langChip('TH', isThai, () => onToggle(true)),
          const SizedBox(width: 2),
          _langChip('EN', !isThai, () => onToggle(false)),
        ],
      ),
    );
  }

  Widget _langChip(String label, bool active, VoidCallback onTap) {
    return AiraTapEffect(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AiraColors.woodDk : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active
              ? [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AiraColors.muted,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Month Navigation Button
// ═══════════════════════════════════════════════════════════════
class _MonthNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MonthNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AiraColors.cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AiraColors.creamDk),
        ),
        child: Icon(icon, size: 24, color: AiraColors.charcoal),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Appointment Timeline Row — premium card style
// ═══════════════════════════════════════════════════════════════
class _AppointmentTimelineRow extends ConsumerWidget {
  final Appointment appt;
  final bool isLast;
  final bool isThai;
  const _AppointmentTimelineRow({required this.appt, required this.isLast, required this.isThai});

  Color get _statusColor {
    switch (appt.status) {
      case AppointmentStatus.newAppt: return AiraColors.woodMid;
      case AppointmentStatus.confirmed: return AiraColors.sage;
      case AppointmentStatus.followUp: return AiraColors.gold;
      case AppointmentStatus.completed: return AiraColors.sage;
      case AppointmentStatus.cancelled: return AiraColors.muted;
      case AppointmentStatus.noShow: return AiraColors.terra;
    }
  }

  String get _statusLabel {
    if (isThai) {
      switch (appt.status) {
        case AppointmentStatus.newAppt: return 'ใหม่';
        case AppointmentStatus.confirmed: return 'ยืนยัน';
        case AppointmentStatus.followUp: return 'F/U';
        case AppointmentStatus.completed: return 'เสร็จ';
        case AppointmentStatus.cancelled: return 'ยกเลิก';
        case AppointmentStatus.noShow: return 'ไม่มา';
      }
    } else {
      switch (appt.status) {
        case AppointmentStatus.newAppt: return 'New';
        case AppointmentStatus.confirmed: return 'Confirmed';
        case AppointmentStatus.followUp: return 'Follow-up';
        case AppointmentStatus.completed: return 'Done';
        case AppointmentStatus.cancelled: return 'Cancelled';
        case AppointmentStatus.noShow: return 'No-show';
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientByIdProvider(appt.patientId));
    final doctorAsync = appt.doctorId != null && appt.doctorId!.isNotEmpty
        ? ref.watch(_calendarDoctorProvider(appt.doctorId!))
        : const AsyncValue<Staff?>.data(null);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                appt.startTime.substring(0, 5),
                style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
              ),
            ),
          ),
          // Timeline dots & line
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: _statusColor, width: 2.5),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: AiraColors.creamDk,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Card
          Expanded(
            child: AiraTapEffect(
              onTap: () => context.push('/appointments/${appt.id}/edit'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AiraColors.parchment.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4, height: 40,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: patientAsync.when(
                                  loading: () => Text('...', style: GoogleFonts.plusJakartaSans(fontSize: 15)),
                                  error: (e, s) => Text('?', style: GoogleFonts.plusJakartaSans(fontSize: 15)),
                                  data: (p) => Text(
                                    p != null
                                        ? '${p.firstName} ${p.lastName}${p.nickname != null ? ' (${p.nickname})' : ''}'
                                        : context.l10n.notFoundShort,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.charcoal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _statusLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appt.treatmentType ?? context.l10n.noTreatmentSpecified,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted),
                          ),
                          doctorAsync.when(
                            data: (doctor) => doctor != null
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      context.l10n.isThai
                                          ? 'แพทย์: ${doctor.fullName}'
                                          : 'Doctor: ${doctor.fullName}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AiraColors.woodMid,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 20, color: AiraColors.muted.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
