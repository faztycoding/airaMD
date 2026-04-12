part of 'dashboard_screen.dart';

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
