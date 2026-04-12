import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/localization/app_localizations.dart';

part '_dashboard_header.dart';
part '_dashboard_cards.dart';
part '_dashboard_panels.dart';

// ─── Dashboard search ─────────────────────────────────────────
final _dashSearchQueryProvider = StateProvider<String>((ref) => '');
final _dashSearchResultsProvider = FutureProvider<List<Patient>>((ref) {
  final q = ref.watch(_dashSearchQueryProvider).trim();
  if (q.length < 2) return [];
  return ref.watch(patientSearchProvider(q).future);
});

// ─── Helpers ─────────────────────────────────────────────────
String _t(bool isThai, String th, String en) => isThai ? th : en;

String _dashboardGreeting(bool isThai) {
  final h = DateTime.now().hour;
  if (isThai) {
    if (h >= 5 && h < 12) return 'สวัสดีตอนเช้าค่ะ';
    if (h >= 12 && h < 17) return 'สวัสดีตอนบ่ายค่ะ';
    if (h >= 17 && h < 21) return 'สวัสดีตอนเย็นค่ะ';
    return 'สวัสดีตอนค่ำค่ะ';
  }
  if (h >= 5 && h < 12) return 'Good morning';
  if (h >= 12 && h < 17) return 'Good afternoon';
  if (h >= 17 && h < 21) return 'Good evening';
  return 'Good night';
}

String _dashboardFormattedDate(bool isThai) {
  final now = DateTime.now();
  const thaiDayNames = [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ];
  const thaiMonthNames = [
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];
  const enDayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const enMonthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  if (isThai) {
    final buddhistYear = now.year + 543;
    return 'วัน${thaiDayNames[now.weekday - 1]}ที่ ${now.day} ${thaiMonthNames[now.month - 1]} $buddhistYear';
  }
  return '${enDayNames[now.weekday - 1]}, ${enMonthNames[now.month - 1]} ${now.day}, ${now.year}';
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 980;
        final hp = constraints.maxWidth >= 1280
            ? 32.0
            : constraints.maxWidth >= 768
                ? 24.0
                : 16.0;
        final maxW = isWide ? 1380.0 : 860.0;

        if (isWide) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(
                children: [
                  _HeroHeader(isWide: true),
                  const SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hp),
                    child: const _PatientSearchBar(),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hp),
                    child: const _StatCardsRow(),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: hp),
                    child: const _QuickActionsStrip(),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hp, 0, hp, 16),
                      child: _buildWide(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _HeroHeader(isWide: false)),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hp),
                    child: const _PatientSearchBar(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hp),
                    child: const _StatCardsRow(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hp),
                    child: const _QuickActionsStrip(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hp),
                    child: _buildNarrow(context),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 108)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: _AppointmentsSection(),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: _DataPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrow(BuildContext context) {
    return Column(
      children: [
        _AppointmentsSection(),
        const SizedBox(height: 24),
        _DataPanel(),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// QUICK ACTIONS — compact horizontal strip
// ═══════════════════════════════════════════════════════════════════
class _QuickActionsStrip extends ConsumerWidget {
  const _QuickActionsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    return Row(
      children: [
        Expanded(
          child: _QuickActionChip(
            icon: Icons.person_add_rounded,
            label: _t(isThai, 'เพิ่มผู้รับบริการ', 'Add Patient'),
            color: AiraColors.woodMid,
            onTap: () => context.push('/patients/new'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionChip(
            icon: Icons.event_rounded,
            label: _t(isThai, 'สร้างนัด', 'New Appointment'),
            color: AiraColors.sage,
            onTap: () => context.push('/appointments/new'),
          ),
        ),
      ],
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _QuickActionChip({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: onTap,
      scaleDown: 0.94,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

