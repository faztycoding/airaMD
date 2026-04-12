part of 'dashboard_screen.dart';

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

