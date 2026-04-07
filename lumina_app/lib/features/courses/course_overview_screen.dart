import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/localization/app_localizations.dart';

// ─── Filters ──────────────────────────────────────────────────
final _courseFilterProvider = StateProvider<CourseStatus?>((ref) => null);
final _courseSearchProvider = StateProvider<String>((ref) => '');

class CourseOverviewScreen extends ConsumerWidget {
  const CourseOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(courseListProvider);
    final filter = ref.watch(_courseFilterProvider);
    final searchQ = ref.watch(_courseSearchProvider).toLowerCase();
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AiraColors.cream,
      appBar: AppBar(
        title: Text(l.isThai ? 'ภาพรวมคอร์สทั้งหมด' : 'All Courses Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/courses/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + filters
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.6)),
                  ),
                  child: TextField(
                    onChanged: (v) => ref.read(_courseSearchProvider.notifier).state = v,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: l.isThai ? 'ค้นหาชื่อคอร์ส / ผู้ป่วย...' : 'Search course / patient...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted.withValues(alpha: 0.5)),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: AiraColors.muted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(label: l.all, isActive: filter == null, onTap: () => ref.read(_courseFilterProvider.notifier).state = null),
                      const SizedBox(width: 8),
                      _FilterChip(label: l.isThai ? 'ใช้งาน' : 'Active', isActive: filter == CourseStatus.active, color: AiraColors.sage, onTap: () => ref.read(_courseFilterProvider.notifier).state = CourseStatus.active),
                      const SizedBox(width: 8),
                      _FilterChip(label: l.isThai ? 'เหลือน้อย' : 'Low', isActive: filter == CourseStatus.low, color: AiraColors.gold, onTap: () => ref.read(_courseFilterProvider.notifier).state = CourseStatus.low),
                      const SizedBox(width: 8),
                      _FilterChip(label: l.isThai ? 'ครบแล้ว' : 'Completed', isActive: filter == CourseStatus.completed, color: AiraColors.woodMid, onTap: () => ref.read(_courseFilterProvider.notifier).state = CourseStatus.completed),
                      const SizedBox(width: 8),
                      _FilterChip(label: l.expired, isActive: filter == CourseStatus.expired, color: AiraColors.terra, onTap: () => ref.read(_courseFilterProvider.notifier).state = CourseStatus.expired),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Summary row
          coursesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
            data: (courses) {
              final active = courses.where((c) => c.status == CourseStatus.active).length;
              final low = courses.where((c) => c.status == CourseStatus.low).length;
              final completed = courses.where((c) => c.status == CourseStatus.completed).length;
              final expired = courses.where((c) => c.status == CourseStatus.expired).length;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _StatBadge(label: l.all, count: courses.length, color: AiraColors.charcoal),
                    const SizedBox(width: 8),
                    _StatBadge(label: l.isThai ? 'ใช้งาน' : 'Active', count: active, color: AiraColors.sage),
                    const SizedBox(width: 8),
                    _StatBadge(label: l.low, count: low, color: AiraColors.gold),
                    const SizedBox(width: 8),
                    _StatBadge(label: l.done, count: completed, color: AiraColors.woodMid),
                    const SizedBox(width: 8),
                    _StatBadge(label: l.expired, count: expired, color: AiraColors.terra),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Course list
          Expanded(
            child: coursesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text(l.errorMsg('$e'))),
              data: (courses) {
                var filtered = courses.toList();
                if (filter != null) filtered = filtered.where((c) => c.status == filter).toList();
                if (searchQ.isNotEmpty) {
                  filtered = filtered.where((c) => c.name.toLowerCase().contains(searchQ)).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.card_membership_rounded, size: 48, color: AiraColors.muted.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(l.noCoursesTreatment, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AiraColors.muted)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _OverviewCourseCard(course: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isActive, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? (color ?? AiraColors.woodDk) : AiraColors.woodWash.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AiraColors.charcoal),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatBadge({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text('$count', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _OverviewCourseCard extends ConsumerWidget {
  final Course course;
  const _OverviewCourseCard({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientByIdProvider(course.patientId));
    final total = course.sessionsTotal ?? (course.sessionsBought + course.sessionsBonus);
    final remaining = total - course.sessionsUsed;
    final progress = total > 0 ? course.sessionsUsed / total : 0.0;
    final l = context.l10n;

    return AiraTapEffect(
      onTap: () => context.push('/courses/${course.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.6)),
          boxShadow: AiraShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.card_membership_rounded, size: 20, color: _statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
                      patientAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, s) => const SizedBox.shrink(),
                        data: (p) => p != null
                            ? AiraTapEffect(
                                onTap: () => context.push('/patients/${p.id}'),
                                child: Row(
                                  children: [
                                    Icon(Icons.person_rounded, size: 12, color: AiraColors.woodMid),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        '${p.firstName} ${p.lastName}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.woodMid, fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(_statusLabel(l), style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.sessionCount(course.sessionsUsed, total), style: AiraFonts.numeric(fontSize: 12, fontWeight: FontWeight.w500, color: AiraColors.muted)),
                Text(l.remainingSessions(remaining), style: AiraFonts.numeric(fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: progress, backgroundColor: AiraColors.creamDk, valueColor: AlwaysStoppedAnimation<Color>(_statusColor), minHeight: 6),
            ),
            // Bottom info row
            const SizedBox(height: 8),
            Row(
              children: [
                if (course.expiryDate != null) ...[
                  Icon(Icons.schedule_rounded, size: 12, color: AiraColors.muted),
                  const SizedBox(width: 4),
                  Text(DateFormat('dd/MM/yy').format(course.expiryDate!), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted)),
                  const SizedBox(width: 12),
                ],
                if (course.price != null) ...[
                  Icon(Icons.payments_rounded, size: 12, color: AiraColors.muted),
                  const SizedBox(width: 4),
                  Text('฿${NumberFormat('#,##0').format(course.price)}', style: AiraFonts.numeric(fontSize: 11, color: AiraColors.muted)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color get _statusColor {
    switch (course.status) {
      case CourseStatus.active: return AiraColors.sage;
      case CourseStatus.low: return AiraColors.gold;
      case CourseStatus.completed: return AiraColors.woodMid;
      case CourseStatus.expired: return AiraColors.terra;
    }
  }

  String _statusLabel(AppL10n l) {
    switch (course.status) {
      case CourseStatus.active: return l.isThai ? 'ใช้งาน' : 'Active';
      case CourseStatus.low: return l.isThai ? 'เหลือน้อย' : 'Low';
      case CourseStatus.completed: return l.isThai ? 'ครบแล้ว' : 'Completed';
      case CourseStatus.expired: return l.expired;
    }
  }
}
