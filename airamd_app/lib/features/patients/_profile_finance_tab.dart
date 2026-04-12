part of 'patient_profile_screen.dart';

// ═══════════════════════════════════════════════════════════════════
// TAB 8: ศัลยกรรม (Surgery) — Surgery history with timeline
// ═══════════════════════════════════════════════════════════════════

class _SurgeryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          title: 'ประวัติศัลยกรรม',
          icon: Icons.favorite_rounded,
          iconColor: AiraColors.terra,
          children: [
            _SurgeryItem('Rhinoplasty tip', 'ปลายจมูก/แม่พิมพ์', ['<1 เดือน', '1-3 เดือน', '3-6 เดือน', '6-12 เดือน', '1-2 ปี', '>5 ปี']),
            const Divider(height: 24),
            _SurgeryItem('Double Eyelid', 'ตัดชั้นตาสองชั้น', ['<1 เดือน', '1-3 เดือน', '3-6 เดือน', '6-12 เดือน', '1-2 ปี', '>2 ปี']),
          ],
        ),
      ],
    );
  }
}

class _SurgeryItem extends StatelessWidget {
  final String name;
  final String desc;
  final List<String> timeline;
  const _SurgeryItem(this.name, this.desc, this.timeline);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_rounded, size: 14, color: AiraColors.terra),
            const SizedBox(width: 6),
            Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: timeline.asMap().entries.map((e) {
            final isLast = e.key == timeline.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isLast ? AiraColors.terra.withValues(alpha: 0.12) : AiraColors.parchment,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLast ? AiraColors.terra.withValues(alpha: 0.3) : AiraColors.woodPale.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                e.value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
                  color: isLast ? AiraColors.terra : AiraColors.muted,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text('❤️ $desc', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.terra)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 9: ค่าใช้จ่าย (Finance) — Courses + Payments
// ═══════════════════════════════════════════════════════════════════

class _FinanceTab extends ConsumerWidget {
  final String patientId;
  const _FinanceTab({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesByPatientProvider(patientId));
    final financialsAsync = ref.watch(financialsByPatientProvider(patientId));

    return coursesAsync.when(
      data: (courses) => financialsAsync.when(
        data: (records) {
          final remainingSessions = courses.fold<int>(0, (sum, course) => sum + course.sessionsRemaining);
          final outstanding = records.where((record) => record.isOutstanding).toList();
          final outstandingTotal = outstanding.fold<double>(0, (sum, record) => sum + record.amount);
          final activeCourses = courses.where((course) => course.status != CourseStatus.completed).toList();
          final history = [...records]
            ..sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(child: _FinStatCard('${courses.length}', 'คอร์สทั้งหมด', AiraColors.woodMid)),
                  const SizedBox(width: 10),
                  Expanded(child: _FinStatCard('$remainingSessions', 'เซสชั่นคงเหลือ', AiraColors.sage)),
                  const SizedBox(width: 10),
                  Expanded(child: _FinStatCard('฿${_formatAmount(outstandingTotal)}', 'ยอดค้างชำระ', AiraColors.woodDk)),
                ],
              ),
              const SizedBox(height: 20),
              AiraTapEffect(
                onTap: () => context.push('/courses?patientId=$patientId'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AiraColors.woodPale.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.4)),
                  ),
                  child: Center(
                    child: Text(
                      '+ เปิดจัดการคอร์ส',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.woodDk),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 16, color: AiraColors.woodDk),
                  const SizedBox(width: 6),
                  Text(context.l10n.patientCourses, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
                ],
              ),
              const SizedBox(height: 12),
              if (activeCourses.isEmpty)
                _SectionCard(
                  title: 'ยังไม่มีคอร์ส',
                  children: [
                    Text(context.l10n.noCoursesYet, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
                  ],
                ),
              ...activeCourses.map((course) {
                final total = course.sessionsTotal ?? (course.sessionsBought + course.sessionsBonus);
                final detail = 'ซื้อ ${course.sessionsBought} แถม ${course.sessionsBonus}'
                    '${course.expiryDate != null ? ' • ครบกำหนด ${_formatDate(course.expiryDate)}' : ' • ไม่กำหนดวันหมดอายุ'}'
                    '${course.price != null ? ' • ฿${_formatAmount(course.price!)}' : ''}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CourseCard(
                    name: course.name,
                    detail: detail,
                    sessionsTotal: total,
                    sessionsUsed: course.sessionsUsed,
                    color: _courseColor(course.status),
                    statusLabel: _courseStatusLabel(course.status),
                  ),
                );
              }),
              const SizedBox(height: 24),
              _SectionCard(
                title: 'ยอดค้างชำระ',
                icon: Icons.warning_amber_rounded,
                iconColor: AiraColors.terra,
                children: [
                  if (outstanding.isEmpty)
                    Text(context.l10n.noOutstanding, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
                  ...outstanding.map((record) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OutstandingItem(
                          record.description ?? _financialTypeLabel(record.type),
                          '${_formatDate(record.createdAt)} • ยังไม่ชำระ',
                          record.amount,
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.history_rounded, size: 16, color: AiraColors.woodDk),
                  const SizedBox(width: 6),
                  Text(context.l10n.paymentHistory, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
                ],
              ),
              const SizedBox(height: 12),
              if (history.isEmpty)
                _SectionCard(
                  title: 'ยังไม่มีประวัติการเงิน',
                  children: [
                    Text(context.l10n.paymentWillShowHere, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
                  ],
                ),
              ...history.take(12).map((record) => _PaymentHistoryItem(
                    _financialIcon(record.type),
                    record.description ?? _financialTypeLabel(record.type),
                    '${_formatDate(record.createdAt)}${record.paymentMethod != null ? ' • ${_paymentMethodLabel(record.paymentMethod!)}' : ''}',
                    record.amount,
                    _financialColor(record),
                  )),
              const SizedBox(height: 40),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Color _courseColor(CourseStatus status) {
    switch (status) {
      case CourseStatus.completed:
        return AiraColors.sage;
      case CourseStatus.low:
        return AiraColors.gold;
      case CourseStatus.expired:
        return AiraColors.terra;
      case CourseStatus.active:
        return AiraColors.woodMid;
    }
  }

  String _courseStatusLabel(CourseStatus status) {
    switch (status) {
      case CourseStatus.completed:
        return 'ครบแล้ว';
      case CourseStatus.low:
        return 'ใกล้หมด';
      case CourseStatus.expired:
        return 'หมดอายุ';
      case CourseStatus.active:
        return 'ใช้อยู่';
    }
  }

  IconData _financialIcon(FinancialType type) {
    switch (type) {
      case FinancialType.payment:
        return Icons.payments_rounded;
      case FinancialType.refund:
        return Icons.reply_rounded;
      case FinancialType.adjustment:
        return Icons.tune_rounded;
      case FinancialType.charge:
        return Icons.receipt_long_rounded;
    }
  }

  Color _financialColor(FinancialRecord record) {
    if (record.isOutstanding) return AiraColors.terra;
    switch (record.type) {
      case FinancialType.payment:
        return AiraColors.sage;
      case FinancialType.refund:
        return AiraColors.gold;
      case FinancialType.adjustment:
        return AiraColors.woodMid;
      case FinancialType.charge:
        return AiraColors.woodDk;
    }
  }

  String _financialTypeLabel(FinancialType type) {
    switch (type) {
      case FinancialType.payment:
        return 'รับชำระ';
      case FinancialType.refund:
        return 'คืนเงิน';
      case FinancialType.adjustment:
        return 'ปรับปรุงยอด';
      case FinancialType.charge:
        return 'ค่าใช้จ่าย';
    }
  }

  String _paymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'เงินสด';
      case PaymentMethod.transfer:
        return 'โอนเงิน';
      case PaymentMethod.creditCard:
        return 'บัตรเครดิต';
      case PaymentMethod.debit:
        return 'บัตรเดบิต';
      case PaymentMethod.other:
        return 'อื่นๆ';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'ไม่ระบุวันที่';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

class _FinStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _FinStatCard(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final String name;
  final String detail;
  final int sessionsTotal;
  final int sessionsUsed;
  final Color color;
  final String statusLabel;
  const _CourseCard({
    required this.name, required this.detail,
    required this.sessionsTotal, required this.sessionsUsed,
    required this.color, required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = sessionsTotal <= 0 ? 1 : sessionsTotal;
    final remaining = (sessionsTotal - sessionsUsed) < 0 ? 0 : (sessionsTotal - sessionsUsed);
    final progress = (sessionsUsed / safeTotal).clamp(0, 1).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(statusLabel, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(detail, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted)),
          const SizedBox(height: 12),
          // ─── Session dots ───
          Row(
            children: List.generate(sessionsTotal, (i) {
              final used = i < sessionsUsed;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${i + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: used ? color : AiraColors.muted.withValues(alpha: 0.4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // ─── Progress bar ───
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AiraColors.creamDk,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.sessionCount(sessionsUsed, sessionsTotal), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted)),
              Text(context.l10n.remainingSessions(remaining), style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutstandingItem extends StatelessWidget {
  final String name;
  final String detail;
  final double amount;
  const _OutstandingItem(this.name, this.detail, this.amount);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.charcoal)),
              Text(detail, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted)),
            ],
          ),
        ),
        Text(
          '฿${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
          style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: AiraColors.terra),
        ),
      ],
    );
  }
}

class _PaymentHistoryItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final String detail;
  final double amount;
  final Color color;
  const _PaymentHistoryItem(this.icon, this.name, this.detail, this.amount, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.charcoal)),
                Text(detail, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted)),
              ],
            ),
          ),
          Text(
            '฿${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
            style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED COMPONENTS
// ═══════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final List<Widget> children;
  const _SectionCard({required this.title, this.icon, this.iconColor, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: iconColor ?? AiraColors.woodDk),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

