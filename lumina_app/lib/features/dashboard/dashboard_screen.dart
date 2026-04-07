import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/localization/app_localizations.dart';

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

// ═══════════════════════════════════════════════════════════════════
// DATA PANEL — Ops Snapshot + Revenue + Follow-ups + Inventory
// ═══════════════════════════════════════════════════════════════════
class _DataPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OpsSnapshotCard(),
        const SizedBox(height: 16),
        _RevenueCard(),
        const SizedBox(height: 16),
        _FollowUpCard(),
        const SizedBox(height: 16),
        _InventoryAlertCard(),
        const SizedBox(height: 16),
        _ExpiryAlertCard(),
      ],
    );
  }
}

class _StarBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AiraColors.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (_) => const Icon(Icons.star_rounded, size: 12, color: Color(0xFFC4922A)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HERO HEADER — tall, dramatic, layered gradient
// ═══════════════════════════════════════════════════════════════════
class _HeroHeader extends ConsumerWidget {
  final bool isWide;
  const _HeroHeader({required this.isWide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final topPad = MediaQuery.of(context).padding.top;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = !isWide || constraints.maxWidth < 560;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            compact ? 18 : 24,
            topPad + (isWide ? 6 : 10),
            compact ? 18 : 24,
            compact ? 24 : 18,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6B4F3A), Color(0xFF8B6650), Color(0xFFBE9B7D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B4F3A).withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(right: -50, top: -40, child: _Orb(160, 0.07)),
              Positioned(right: 60, top: 20, child: _Orb(90, 0.05)),
              Positioned(left: -30, bottom: -30, child: _Orb(110, 0.04)),
              Positioned(right: 20, bottom: -20, child: _Orb(60, 0.06)),
              Positioned.fill(child: CustomPaint(painter: _GridPatternPainter())),
              compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeroAvatar(size: 46),
                            const Spacer(),
                            const _LangToggle(),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _HeroTextBlock(isThai: isThai, compact: true),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroAvatar(size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _HeroTextBlock(isThai: isThai, compact: false),
                        ),
                        const _LangToggle(),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  final double size;
  const _HeroAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.medical_services_rounded,
          color: Colors.white,
          size: size * 0.45,
        ),
      ),
    );
  }
}

