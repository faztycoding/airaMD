import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/aira_premium_form.dart';
import '../../core/localization/app_localizations.dart';

/// Active tab for financial screen.
final _finTabProvider = StateProvider<int>((ref) => 0);

class FinancialScreen extends ConsumerWidget {
  const FinancialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_finTabProvider);

    return Scaffold(
      backgroundColor: AiraColors.cream,
      appBar: AppBar(
        title: Builder(builder: (ctx) => Text(ctx.l10n.financial)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'บันทึกรายการใหม่',
            onPressed: () => _showAddRecordDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary cards
          _SummaryCards(),
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _TabChip('ทั้งหมด', 0, tab, ref),
                const SizedBox(width: 8),
                _TabChip('ค้างชำระ', 1, tab, ref),
                const SizedBox(width: 8),
                _TabChip('วันนี้', 2, tab, ref),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // List
          Expanded(
            child: tab == 1
                ? _OutstandingList()
                : _AllRecordsList(todayOnly: tab == 2),
          ),
        ],
      ),
    );
  }

  void _showAddRecordDialog(BuildContext context, WidgetRef ref) {
    final typeNotifier = ValueNotifier<FinancialType>(FinancialType.payment);
    final methodNotifier = ValueNotifier<PaymentMethod>(PaymentMethod.cash);
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedPatientId;
    final patients = ref.read(patientListProvider).valueOrNull ?? [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: AiraColors.cream,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium dialog header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF3D2517), Color(0xFF5A3E2B), Color(0xFF7B5840)]),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(children: [
                    Icon(Icons.account_balance_wallet_rounded, size: 22, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(
                      'บันทึกรายการเงิน',
                      style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    )),
                    AiraTapEffect(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close_rounded, size: 20, color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ]),
                ),
                // Form content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Patient dropdown
                        DropdownButtonFormField<String>(
                          value: selectedPatientId,
                          style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(label: 'ผู้รับบริการ *', prefixIcon: Icons.person_rounded),
                          items: patients.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.firstName} ${p.lastName}', overflow: TextOverflow.ellipsis, style: airaFieldTextStyle),
                          )).toList(),
                          onChanged: (v) => setDialogState(() => selectedPatientId = v),
                        ),
                        const SizedBox(height: 14),
                        // Type
                        ValueListenableBuilder<FinancialType>(
                          valueListenable: typeNotifier,
                          builder: (_, type, child) => DropdownButtonFormField<FinancialType>(
                            value: type,
                            style: airaFieldTextStyle,
                            decoration: airaFieldDecoration(label: 'ประเภท', prefixIcon: Icons.receipt_long_rounded),
                            items: FinancialType.values.map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(_typeLabel(t), style: airaFieldTextStyle),
                            )).toList(),
                            onChanged: (v) { if (v != null) typeNotifier.value = v; },
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Amount
                        TextField(
                          controller: amountCtrl,
                          style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(label: 'จำนวนเงิน (฿) *', hint: '0.00', prefixIcon: Icons.payments_rounded),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 14),
                        // Payment method
                        ValueListenableBuilder<PaymentMethod>(
                          valueListenable: methodNotifier,
                          builder: (_, method, child) => DropdownButtonFormField<PaymentMethod>(
                            value: method,
                            style: airaFieldTextStyle,
                            decoration: airaFieldDecoration(label: 'วิธีชำระ', prefixIcon: Icons.credit_card_rounded),
                            items: PaymentMethod.values.map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(_methodLabel(m), style: airaFieldTextStyle),
                            )).toList(),
                            onChanged: (v) { if (v != null) methodNotifier.value = v; },
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Description
                        TextField(
                          controller: descCtrl,
                          style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(label: 'รายละเอียด', hint: 'เช่น ค่า Botox Forehead', prefixIcon: Icons.notes_rounded),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: Row(children: [
                    Expanded(
                      child: AiraTapEffect(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(color: AiraColors.creamDk, borderRadius: BorderRadius.circular(14)),
                          child: Center(child: Text(context.l10n.cancel, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.muted))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AiraTapEffect(
                        onTap: () async {
                          if (selectedPatientId == null || amountCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.pleaseFillRequired)),
                            );
                            return;
                          }
                          final clinicId = ref.read(currentClinicIdProvider);
                          if (clinicId == null) return;

                          final record = FinancialRecord(
                            id: const Uuid().v4(),
                            clinicId: clinicId,
                            patientId: selectedPatientId!,
                            type: typeNotifier.value,
                            amount: double.tryParse(amountCtrl.text.trim()) ?? 0,
                            paymentMethod: methodNotifier.value,
                            description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                            isOutstanding: typeNotifier.value == FinancialType.charge,
                          );

                          try {
                            await ref.read(financialRepoProvider).create(record);
                            ref.invalidate(financialListProvider);
                            ref.invalidate(outstandingRecordsProvider);
                            ref.invalidate(todayRevenueAmountProvider);
                            ref.invalidate(dashboardStatsProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(context.l10n.saveSuccess), backgroundColor: AiraColors.sage),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(context.l10n.errorMsg('$e')), backgroundColor: AiraColors.terra),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF3D2517), Color(0xFF6B4F3A), Color(0xFF8B6650)]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(context.l10n.save, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _typeLabel(FinancialType t) {
    switch (t) {
      case FinancialType.charge: return 'เรียกเก็บ (Charge)';
      case FinancialType.payment: return 'ชำระเงิน (Payment)';
      case FinancialType.refund: return 'คืนเงิน (Refund)';
      case FinancialType.adjustment: return 'ปรับปรุง (Adjustment)';
    }
  }

  static String _methodLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash: return 'เงินสด';
      case PaymentMethod.transfer: return 'โอน';
      case PaymentMethod.creditCard: return 'บัตรเครดิต';
      case PaymentMethod.debit: return 'บัตรเดบิต';
      case PaymentMethod.other: return 'อื่นๆ';
    }
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final int index;
  final int current;
  final WidgetRef ref;
  const _TabChip(this.label, this.index, this.current, this.ref);

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return AiraTapEffect(
      onTap: () => ref.read(_finTabProvider.notifier).state = index,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AiraColors.woodDk : AiraColors.woodWash.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: active ? Colors.white : AiraColors.charcoal,
        )),
      ),
    );
  }
}

