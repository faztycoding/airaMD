part of 'dashboard_screen.dart';

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