class _HeroTextBlock extends StatelessWidget {
  final bool isThai;
  final bool compact;
  const _HeroTextBlock({required this.isThai, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _dashboardGreeting(isThai),
          style: GoogleFonts.plusJakartaSans(
            fontSize: compact ? 12 : 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.75),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Text(
              'Dr. Pammy',
              style: AiraFonts.heading(
                fontSize: compact ? 24 : 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.1,
              ),
            ),
            Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 13,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _dashboardFormattedDate(isThai),
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final double opacity;
  const _Orb(this.size, this.opacity);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LangToggle extends StatelessWidget {
  const _LangToggle();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isThai = ref.watch(isThaiProvider);
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AiraTapEffect(
                onTap: () {
                  ref.read(localeProvider.notifier).state = const Locale('th', 'TH');
                },
                scaleDown: 0.90,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isThai ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isThai
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'TH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isThai ? AiraColors.woodDk : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              AiraTapEffect(
                onTap: () {
                  ref.read(localeProvider.notifier).state = const Locale('en', 'US');
                },
                scaleDown: 0.90,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isThai ? Colors.transparent : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isThai
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Text(
                    'EN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isThai ? Colors.white.withValues(alpha: 0.7) : AiraColors.woodDk,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// STAT CARDS — glassmorphism, overlapping header
// ═══════════════════════════════════════════════════════════════════
class _StatCardsRow extends ConsumerWidget {
  const _StatCardsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final isThai = ref.watch(isThaiProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 720;
        return statsAsync.when(
          data: (stats) => _grid(
            '${stats.todayAppointments}',
            '${stats.totalPatients}',
            '${stats.pendingFollowUps}',
            _formatRevenue(stats.monthRevenue),
            isThai: isThai,
            wide: wide,
          ),
          loading: () => _grid('-', '-', '-', '-', isThai: isThai, wide: wide),
          error: (e, s) => _grid('!', '!', '!', '!', isThai: isThai, wide: wide),
        );
      },
    );
  }

  Widget _grid(
    String v1,
    String v2,
    String v3,
    String v4, {
    required bool isThai,
    bool wide = false,
  }) {
    if (wide) {
      return Row(
        children: [
          Expanded(
            child: _StatCard(
              v1,
              _t(isThai, 'นัดวันนี้', 'Today'),
              Icons.calendar_today_rounded,
              AiraColors.woodMid,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              v2,
              _t(isThai, 'คนไข้ทั้งหมด', 'Patients'),
              Icons.people_rounded,
              AiraColors.sage,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              v3,
              _t(isThai, 'รอ Follow-up', 'Follow-ups'),
              Icons.replay_rounded,
              AiraColors.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              v4,
              _t(isThai, 'รายได้วันนี้', 'Revenue'),
              Icons.account_balance_wallet_rounded,
              const Color(0xFFB86848),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                v1,
                _t(isThai, 'นัดวันนี้', 'Today'),
                Icons.calendar_today_rounded,
                AiraColors.woodMid,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                v2,
                _t(isThai, 'คนไข้ทั้งหมด', 'Patients'),
                Icons.people_rounded,
                AiraColors.sage,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                v3,
                _t(isThai, 'รอ Follow-up', 'Follow-ups'),
                Icons.replay_rounded,
                AiraColors.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                v4,
                _t(isThai, 'รายได้วันนี้', 'Revenue'),
                Icons.account_balance_wallet_rounded,
                const Color(0xFFB86848),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatRevenue(double amount) {
    if (amount >= 1000000) return '฿${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '฿${(amount / 1000).toStringAsFixed(1)}K';
    return '฿${amount.toStringAsFixed(0)}';
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.18),
                  color.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AiraFonts.label(fontSize: 11, color: AiraColors.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AiraFonts.numeric(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AiraColors.charcoal,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// APPOINTMENTS SECTION
// ═══════════════════════════════════════════════════════════════════
class _AppointmentsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final apptsAsync = ref.watch(todayAppointmentsProvider);
    return apptsAsync.when(
      data: (appts) {
        final sorted = [...appts]
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 520;
                return Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B6650), Color(0xFFD4B89A)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _t(isThai, 'นัดวันนี้', 'Today\'s Appointments'),
                          style: GoogleFonts.playfairDisplay(
                            fontSize: compact ? 22 : 24,
                            fontWeight: FontWeight.w700,
                            color: AiraColors.charcoal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AiraColors.woodDk,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${sorted.length}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AiraTapEffect(
                      onTap: () => context.go('/calendar'),
                      scaleDown: 0.94,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AiraColors.woodWash.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AiraColors.woodPale.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AiraColors.woodDk.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _t(isThai, 'ดูปฏิทินทั้งหมด', 'Open calendar'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AiraColors.woodDk,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AiraColors.muted.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (sorted.isEmpty)
              _DashboardEmptyState(
                title: _t(isThai, 'วันนี้ยังไม่มีนัดหมาย', 'No appointments today'),
                subtitle: _t(isThai, 'สามารถสร้างนัดใหม่จากปุ่มด้านขวาหรือหน้า Calendar ได้ทันที', 'You can create a new appointment from Quick Actions or Calendar.'),
                icon: Icons.event_available_rounded,
              ),
            ...sorted.map(
              (appt) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LiveAppointmentCard(appt: appt),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const _DashboardSectionLoading(itemCount: 4),
      error: (e, s) => _DashboardEmptyState(
        title: _t(isThai, 'โหลดนัดหมายไม่สำเร็จ', 'Failed to load appointments'),
        subtitle: '$e',
        icon: Icons.error_outline_rounded,
      ),
    );
  }
}

class _LiveAppointmentCard extends ConsumerWidget {
  final Appointment appt;
  const _LiveAppointmentCard({required this.appt});

  Color get _accentColor {
    switch (appt.status) {
      case AppointmentStatus.newAppt:
        return AiraColors.woodMid;
      case AppointmentStatus.confirmed:
        return AiraColors.sage;
      case AppointmentStatus.followUp:
        return AiraColors.gold;
      case AppointmentStatus.completed:
        return AiraColors.sage;
      case AppointmentStatus.cancelled:
        return AiraColors.muted;
      case AppointmentStatus.noShow:
        return AiraColors.terra;
    }
  }

  String _statusKey() {
    switch (appt.status) {
      case AppointmentStatus.newAppt:
        return 'NEW';
      case AppointmentStatus.confirmed:
        return 'CONFIRMED';
      case AppointmentStatus.followUp:
        return 'FOLLOW_UP';
      case AppointmentStatus.completed:
        return 'COMPLETED';
      case AppointmentStatus.cancelled:
        return 'CANCELLED';
      case AppointmentStatus.noShow:
        return 'NO_SHOW';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientByIdProvider(appt.patientId));
    final isThai = ref.watch(isThaiProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return patientAsync.when(
          loading: () => const _DashboardCardSkeleton(height: 96),
          error: (e, s) => _DashboardEmptyState(
            title: _t(isThai, 'โหลดข้อมูลคนไข้ไม่สำเร็จ', 'Failed to load patient data'),
            subtitle: '$e',
            icon: Icons.error_outline_rounded,
          ),
          data: (patient) {
            final displayName = patient == null
                ? _t(isThai, 'ไม่พบข้อมูล', 'Not found')
                : '${patient.firstName} ${patient.lastName}'.trim().isEmpty
                    ? _t(isThai, 'ไม่ระบุชื่อ', 'Unnamed patient')
                    : '${patient.firstName} ${patient.lastName}';
            final nickname = patient?.nickname;
            final treatment = appt.treatmentType ?? _t(isThai, 'ไม่ระบุหัตถการ', 'No treatment specified');
            final actions = <String>[
              if (patient?.lineId != null && patient!.lineId!.isNotEmpty) 'line',
              if (patient?.facebook != null && patient!.facebook!.isNotEmpty) 'fb',
            ];
            final tier = patient?.status;

            return AiraTapEffect(
              onTap: () => context.push('/appointments/${appt.id}/edit'),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: AiraColors.woodDk.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: compact
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(width: 5, height: 48, color: _accentColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appt.startTime.substring(0, 5),
                                          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AiraColors.charcoal),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          displayName,
                                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  _StatusChip(_statusKey()),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (tier == PatientStatus.vip) _VipBadge(),
                                  if (tier == PatientStatus.star) _StarBadge(),
                                  if (nickname != null && nickname.isNotEmpty) _MetaChip(label: '${_t(isThai, 'ชื่อเล่น', 'Nickname')}: $nickname'),
                                  _MetaChip(label: treatment),
                                ],
                              ),
                              if (patient != null && patient.drugAllergies.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '⚠ ${_t(isThai, 'แพ้', 'Allergy')}: ${patient.drugAllergies.join(', ')}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AiraColors.danger),
                                ),
                              ],
                              if (actions.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: actions
                                      .map((a) => Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: _ContactBtn(a),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            Container(width: 5, height: 104, color: _accentColor),
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 58,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    appt.startTime.substring(0, 5),
                                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AiraColors.charcoal),
                                  ),
                                  Text(
                                    appt.startTime.compareTo('12:00') < 0 ? 'AM' : 'PM',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: AiraColors.muted, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 40, margin: const EdgeInsets.symmetric(horizontal: 10), color: AiraColors.creamDk),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                _accentColor.withValues(alpha: 0.2),
                                                _accentColor.withValues(alpha: 0.08),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              displayName.isEmpty ? '?' : displayName[0],
                                              style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700, color: _accentColor),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: displayName,
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                                                ),
                                                if (nickname != null && nickname.isNotEmpty)
                                                  TextSpan(
                                                    text: ' ($nickname)',
                                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
                                                  ),
                                              ],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (tier == PatientStatus.vip) _VipBadge(),
                                        if (tier == PatientStatus.star) _StarBadge(),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      treatment,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted, height: 1.3),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (patient != null && patient.drugAllergies.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '⚠ ${_t(isThai, 'แพ้', 'Allergy')}: ${patient.drugAllergies.join(', ')}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AiraColors.danger),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _StatusChip(_statusKey()),
                                  if (actions.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: actions
                                          .map((a) => Padding(
                                                padding: const EdgeInsets.only(left: 5),
                                                child: _ContactBtn(a),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AiraColors.parchment,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.woodDk),
      ),
    );
  }
}

class _VipBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC4922A), Color(0xFFE0B44C)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC4922A).withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'VIP',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatusChip extends ConsumerWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    Color bg, fg;
    String label;
    switch (status) {
      case 'NEW':
        bg = AiraColors.woodWash;
        fg = AiraColors.woodDk;
        label = _t(isThai, 'ใหม่', 'NEW');
      case 'CONFIRMED':
        bg = AiraColors.sage.withValues(alpha: 0.14);
        fg = AiraColors.sage;
        label = _t(isThai, 'ยืนยัน', 'Confirmed');
      case 'FOLLOW_UP':
        bg = AiraColors.gold.withValues(alpha: 0.14);
        fg = AiraColors.gold;
        label = _t(isThai, 'ติดตามผล', 'Follow-up');
      default:
        bg = AiraColors.creamDk;
        fg = AiraColors.muted;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _ContactBtn extends StatelessWidget {
  final String type;
  const _ContactBtn(this.type);

  @override
  Widget build(BuildContext context) {
    final isLine = type == 'line';
    final color = isLine ? const Color(0xFF06C755) : const Color(0xFF1877F2);
    return AiraTapEffect(
      scaleDown: 0.90,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLine ? Icons.chat_rounded : Icons.facebook_rounded,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            isLine ? 'LINE' : 'FB',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// (_RightPanel and _ActionCard removed — replaced by _DataPanel + _QuickActionsStrip above)

class _OpsSnapshotCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final canAccessFinancialData = ref.watch(canAccessFinancialDataProvider);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: AiraColors.woodDk.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: statsAsync.when(
        data: (stats) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t(isThai, 'ภาพรวมการทำงานวันนี้', 'Today\'s Ops Snapshot'),
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
            ),
            const SizedBox(height: 4),
            Text(
              _t(isThai, 'สรุปภาพรวมหน้าคลินิกที่ควรเช็กก่อนเริ่มงาน', 'A quick operational summary before the next patient arrives.'),
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted, height: 1.4),
            ),
            const SizedBox(height: 14),
            _OpsLine(label: _t(isThai, 'นัดหมายวันนี้', 'Today\'s Appointments'), value: '${stats.todayAppointments}', accent: AiraColors.woodMid),
            _OpsLine(label: _t(isThai, 'ติดตามผลค้าง', 'Pending follow-ups'), value: '${stats.pendingFollowUps}', accent: AiraColors.gold),
            _OpsLine(label: _t(isThai, 'ข้อมูลผู้รับบริการ', 'Service Recipients'), value: '${stats.totalPatients}', accent: AiraColors.sage),
            _OpsLine(
              label: _t(isThai, 'รายได้ที่มองเห็น', 'Visible revenue'),
              value: canAccessFinancialData ? _formatDashboardAmount(stats.monthRevenue) : _t(isThai, 'จำกัดสิทธิ์', 'Restricted'),
              accent: canAccessFinancialData ? AiraColors.terra : AiraColors.muted,
            ),
          ],
        ),
        loading: () => const _DashboardCardSkeleton(height: 180),
        error: (e, s) => _DashboardEmptyState(
          title: _t(isThai, 'โหลดภาพรวมไม่สำเร็จ', 'Failed to load snapshot'),
          subtitle: '$e',
          icon: Icons.error_outline_rounded,
        ),
      ),
    );
  }
}

class _OpsLine extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _OpsLine({required this.label, required this.value, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: accent),
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final revenueAsync = ref.watch(todayRevenueProvider);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8F4EE), Color(0xFFFFFCF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AiraColors.woodDk.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AiraColors.sage.withValues(alpha: 0.2),
                      AiraColors.sage.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AiraColors.sage,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _t(isThai, 'รายได้วันนี้', 'Today\'s Revenue'),
                  style: AiraFonts.label(fontSize: 13, color: AiraColors.muted),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AiraColors.sage.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      size: 13,
                      color: AiraColors.sage,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '+23%',
                      style: AiraFonts.numeric(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AiraColors.sage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          revenueAsync.when(
            data: (amount) => Text(
              _formatDashboardAmount(amount),
              style: AiraFonts.numeric(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AiraColors.charcoal,
                letterSpacing: -1.0,
              ),
            ),
            loading: () => Text(
              '...',
              style: AiraFonts.numeric(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AiraColors.charcoal,
                letterSpacing: -1.0,
              ),
            ),
            error: (e, s) => Text(
              _t(isThai, 'โหลดไม่สำเร็จ', 'Unavailable'),
              style: AiraFonts.label(fontSize: 13, color: AiraColors.terra),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(isThai, 'เทียบกับสัปดาห์ที่แล้ว', 'Compared to last week'),
            style: AiraFonts.label(fontSize: 11, color: AiraColors.muted),
          ),
        ],
      ),
    );
  }
}

class _FollowUpCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final followUpsAsync = ref.watch(upcomingFollowUpsProvider);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AiraColors.gold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AiraColors.gold.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AiraColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AiraColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _t(isThai, 'ติดตามผลสัปดาห์นี้', 'This Week\'s Follow-ups'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AiraColors.muted,
                ),
              ),
              const Spacer(),
              followUpsAsync.when(
                data: (items) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AiraColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    context.l10n.nPatients(items.length),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AiraColors.gold,
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, s) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          followUpsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return Text(
                  _t(isThai, 'ยังไม่มีรายการติดตามผลที่รอดำเนินการ', 'No pending follow-ups right now.'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted),
                );
              }
              return Column(
                children: items.take(4).map((item) {
                  final dateLabel = item.followUpDate == null
                      ? _t(isThai, 'ยังไม่ระบุวัน', 'Date pending')
                      : _followUpRelative(item.followUpDate!, context.l10n);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FollowUpRow(item.treatmentName, item.notes ?? _t(isThai, 'รอติดตามอาการ', 'Pending follow-up note'), dateLabel),
                  );
                }).toList(),
              );
            },
            loading: () => const _DashboardCardSkeleton(height: 86),
            error: (e, s) => Text(
              _t(isThai, 'โหลดติดตามผลไม่สำเร็จ', 'Failed to load follow-ups'),
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.terra),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryAlertCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final lowStockAsync = ref.watch(lowStockAlertsProvider);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AiraColors.terra.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AiraColors.terra.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: lowStockAsync.when(
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AiraColors.terra.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: AiraColors.terra, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t(isThai, 'สินค้าสต็อกต่ำ', 'Low Stock Alerts'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              Text(
                _t(isThai, 'ยังไม่มีสินค้าที่ต่ำกว่าเกณฑ์แจ้งเตือน', 'No products are currently below alert threshold.'),
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted),
              ),
            ...items.take(3).map((product) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoal),
                        ),
                      ),
                      Text(
                        '${product.stockQuantity.toStringAsFixed(product.stockQuantity == product.stockQuantity.roundToDouble() ? 0 : 1)} ${product.unit}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AiraColors.terra),
                      ),
                    ],
                  ),
                )),
          ],
        ),
        loading: () => const _DashboardCardSkeleton(height: 116),
        error: (e, s) => Text(
          _t(isThai, 'โหลดสต็อกไม่สำเร็จ', 'Failed to load inventory alerts'),
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.terra),
        ),
      ),
    );
  }
}