class _SummaryCards extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueAsync = ref.watch(todayRevenueAmountProvider);
    final outstandingAsync = ref.watch(outstandingRecordsProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(child: _SummaryCard(
            title: 'รายได้วันนี้',
            icon: Icons.trending_up_rounded,
            color: AiraColors.sage,
            value: revenueAsync.when(
              loading: () => '-',
              error: (e, s) => '!',
              data: (v) => '฿${NumberFormat('#,##0').format(v)}',
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(
            title: 'ค้างชำระ',
            icon: Icons.warning_amber_rounded,
            color: AiraColors.gold,
            value: outstandingAsync.when(
              loading: () => '-',
              error: (e, s) => '!',
              data: (records) {
                final total = records.fold<double>(0, (sum, r) => sum + r.amount);
                return '฿${NumberFormat('#,##0').format(total)}';
              },
            ),
          )),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard(
            title: 'รายการค้าง',
            icon: Icons.receipt_long_rounded,
            color: AiraColors.terra,
            value: outstandingAsync.when(
              loading: () => '-',
              error: (e, s) => '!',
              data: (records) => '${records.length}',
            ),
          )),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AiraShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted))),
          ]),
          const SizedBox(height: 8),
          Text(value, style: AiraFonts.numeric(fontSize: 22, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
        ],
      ),
    );
  }
}

