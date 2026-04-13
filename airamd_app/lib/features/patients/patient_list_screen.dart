import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/localization/app_localizations.dart';

// ─── Filter state ──────────────────────────────────────────
final _searchQueryProvider = StateProvider<String>((ref) => '');
final _activeFilterProvider = StateProvider<String>((ref) => 'ทั้งหมด');

final _filteredPatientsProvider = FutureProvider<List<Patient>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(patientRepoProvider);
  final query = ref.watch(_searchQueryProvider);
  final filter = ref.watch(_activeFilterProvider);

  List<Patient> patients;
  if (query.isNotEmpty) {
    patients = await repo.searchPatients(clinicId: clinicId, query: query);
  } else if (filter == 'VIP') {
    patients = await repo.getByStatus(clinicId: clinicId, status: PatientStatus.vip);
  } else if (filter == 'STAR' || filter == '⭐') {
    patients = await repo.getByStatus(clinicId: clinicId, status: PatientStatus.star);
  } else if (filter == 'นัดวันนี้') {
    final appointments = await ref.watch(todayAppointmentsProvider.future);
    if (appointments.isEmpty) return [];
    final patientIds = appointments.map((a) => a.patientId).toSet();
    final allPatients = await repo.list(clinicId: clinicId);
    patients = allPatients.where((p) => patientIds.contains(p.id)).toList();
  } else if (filter == 'Follow-up') {
    final apptRepo = ref.watch(appointmentRepoProvider);
    final allAppts = await apptRepo.list(clinicId: clinicId, limit: 500);
    final followUpIds = allAppts
        .where((a) => a.status == AppointmentStatus.followUp)
        .map((a) => a.patientId)
        .toSet();
    if (followUpIds.isEmpty) return [];
    final allPatients = await repo.list(clinicId: clinicId);
    patients = allPatients.where((p) => followUpIds.contains(p.id)).toList();
  } else {
    patients = await repo.list(clinicId: clinicId);
  }
  return patients;
});

class PatientListScreen extends ConsumerStatefulWidget {
  const PatientListScreen({super.key});

  @override
  ConsumerState<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends ConsumerState<PatientListScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(_filteredPatientsProvider);
    final countAsync = ref.watch(patientCountProvider);
    final activeFilter = ref.watch(_activeFilterProvider);
    final canManageClinicalData = ref.watch(canManageClinicalDataProvider);
    final effectiveRole = ref.watch(effectiveStaffRoleProvider);
    final l = context.l10n;

