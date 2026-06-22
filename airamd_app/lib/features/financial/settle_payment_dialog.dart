import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/localization/app_localizations.dart';

// ═══════════════════════════════════════════════════════════════════
// showSettlePaymentDialog — shared partial/full payment dialog used by
// both the patient Spending tab and the global Financial screen.
//
// • Default amount = outstanding remaining (one tap to pay in full).
// • Amount field is editable for partial payments.
// • Payment method chip picker (CASH / TRANSFER / CREDIT_CARD / DEBIT).
// • Calls settle_charge RPC (atomic, concurrency-safe, migration 028).
// • Invalidates all relevant providers so every page refreshes immediately.
// ═══════════════════════════════════════════════════════════════════

Future<void> showSettlePaymentDialog(
  BuildContext context,
  WidgetRef ref,
  FinancialRecord charge,
) async {
  final remaining = charge.outstandingRemaining;
  if (remaining <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.l10n.isThai ? 'รายการนี้ชำระครบแล้ว' : 'Already fully settled'),
      backgroundColor: AiraColors.sage,
    ));
    return;
  }

  final amountCtrl = TextEditingController(text: remaining.toStringAsFixed(0));
  final methodNotifier = ValueNotifier<PaymentMethod>(PaymentMethod.cash);
  final messenger = ScaffoldMessenger.of(context);
  // Capture every localized value up front so the dialog builder performs
  // NO inherited-widget lookups (calling context.l10n inside the builder
  // registers the wrong element as a dependent and trips the
  // InheritedElement._dependents.isEmpty assertion on teardown).
  final l = context.l10n;
  final isThai = l.isThai;
  final cancelLabel = l.cancel;
  final fmt = NumberFormat('#,##0');

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ValueListenableBuilder<PaymentMethod>(
      valueListenable: methodNotifier,
      builder: (ctx, method, _) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AiraColors.sage.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.payments_rounded, color: AiraColors.sage, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              isThai ? 'รับชำระ' : 'Record Payment',
              style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (charge.description != null) ...[
                const SizedBox(height: 10),
                Text(
                  charge.description!,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.charcoal),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 14),
              // ─── Outstanding summary ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AiraColors.terra.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AiraColors.terra.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isThai ? 'ยอดค้างชำระ' : 'Outstanding',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.terra),
                    ),
                    Text(
                      '฿${fmt.format(remaining)}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w800, color: AiraColors.terra),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // ─── Amount input ───
              Text(
                isThai ? 'จำนวนที่รับชำระ' : 'Payment Amount',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoal),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        prefixText: '฿ ',
                        prefixStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AiraColors.creamDk),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AiraColors.woodMid, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      amountCtrl.text = remaining.toStringAsFixed(0);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AiraColors.sage,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    child: Text(
                      isThai ? 'เต็ม' : 'Full',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ─── Payment method ───
              Text(
                isThai ? 'วิธีชำระ' : 'Payment Method',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoal),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: PaymentMethod.values.map((m) {
                  final selected = method == m;
                  final label = switch (m) {
                    PaymentMethod.cash => 'เงินสด',
                    PaymentMethod.transfer => 'โอน',
                    PaymentMethod.creditCard => 'บัตรเครดิต',
                    PaymentMethod.debit => 'เดบิต',
                    PaymentMethod.other => 'อื่นๆ',
                  };
                  return GestureDetector(
                    onTap: () => methodNotifier.value = m,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AiraColors.woodDk.withValues(alpha: 0.1)
                            : AiraColors.creamDk.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AiraColors.woodDk : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          color: selected ? AiraColors.woodDk : AiraColors.muted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel, style: const TextStyle(color: AiraColors.muted)),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check_rounded, size: 16),
            label: Text(
              isThai ? 'รับชำระ' : 'Receive',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(backgroundColor: AiraColors.sage),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    ),
  );

  // Capture values before disposing controllers.
  final amountText = amountCtrl.text;
  final selectedMethod = methodNotifier.value;
  amountCtrl.dispose();
  methodNotifier.dispose();

  if (confirmed != true) return;

  final amount = double.tryParse(amountText.trim().replaceAll(',', '')) ?? 0;
  if (amount <= 0) return;

  try {
    await ref.read(financialRepoProvider).settleCharge(
          charge.id,
          amount,
          selectedMethod.dbValue,
        );

    // ─── Centralised invalidation — refresh every relevant view ───
    ref.invalidate(financialListProvider);
    ref.invalidate(outstandingRecordsProvider);
    ref.invalidate(todayRevenueAmountProvider);
    ref.invalidate(todayRevenueProvider);
    ref.invalidate(revenueTrendProvider);
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(financialsByPatientProvider(charge.patientId));
    ref.invalidate(patientBalanceProvider(charge.patientId));

    final fullyPaid = amount >= remaining;
    messenger.showSnackBar(SnackBar(
      content: Text(fullyPaid
          ? (isThai ? 'ชำระครบแล้ว ✓' : 'Fully settled ✓')
          : (isThai
              ? 'บันทึกการชำระ ฿${NumberFormat('#,##0').format(amount)} สำเร็จ'
              : 'Payment of ฿${NumberFormat('#,##0').format(amount)} recorded')),
      backgroundColor: AiraColors.sage,
    ));
  } catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text(isThai ? 'เกิดข้อผิดพลาด: $e' : 'Error: $e'),
      backgroundColor: AiraColors.terra,
    ));
  }
}