class _AllRecordsList extends ConsumerWidget {
  final bool todayOnly;
  const _AllRecordsList({this.todayOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(financialListProvider);

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text(context.l10n.errorMsg('$e'))),
      data: (records) {
        var filtered = records;
        if (todayOnly) {
          final today = DateTime.now();
          filtered = records.where((r) =>
              r.createdAt != null &&
              r.createdAt!.year == today.year &&
              r.createdAt!.month == today.month &&
              r.createdAt!.day == today.day).toList();
        }

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_rounded, size: 48, color: AiraColors.muted.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(context.l10n.noTransactions, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AiraColors.muted)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: filtered.length,
          separatorBuilder: (_, i2) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _FinancialRecordCard(record: filtered[i]),
        );
      },
    );
  }
}

class _OutstandingList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(outstandingRecordsProvider);

    return recordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text(context.l10n.errorMsg('$e'))),
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 48, color: AiraColors.sage.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(context.l10n.noOutstanding, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AiraColors.muted)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: records.length,
          separatorBuilder: (_, i2) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _FinancialRecordCard(record: records[i], showPayButton: true),
        );
      },
    );
  }
}

class _FinancialRecordCard extends ConsumerWidget {
  final FinancialRecord record;
  final bool showPayButton;
  const _FinancialRecordCard({required this.record, this.showPayButton = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientByIdProvider(record.patientId));
    final isIncome = record.type == FinancialType.payment;
    final isCharge = record.type == FinancialType.charge;

    return AiraTapEffect(
      onTap: () => _showReceiptDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isIncome ? AiraColors.sage : isCharge ? AiraColors.gold : AiraColors.terra).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isIncome ? Icons.arrow_downward_rounded : isCharge ? Icons.arrow_upward_rounded : Icons.swap_horiz_rounded,
                    size: 18,
                    color: isIncome ? AiraColors.sage : isCharge ? AiraColors.gold : AiraColors.terra,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      patientAsync.when(
                        loading: () => Text('...', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                        error: (e, s) => Text('?', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                        data: (p) => Text(
                          p != null ? '${p.firstName} ${p.lastName}' : '-',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.charcoal),
                        ),
                      ),
                      if (record.description != null)
                        Text(record.description!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted)),
                      if (record.createdAt != null)
                        Text(
                          DateFormat('dd/MM/yy HH:mm').format(record.createdAt!),
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AiraColors.muted.withValues(alpha: 0.6)),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isIncome ? '+' : isCharge ? '-' : ''}฿${NumberFormat('#,##0').format(record.amount)}',
                      style: AiraFonts.numeric(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: isIncome ? AiraColors.sage : isCharge ? AiraColors.terra : AiraColors.charcoal,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: (isIncome ? AiraColors.sage : isCharge ? AiraColors.gold : AiraColors.woodMid).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _typeShort(record.type),
                        style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700,
                          color: isIncome ? AiraColors.sage : isCharge ? AiraColors.gold : AiraColors.woodMid),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Mark as Paid button for outstanding charges
            if (showPayButton && record.isOutstanding) ...[
              const SizedBox(height: 10),
              AiraTapEffect(
                onTap: () => _markAsPaid(context, ref),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AiraColors.sage.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AiraColors.sage.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 16, color: AiraColors.sage),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.isThai ? 'รับชำระแล้ว' : 'Mark as Paid',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AiraColors.sage),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _markAsPaid(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(context.l10n.isThai ? 'ยืนยันรับชำระ' : 'Confirm Payment'),
        content: Text(
          context.l10n.isThai
              ? 'ยืนยันว่าได้รับชำระเงิน ฿${NumberFormat('#,##0').format(record.amount)} แล้ว?'
              : 'Confirm payment of ฿${NumberFormat('#,##0').format(record.amount)} received?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(context.l10n.confirm, style: TextStyle(color: AiraColors.sage, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(financialRepoProvider).markAsPaid(record.id);
      // Create a matching payment record
      final clinicId = ref.read(currentClinicIdProvider);
      if (clinicId != null) {
        final paymentRecord = FinancialRecord(
          id: const Uuid().v4(),
          clinicId: clinicId,
          patientId: record.patientId,
          treatmentRecordId: record.treatmentRecordId,
          courseId: record.courseId,
          type: FinancialType.payment,
          amount: record.amount,
          paymentMethod: PaymentMethod.cash,
          description: record.description != null ? 'ชำระ: ${record.description}' : 'ชำระยอดค้าง',
          isOutstanding: false,
        );
        await ref.read(financialRepoProvider).create(paymentRecord);
      }
      ref.invalidate(financialListProvider);
      ref.invalidate(outstandingRecordsProvider);
      ref.invalidate(todayRevenueAmountProvider);
      ref.invalidate(dashboardStatsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.isThai ? 'บันทึกการรับชำระสำเร็จ' : 'Payment recorded'),
            backgroundColor: AiraColors.sage,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saveFailed('$e')), backgroundColor: AiraColors.terra),
        );
      }
    }
  }

  void _showReceiptDialog(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.read(patientByIdProvider(record.patientId));
    final patientName = patientAsync.valueOrNull;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Receipt header
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AiraColors.woodWash.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long_rounded, size: 28, color: AiraColors.woodMid),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.isThai ? 'รายละเอียดรายการ' : 'Transaction Detail',
                  style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                ),
                const SizedBox(height: 20),
                // Details
                _ReceiptRow(context.l10n.isThai ? 'ประเภท' : 'Type', _typeLabel(record.type)),
                _ReceiptRow(context.l10n.isThai ? 'จำนวนเงิน' : 'Amount', '฿${NumberFormat('#,##0.00').format(record.amount)}'),
                if (patientName != null) _ReceiptRow(context.l10n.patient, '${patientName.firstName} ${patientName.lastName}'),
                if (record.paymentMethod != null) _ReceiptRow(context.l10n.isThai ? 'วิธีชำระ' : 'Method', _methodName(record.paymentMethod!)),
                if (record.description != null) _ReceiptRow(context.l10n.isThai ? 'รายละเอียด' : 'Description', record.description!),
                _ReceiptRow(context.l10n.status, record.isOutstanding ? (context.l10n.isThai ? 'ค้างชำระ' : 'Outstanding') : (context.l10n.isThai ? 'ชำระแล้ว' : 'Paid')),
                if (record.createdAt != null) _ReceiptRow(context.l10n.isThai ? 'วันที่' : 'Date', DateFormat('dd/MM/yyyy HH:mm').format(record.createdAt!)),
                const SizedBox(height: 20),
                Divider(color: AiraColors.creamDk),
                const SizedBox(height: 12),
                Text(
                  'airaMD Clinic System',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AiraColors.muted.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 16),
                AiraTapEffect(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: AiraColors.creamDk, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(context.l10n.close, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.charcoal))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _typeLabel(FinancialType t) {
    switch (t) {
      case FinancialType.charge: return 'Charge (เรียกเก็บ)';
      case FinancialType.payment: return 'Payment (ชำระ)';
      case FinancialType.refund: return 'Refund (คืนเงิน)';
      case FinancialType.adjustment: return 'Adjustment (ปรับปรุง)';
    }
  }

  static String _methodName(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash: return 'เงินสด';
      case PaymentMethod.transfer: return 'โอน';
      case PaymentMethod.creditCard: return 'บัตรเครดิต';
      case PaymentMethod.debit: return 'บัตรเดบิต';
      case PaymentMethod.other: return 'อื่นๆ';
    }
  }

  String _typeShort(FinancialType t) {
    switch (t) {
      case FinancialType.charge: return 'CHARGE';
      case FinancialType.payment: return 'PAYMENT';
      case FinancialType.refund: return 'REFUND';
      case FinancialType.adjustment: return 'ADJUST';
    }
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label, value;
  const _ReceiptRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.charcoal)),
          ),
        ],
      ),
    );
  }
}
