import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_empty_state.dart';
import '../../core/widgets/aira_feedback.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/aira_premium_form.dart';
import '../../core/services/audit_service.dart';
import '../../core/localization/app_localizations.dart';
import 'inventory_validation.dart';

// ─── Providers ────────────────────────────────────────────────
final _invProductIdProvider = StateProvider<String?>((ref) => null);

final _inventoryTxProvider =
    FutureProvider.family<List<InventoryTransaction>, String>((ref, productId) {
  final repo = ref.watch(inventoryRepoProvider);
  return repo.getByProduct(productId: productId, limit: 50);
});

// ═══════════════════════════════════════════════════════════════
// INVENTORY MANAGEMENT SCREEN
// ═══════════════════════════════════════════════════════════════
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final selectedProductId = ref.watch(_invProductIdProvider);

    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          // ─── Header ───
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B4F3A), Color(0xFF8B6650)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B4F3A).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                AiraTapEffect(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ธุรกรรมสต็อก',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Stock In / Out / Adjustment',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Body ───
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: AiraEmptyState(
                        icon: Icons.inventory_2_rounded,
                        title: context.l10n.noProductsYet,
                        subtitle: context.l10n.isThai
                            ? 'เพิ่มสินค้าใน Product Library ก่อน แล้วจึงเริ่มรับเข้า เบิกใช้ และติดตามล็อตคงเหลือ'
                            : 'Add products in the Product Library first, then start receiving, using, and tracking inventory lots.',
                        accentColor: AiraColors.woodMid,
                      ),
                    ),
                  );
                }

                return Row(
                  children: [
                    // Left: product list
                    SizedBox(
                      width: 300,
                      child: _ProductList(
                        products: products,
                        selectedId: selectedProductId,
                        onSelect: (id) => ref
                            .read(_invProductIdProvider.notifier)
                            .state = id,
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    // Right: transactions
                    Expanded(
                      child: selectedProductId == null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: AiraEmptyState(
                                  icon: Icons.touch_app_rounded,
                                  title: context.l10n.selectProductLeft,
                                  subtitle: context.l10n.isThai
                                      ? 'เลือกสินค้าทางด้านซ้ายเพื่อดูยอดคงเหลือ ประวัติธุรกรรม และข้อมูลล็อตล่าสุด'
                                      : 'Select a product on the left to review on-hand stock, transaction history, and recent lot details.',
                                  accentColor: AiraColors.gold,
                                ),
                              ),
                            )
                          : _TransactionPanel(
                              product: products.firstWhere(
                                  (p) => p.id == selectedProductId,
                                  orElse: () => products.first),
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AiraColors.woodMid)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Product List Panel ──────────────────────────────────────
class _ProductList extends StatelessWidget {
  final List<Product> products;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _ProductList({
    required this.products,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        final selected = p.id == selectedId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: AiraTapEffect(
            onTap: () => onSelect(p.id),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? AiraColors.woodWash.withValues(alpha: 0.5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AiraColors.woodMid
                      : AiraColors.creamDk.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AiraColors.charcoal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                          'สต็อก: ${NumberFormat('#,##0.#').format(p.stockQuantity)} ${p.unit}',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: p.isLowStock
                                  ? AiraColors.terra
                                  : AiraColors.muted)),
                      const Spacer(),
                      if (p.isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AiraColors.terra.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(context.l10n.low,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AiraColors.terra)),
                        ),
                      if (p.isExpired) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AiraColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(context.l10n.expired,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AiraColors.danger)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Transaction Panel ───────────────────────────────────────
class _TransactionPanel extends ConsumerWidget {
  final Product product;
  const _TransactionPanel({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(_inventoryTxProvider(product.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product info header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AiraColors.charcoal)),
                    if (product.brand != null)
                      Text('${product.brand} · ${product.category.dbValue}',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, color: AiraColors.muted)),
                    if ((product.stockPerContainer ?? 0) > 0 || product.minStockAlert != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if ((product.stockPerContainer ?? 0) > 0)
                              _MetaChip(
                                label:
                                    '1 ขวด/กล่อง = ${NumberFormat('#,##0.###').format(product.stockPerContainer ?? 0)} ${product.unit}',
                                color: AiraColors.woodMid,
                              ),
                            if (product.minStockAlert != null)
                              _MetaChip(
                                label:
                                    'Min ≤ ${product.minStockAlert} ${product.unit}',
                                color: product.isLowStock
                                    ? AiraColors.terra
                                    : AiraColors.gold,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Stock badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: product.isLowStock
                      ? AiraColors.terra.withValues(alpha: 0.1)
                      : AiraColors.sage.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                        NumberFormat('#,##0.##')
                            .format(product.stockQuantity),
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: product.isLowStock
                                ? AiraColors.terra
                                : AiraColors.sage)),
                    Text(product.unit,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, color: AiraColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Action buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: 'รับเข้า (Stock In)',
                  icon: Icons.add_circle_outline_rounded,
                  color: AiraColors.sage,
                  onTap: () =>
                      _showTxDialog(context, ref, InventoryTransactionType.stockIn),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: 'เบิกออก (Used)',
                  icon: Icons.remove_circle_outline_rounded,
                  color: AiraColors.terra,
                  onTap: () =>
                      _showTxDialog(context, ref, InventoryTransactionType.used),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: 'ปรับยอด',
                  icon: Icons.tune_rounded,
                  color: AiraColors.gold,
                  onTap: () => _showTxDialog(
                      context, ref, InventoryTransactionType.adjustment),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: 'สูญเสีย',
                  icon: Icons.delete_outline_rounded,
                  color: AiraColors.muted,
                  onTap: () => _showTxDialog(
                      context, ref, InventoryTransactionType.wastage),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Expiry info
        if (product.expiryDate != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: product.isExpired
                  ? AiraColors.danger.withValues(alpha: 0.08)
                  : _isExpiringSoon(product.expiryDate!)
                      ? AiraColors.gold.withValues(alpha: 0.08)
                      : AiraColors.sage.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  product.isExpired
                      ? Icons.error_rounded
                      : Icons.schedule_rounded,
                  size: 16,
                  color: product.isExpired
                      ? AiraColors.danger
                      : _isExpiringSoon(product.expiryDate!)
                          ? AiraColors.gold
                          : AiraColors.sage,
                ),
                const SizedBox(width: 8),
                Text(
                  product.isExpired
                      ? 'หมดอายุแล้ว: ${DateFormat('d MMM yyyy').format(product.expiryDate!)}'
                      : 'วันหมดอายุ: ${DateFormat('d MMM yyyy').format(product.expiryDate!)}${_isExpiringSoon(product.expiryDate!) ? ' (ใกล้หมด!)' : ''}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: product.isExpired
                        ? AiraColors.danger
                        : _isExpiringSoon(product.expiryDate!)
                            ? AiraColors.gold
                            : AiraColors.sage,
                  ),
                ),
              ],
            ),
          ),
        // Min stock alert
        if (product.minStockAlert != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'แจ้งเตือนเมื่อเหลือ ≤ ${product.minStockAlert} ${product.unit}',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, color: AiraColors.muted),
            ),
          ),
        const SizedBox(height: 8),
        // Transaction history title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(context.l10n.transactionHistory,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AiraColors.charcoal)),
        ),
        const SizedBox(height: 8),
        // Transaction list
        Expanded(
          child: txAsync.when(
            data: (txs) {
              if (txs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AiraEmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: context.l10n.noTransactionsYet,
                      subtitle: context.l10n.isThai
                          ? 'ยังไม่มีการรับเข้า เบิกใช้ ปรับยอด หรือบันทึก lot สำหรับสินค้านี้'
                          : 'There are no stock-in, usage, adjustment, or lot transactions for this product yet.',
                      accentColor: AiraColors.woodMid,
                    ),
                  ),
                );
              }
              final recentBatches = _recentBatchTransactions(txs);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recentBatches.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: recentBatches
                            .map(
                              (tx) => _BatchChip(
                                batchNo: tx.batchNo,
                                expiryDate: tx.expiryDate,
                                isExpired: tx.expiryDate != null &&
                                    tx.expiryDate!.isBefore(DateTime.now()),
                                isExpiringSoon: tx.expiryDate != null &&
                                    _isExpiringSoon(tx.expiryDate!),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: txs.length,
                      itemBuilder: (_, i) => _TxCard(tx: txs[i], unit: product.unit),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(
                child:
                    CircularProgressIndicator(color: AiraColors.woodMid)),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  bool _isExpiringSoon(DateTime date) {
    return date.isBefore(DateTime.now().add(const Duration(days: 30))) &&
        date.isAfter(DateTime.now());
  }

  List<InventoryTransaction> _recentBatchTransactions(
      List<InventoryTransaction> txs) {
    final seen = <String>{};
    final result = <InventoryTransaction>[];
    for (final tx in txs) {
      if (tx.transactionType != InventoryTransactionType.stockIn) continue;
      final batchKey = tx.batchNo?.trim() ?? '';
      final expiryKey = tx.expiryDate?.toIso8601String() ?? '';
      if (batchKey.isEmpty && expiryKey.isEmpty) continue;
      final key = '$batchKey|$expiryKey';
      if (!seen.add(key)) continue;
      result.add(tx);
      if (result.length >= 3) break;
    }
    return result;
  }

  void _showTxDialog(
      BuildContext context, WidgetRef ref, InventoryTransactionType type) {
    final qtyCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime? expiryDate;

    final typeLabel = switch (type) {
      InventoryTransactionType.stockIn => 'รับเข้า (Stock In)',
      InventoryTransactionType.used => 'เบิกใช้ (Used)',
      InventoryTransactionType.wastage => 'สูญเสีย (Wastage)',
      InventoryTransactionType.adjustment => 'ปรับยอด (Adjustment)',
    };

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(typeLabel,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AiraColors.charcoal)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${product.name} (สต็อกปัจจุบัน: ${NumberFormat('#,##0.##').format(product.stockQuantity)} ${product.unit})',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: AiraColors.muted)),
                const SizedBox(height: 16),
                TextField(
                  controller: qtyCtrl,
                  style: airaFieldTextStyle,
                  decoration: airaFieldDecoration(
                    label: type == InventoryTransactionType.adjustment
                        ? 'ยอดใหม่ (จำนวน)'
                        : 'จำนวน (${product.unit})',
                    prefixIcon: Icons.numbers_rounded,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                ),
                if (type == InventoryTransactionType.stockIn) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: batchCtrl,
                    style: airaFieldTextStyle,
                    decoration: airaFieldDecoration(
                        label: 'Batch No. (ไม่บังคับ)',
                        prefixIcon: Icons.qr_code_rounded),
                  ),
                  const SizedBox(height: 12),
                  AiraTapEffect(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate:
                            DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        setDialogState(() => expiryDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AiraColors.woodWash.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AiraColors.creamDk.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event_rounded,
                              size: 18, color: AiraColors.woodMid),
                          const SizedBox(width: 10),
                          Text(
                            expiryDate != null
                                ? 'หมดอายุ: ${DateFormat('d MMM yyyy').format(expiryDate!)}'
                                : 'วันหมดอายุ (ไม่บังคับ)',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: expiryDate != null
                                    ? AiraColors.charcoal
                                    : AiraColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  style: airaFieldTextStyle,
                  decoration: airaFieldDecoration(
                      label: 'หมายเหตุ (ไม่บังคับ)',
                      prefixIcon: Icons.note_rounded),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel,
                  style:
                      GoogleFonts.plusJakartaSans(color: AiraColors.muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AiraColors.woodMid,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final qty = double.tryParse(qtyCtrl.text.trim());
                final quantityIssue = validateInventoryQuantity(
                  quantity: qty,
                  type: type,
                  availableStock: product.stockQuantity,
                );
                if (quantityIssue == InventoryQuantityValidationIssue.invalidQuantity) {
                  AiraFeedback.error(
                    context,
                    context.l10n.isThai
                        ? 'จำนวนต้องมากกว่า 0'
                        : 'Quantity must be greater than 0.',
                  );
                  return;
                }

                final clinicId = ref.read(currentClinicIdProvider);
                if (clinicId == null) {
                  if (context.mounted) {
                    AiraFeedback.error(context, context.l10n.clinicContextMissing);
                  }
                  return;
                }

                if (quantityIssue == InventoryQuantityValidationIssue.insufficientStock) {
                  AiraFeedback.error(
                    context,
                    context.l10n.isThai
                        ? 'จำนวนที่เบิกออกมากกว่าสต็อกคงเหลือ'
                        : 'The requested quantity is greater than the remaining stock.',
                  );
                  return;
                }
                final validQty = qty!;

                Navigator.pop(ctx);

                try {
                  final invRepo = ref.read(inventoryRepoProvider);
                  final prodRepo = ref.read(productRepoProvider);
                  final currentStaff =
                      ref.read(currentStaffProvider).valueOrNull;

                  // Calculate new stock quantity
                  double newStock;
                  if (type == InventoryTransactionType.adjustment) {
                    newStock = validQty; // Adjustment sets absolute value
                  } else if (type == InventoryTransactionType.stockIn) {
                    newStock = product.stockQuantity + validQty;
                  } else {
                    // used or wastage
                    newStock = product.stockQuantity - validQty;
                  }

                  final noteSegments = <String>[];
                  if (type == InventoryTransactionType.adjustment) {
                    noteSegments.add(
                      context.l10n.isThai
                          ? 'ปรับยอดจาก ${NumberFormat('#,##0.##').format(product.stockQuantity)} เป็น ${NumberFormat('#,##0.##').format(newStock)} ${product.unit}'
                          : 'Adjusted stock from ${NumberFormat('#,##0.##').format(product.stockQuantity)} to ${NumberFormat('#,##0.##').format(newStock)} ${product.unit}',
                    );
                  }
                  if (notesCtrl.text.trim().isNotEmpty) {
                    noteSegments.add(notesCtrl.text.trim());
                  }

                  // Create transaction record
                  final tx = InventoryTransaction(
                    id: const Uuid().v4(),
                    clinicId: clinicId,
                    productId: product.id,
                    transactionType: type,
                    quantity: validQty,
                    unit: product.unit,
                    batchNo: batchCtrl.text.trim().isEmpty
                        ? null
                        : batchCtrl.text.trim(),
                    expiryDate: expiryDate,
                    notes: noteSegments.isEmpty ? null : noteSegments.join(' • '),
                    createdBy: currentStaff?.id,
                  );
                  await invRepo.create(tx);

                  // Update product stock
                  final selectedExpiryDate = expiryDate;
                  final syncedExpiryDate =
                      type == InventoryTransactionType.stockIn &&
                              selectedExpiryDate != null &&
                              (product.expiryDate == null ||
                                  selectedExpiryDate.isBefore(product.expiryDate!))
                          ? selectedExpiryDate
                          : product.expiryDate;
                  await prodRepo.updateProduct(product.copyWith(
                    stockQuantity: newStock,
                    expiryDate: syncedExpiryDate,
                  ));

                  // Refresh
                  ref.invalidate(_inventoryTxProvider(product.id));
                  ref.invalidate(productListProvider);
                  ref.invalidate(lowStockAlertsProvider);

                  // Audit log
                  ref.read(auditServiceProvider).log(
                    action: 'STOCK_${type.dbValue}',
                    entityType: 'products',
                    entityId: product.id,
                    newData: {
                      'quantity': qty,
                      'product': product.name,
                      'new_stock': newStock,
                      'batch_no': tx.batchNo,
                      'expiry_date': tx.expiryDate?.toIso8601String(),
                      'created_by': tx.createdBy,
                    },
                  );

                  if (context.mounted) {
                    AiraFeedback.success(context, context.l10n.transactionSaveSuccess);
                  }
                } catch (e) {
                  if (context.mounted) {
                    AiraFeedback.error(context, context.l10n.errorMsg('$e'));
                  }
                }
              },
              child: Text(context.l10n.save,
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10, fontWeight: FontWeight.w600, color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _BatchChip extends StatelessWidget {
  final String? batchNo;
  final DateTime? expiryDate;
  final bool isExpired;
  final bool isExpiringSoon;

  const _BatchChip({
    required this.batchNo,
    required this.expiryDate,
    required this.isExpired,
    required this.isExpiringSoon,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpired
        ? AiraColors.danger
        : isExpiringSoon
            ? AiraColors.gold
            : AiraColors.sage;
    final expiryLabel = expiryDate != null
        ? DateFormat('d MMM yy').format(expiryDate!)
        : (context.l10n.isThai ? 'ไม่ระบุวันหมดอายุ' : 'No expiry');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (batchNo != null && batchNo!.trim().isNotEmpty)
                ? 'Batch ${batchNo!.trim()}'
                : (context.l10n.isThai ? 'ล็อตล่าสุด' : 'Recent lot'),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            expiryLabel,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AiraColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final InventoryTransaction tx;
  final String unit;
  const _TxCard({required this.tx, required this.unit});

  @override
  Widget build(BuildContext context) {
    final (icon, color, sign) = switch (tx.transactionType) {
      InventoryTransactionType.stockIn => (
          Icons.add_circle_rounded,
          AiraColors.sage,
          '+'
        ),
      InventoryTransactionType.used => (
          Icons.remove_circle_rounded,
          AiraColors.terra,
          '-'
        ),
      InventoryTransactionType.wastage => (
          Icons.delete_rounded,
          AiraColors.muted,
          '-'
        ),
      InventoryTransactionType.adjustment => (
          Icons.tune_rounded,
          AiraColors.gold,
          '='
        ),
    };

    final dateStr = tx.createdAt != null
        ? DateFormat('d/M/yy HH:mm').format(tx.createdAt!)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.transactionType.dbValue.replaceAll('_', ' '),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AiraColors.charcoal),
                ),
                if (tx.notes != null && tx.notes!.isNotEmpty)
                  Text(tx.notes!,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: AiraColors.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                if (tx.batchNo != null)
                  Text('Batch: ${tx.batchNo}',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 10, color: AiraColors.muted)),
                if (tx.expiryDate != null)
                  Text(
                    'EXP: ${DateFormat('d MMM yyyy').format(tx.expiryDate!)}',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 10, color: AiraColors.muted),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$sign${NumberFormat('#,##0.##').format(tx.quantity)} $unit',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color)),
              Text(dateStr,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 10, color: AiraColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}