class _ExpiryAlertCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final expiryAsync = ref.watch(expiringProductsProvider);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AiraColors.gold.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AiraColors.gold.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: expiryAsync.when(
        data: (items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AiraColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.schedule_rounded, color: AiraColors.gold, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _t(isThai, 'สินค้าใกล้หมดอายุ / หมดอายุ', 'Expiring / Expired Products'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                  ),
                ),
                if (items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AiraColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${items.length}',
                      style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AiraColors.danger),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              Text(
                _t(isThai, 'ไม่มีสินค้าหมดอายุหรือใกล้หมดอายุภายใน 30 วัน', 'No products expiring within 30 days.'),
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted),
              ),
            ...items.take(5).map((product) {
              final isExpired = product.isExpired;
              final daysLeft = product.expiryDate!.difference(DateTime.now()).inDays;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      isExpired ? Icons.error_rounded : Icons.warning_amber_rounded,
                      size: 14,
                      color: isExpired ? AiraColors.danger : AiraColors.gold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        product.name,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoal),
                      ),
                    ),
                    Text(
                      isExpired
                          ? _t(isThai, 'หมดอายุแล้ว', 'Expired')
                          : _t(isThai, 'อีก $daysLeft วัน', '${daysLeft}d left'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isExpired ? AiraColors.danger : AiraColors.gold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        loading: () => const _DashboardCardSkeleton(height: 116),
        error: (e, s) => Text(
          _t(isThai, 'โหลดข้อมูลวันหมดอายุไม่สำเร็จ', 'Failed to load expiry data'),
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.terra),
        ),
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _DashboardEmptyState({required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AiraColors.creamDk),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AiraColors.cream,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: AiraColors.muted),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.45, color: AiraColors.muted),
          ),
        ],
      ),
    );
  }
}

