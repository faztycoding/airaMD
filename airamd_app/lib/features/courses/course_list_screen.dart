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

class CourseListScreen extends ConsumerWidget {
  final String? patientId;
  const CourseListScreen({super.key, this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = patientId != null
        ? ref.watch(coursesByPatientProvider(patientId!))
        : ref.watch(courseListProvider);

    return Scaffold(
      backgroundColor: AiraColors.cream,
      appBar: AppBar(
        title: Builder(builder: (ctx) => Text(ctx.l10n.courseTreatment)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/courses/new${patientId != null ? '?patientId=$patientId' : ''}'),
          ),
        ],
      ),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(context.l10n.errorMsg('$e'))),
        data: (courses) {
          if (courses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8)),
                      BoxShadow(color: AiraColors.gold.withValues(alpha: 0.06), blurRadius: 40, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon badge
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AiraColors.woodPale.withValues(alpha: 0.18), AiraColors.gold.withValues(alpha: 0.10)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.2)),
                        ),
                        child: Icon(Icons.card_membership_rounded, size: 32, color: AiraColors.woodMid),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.l10n.noCoursesTreatment,
                        style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.courseEmptyDesc,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted, height: 1.5),
                      ),
                      const SizedBox(height: 28),
                      AiraTapEffect(
                        onTap: () => context.push('/courses/new${patientId != null ? '?patientId=$patientId' : ''}'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3D2517), Color(0xFF6B4F3A), Color(0xFF8B6650)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(context.l10n.newCourse, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: courses.length,
            separatorBuilder: (_, i2) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _CourseCard(course: courses[i]),
          );
        },
      ),
    );
  }
}

class _CourseCard extends ConsumerWidget {
  final Course course;
  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientByIdProvider(course.patientId));
    final total = course.sessionsTotal ?? (course.sessionsBought + course.sessionsBonus);
    final remaining = total - course.sessionsUsed;
    final progress = total > 0 ? course.sessionsUsed / total : 0.0;

    return AiraTapEffect(
      onTap: () => context.push('/courses/${course.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
                      Text(course.name, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
                      patientAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (e, s) => const SizedBox.shrink(),
                        data: (p) => p != null
                            ? Text('${p.firstName} ${p.lastName}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted))
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_statusLabel, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.l10n.sessionCount(course.sessionsUsed, total), style: AiraFonts.numeric(fontSize: 12, fontWeight: FontWeight.w500, color: AiraColors.muted)),
                          Text(context.l10n.remainingSessions(remaining), style: AiraFonts.numeric(fontSize: 12, fontWeight: FontWeight.w700, color: _statusColor)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AiraColors.creamDk,
                          valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (course.expiryDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: AiraColors.muted),
                  const SizedBox(width: 4),
                  Text(
                    'หมดอายุ: ${DateFormat('dd/MM/yyyy').format(course.expiryDate!)}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted),
                  ),
                ],
              ),
            ],
            if (course.price != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.payments_rounded, size: 14, color: AiraColors.muted),
                  const SizedBox(width: 4),
                  Text(
                    'ราคา: ฿${NumberFormat('#,##0').format(course.price)}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted),
                  ),
                ],
              ),
            ],
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

  String get _statusLabel {
    switch (course.status) {
      case CourseStatus.active: return 'ใช้งาน';
      case CourseStatus.low: return 'เหลือน้อย';
      case CourseStatus.completed: return 'ครบแล้ว';
      case CourseStatus.expired: return 'หมดอายุ';
    }
  }
}