    return Stack(
      children: [
        Positioned(
          top: -40, right: -60,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AiraColors.sage.withValues(alpha: 0.08),
                AiraColors.sage.withValues(alpha: 0.0),
              ]),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            return Column(
            children: [
              // ─── Header ───
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: isNarrow
                    // Narrow: stack title + search vertically
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4, height: 28,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B6650), Color(0xFFD4B89A)],
                                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(l.patientList, style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
                              const SizedBox(width: 10),
                              countAsync.when(
                                data: (count) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(color: AiraColors.woodDk, borderRadius: BorderRadius.circular(12)),
                                  child: Text('$count', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                                ),
                                loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                                error: (e, s) => const SizedBox.shrink(),
                              ),
                              const Spacer(),
                              if (canManageClinicalData)
                                AiraTapEffect(
                                  onTap: () => context.push('/patients/new'),
                                  child: Container(
                                    height: 44,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [BoxShadow(color: const Color(0xFF6B4F3A).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.person_add_rounded, size: 18, color: Colors.white),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Full-width search on narrow
                          Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AiraColors.creamDk),
                              boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (v) {
                                ref.read(_searchQueryProvider.notifier).state = v;
                                setState(() {});
                              },
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal),
                              decoration: InputDecoration(
                                hintText: l.searchHintFull,
                                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted.withValues(alpha: 0.5)),
                                prefixIcon: Icon(Icons.search_rounded, size: 20, color: AiraColors.muted.withValues(alpha: 0.6)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 18),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          ref.read(_searchQueryProvider.notifier).state = '';
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      )
                    // Wide: original row layout
                    : Row(
                  children: [
                    Container(
                      width: 4, height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B6650), Color(0xFFD4B89A)],
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(l.patientList, style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
                    const SizedBox(width: 10),
                    countAsync.when(
                      data: (count) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: AiraColors.woodDk, borderRadius: BorderRadius.circular(12)),
                        child: Text('$count', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                      loading: () => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                    const Spacer(),
                    // Search field — flexible width
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AiraColors.creamDk),
                        boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) {
                          ref.read(_searchQueryProvider.notifier).state = v;
                          setState(() {});
                        },
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal),
                        decoration: InputDecoration(
                          hintText: l.searchHintFull,
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted.withValues(alpha: 0.5)),
                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: AiraColors.muted.withValues(alpha: 0.6)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    ref.read(_searchQueryProvider.notifier).state = '';
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Add patient button
                    if (canManageClinicalData)
                      AiraTapEffect(
                        onTap: () => context.push('/patients/new'),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: const Color(0xFF6B4F3A).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_add_rounded, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(l.addPatient, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ─── Filter Chips ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    for (final f in [l.all, 'VIP', l.todayAppt, 'Follow-up']) ...[
                      AiraTapEffect(
                        onTap: () => ref.read(_activeFilterProvider.notifier).state = f,
                        child: _FilterChip(f, activeFilter == f),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AiraColors.creamDk)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort_rounded, size: 16, color: AiraColors.muted),
                          const SizedBox(width: 6),
                          Text(l.sortByRecent, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ─── Patient List ───
              Expanded(
                child: patientsAsync.when(
                  data: (patients) {
                    if (patients.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_rounded, size: 56, color: AiraColors.muted.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(l.noPatientData, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AiraColors.muted)),
                            const SizedBox(height: 8),
                            Text(l.tapAddToStart, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted.withValues(alpha: 0.6))),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(_filteredPatientsProvider),
                      color: AiraColors.woodDk,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                        itemCount: patients.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _PatientCard(
                            patient: patients[index],
                            onTap: () => context.push('/patients/${patients[index].id}'),
                            onDelete: effectiveRole == StaffRole.owner
                                ? () => _confirmDelete(context, ref, patients[index])
                                : null,
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AiraColors.terra),
                        const SizedBox(height: 12),
                        Text(l.failedToLoad, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.charcoal)),
                        const SizedBox(height: 4),
                        Text('$e', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(_filteredPatientsProvider),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(l.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
          },
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Patient patient) {
    final l = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l.deletePatient, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(l.deletePatientConfirm(patient.fullName, patient.hn), style: GoogleFonts.plusJakartaSans(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(patientListProvider.notifier).deletePatient(patient.id);
                ref.invalidate(_filteredPatientsProvider);
                ref.invalidate(patientCountProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.deletedPatient(patient.fullName)), backgroundColor: AiraColors.sage),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.deleteFailed('$e')), backgroundColor: AiraColors.terra),
                  );
                }
              }
            },
            child: Text(l.delete, style: GoogleFonts.plusJakartaSans(color: AiraColors.terra, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  const _FilterChip(this.label, this.active);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AiraColors.woodDk : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AiraColors.woodDk : AiraColors.creamDk),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : AiraColors.muted),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  const _PatientCard({required this.patient, required this.onTap, required this.onDelete});

  Color get _accentColor {
    if (patient.status == PatientStatus.vip) return const Color(0xFFC4922A);
    if (patient.status == PatientStatus.star) return AiraColors.sage;
    return AiraColors.woodMid;
  }

  @override
  Widget build(BuildContext context) {
    final initial = patient.firstName.isNotEmpty ? patient.firstName[0] : '?';
    final displayName = '${patient.firstName} ${patient.lastName}';
    final nick = patient.nickname;

    return AiraTapEffect(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.6)),
          boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_accentColor.withValues(alpha: 0.15), _accentColor.withValues(alpha: 0.05)]),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(initial, style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: _accentColor)),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nick != null && nick.isNotEmpty ? '$displayName ($nick)' : displayName,
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (patient.status == PatientStatus.vip) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFC4922A), Color(0xFFE0B44C)]),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('VIP', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ],
                      if (patient.status == PatientStatus.star) ...[
                        const SizedBox(width: 8),
                        Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (_) => const Icon(Icons.star_rounded, size: 12, color: Color(0xFFC4922A)))),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(patient.hn ?? '-', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.woodMid)),
                      Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: const BoxDecoration(color: AiraColors.creamDk, shape: BoxShape.circle)),
                      Text(patient.phone ?? '-', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
            // Age / DOB
            if (patient.dateOfBirth != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${patient.age} ${AppL10n.of(context).years}', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.charcoal)),
                  const SizedBox(height: 2),
                  Text(patient.gender?.label() ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted)),
                ],
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AiraColors.muted),
          ],
        ),
      ),
    );
  }
}