class _DashboardSectionLoading extends StatelessWidget {
  final int itemCount;
  const _DashboardSectionLoading({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: _DashboardCardSkeleton(height: 96),
        ),
      ),
    );
  }
}

class _DashboardCardSkeleton extends StatelessWidget {
  final double height;
  const _DashboardCardSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AiraColors.creamDk),
      ),
    );
  }
}

String _formatDashboardAmount(double amount) {
  final rounded = amount.round();
  final raw = rounded.toString();
  final formatted = raw.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  return '฿ $formatted';
}

String _followUpRelative(DateTime date, AppL10n l) {
  final today = DateTime.now();
  final startToday = DateTime(today.year, today.month, today.day);
  final startTarget = DateTime(date.year, date.month, date.day);
  final diff = startTarget.difference(startToday).inDays;
  if (diff == 0) return l.today;
  if (diff == 1) return l.tomorrow;
  if (diff > 1) return l.inDays(diff);
  final overdue = diff.abs();
  return l.overdueDays(overdue);
}

class _FollowUpRow extends StatelessWidget {
  final String name, treatment, when;
  const _FollowUpRow(this.name, this.treatment, this.when);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AiraColors.gold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AiraColors.charcoal,
                ),
              ),
              Text(
                treatment,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AiraColors.muted,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AiraColors.woodWash.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            when,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AiraColors.woodDk,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PATIENT SEARCH BAR — ค้นหาจากชื่อ ชื่อเล่น เบอร์ บัตรประชาชน
// ═══════════════════════════════════════════════════════════════════
class _PatientSearchBar extends ConsumerStatefulWidget {
  const _PatientSearchBar();

  @override
  ConsumerState<_PatientSearchBar> createState() => _PatientSearchBarState();
}

class _PatientSearchBarState extends ConsumerState<_PatientSearchBar> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _showResults = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(_dashSearchResultsProvider);
    final isThai = ref.watch(isThaiProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AiraColors.creamDk),
            boxShadow: [
              BoxShadow(
                color: AiraColors.woodDk.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: AiraColors.charcoal,
            ),
            decoration: InputDecoration(
              hintText: _t(
                isThai,
                'ค้นหาคนไข้ — ชื่อ, ชื่อเล่น, เบอร์, บัตร ปชช.',
                'Search patient — name, nickname, phone, ID card',
              ),
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AiraColors.muted.withValues(alpha: 0.6),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AiraColors.woodMid,
                size: 22,
              ),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _ctrl.clear();
                        ref.read(_dashSearchQueryProvider.notifier).state = '';
                        setState(() => _showResults = false);
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (v) {
              ref.read(_dashSearchQueryProvider.notifier).state = v;
              setState(() => _showResults = v.trim().length >= 2);
            },
          ),
        ),

        // Dropdown results
        if (_showResults)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AiraColors.creamDk),
              boxShadow: [
                BoxShadow(
                  color: AiraColors.woodDk.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: resultsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_t(isThai, 'เกิดข้อผิดพลาด: $e', 'Error: $e'),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AiraColors.terra)),
              ),
              data: (patients) {
                if (patients.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        _t(isThai, 'ไม่พบคนไข้', 'No patients found'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AiraColors.muted,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: patients.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: AiraColors.creamDk.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, i) {
                    final p = patients[i];
                    final hasAllergy = p.drugAllergies.isNotEmpty;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            AiraColors.woodPale.withValues(alpha: 0.3),
                        child: Text(
                          p.firstName.isEmpty ? '?' : p.firstName[0],
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AiraColors.woodDk,
                          ),
                        ),
                      ),
                      title: Text(
                        '${p.firstName} ${p.lastName}'.trim().isEmpty
                            ? _t(isThai, 'ไม่ระบุชื่อ', 'Unnamed patient')
                            : '${p.firstName} ${p.lastName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AiraColors.charcoal,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.nickname != null && p.nickname!.isNotEmpty)
                            Text(
                              '${_t(isThai, 'ชื่อเล่น', 'Nickname')}: ${p.nickname}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AiraColors.muted,
                              ),
                            ),
                          if (hasAllergy)
                            Text(
                              '⚠ ${_t(isThai, 'แพ้', 'Allergy')}: ${p.drugAllergies.join(", ")}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AiraColors.danger,
                              ),
                            ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AiraColors.muted,
                      ),
                      onTap: () {
                        _ctrl.clear();
                        ref.read(_dashSearchQueryProvider.notifier).state = '';
                        setState(() => _showResults = false);
                        _focusNode.unfocus();
                        context.push('/patients/${p.id}');
                      },
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
