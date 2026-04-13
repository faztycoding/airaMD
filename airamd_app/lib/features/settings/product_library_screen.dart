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

/// Active category filter.
final _prodCatFilterProvider = StateProvider<ProductCategory?>((ref) => null);

class ProductLibraryScreen extends ConsumerWidget {
  const ProductLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final catFilter = ref.watch(_prodCatFilterProvider);

    return Scaffold(
      backgroundColor: AiraColors.cream,
      appBar: AppBar(
        title: Builder(builder: (ctx) => Text(ctx.l10n.productLibrary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showProductForm(context, ref, null),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Category filter chips
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    _CatChip('ทั้งหมด', null, catFilter, ref),
                    const SizedBox(width: 8),
                    ...ProductCategory.values.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CatChip(_catLabel(c), c, catFilter, ref),
                    )),
                  ],
                ),
              ),
              // Product list
              Expanded(
                child: productsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text(context.l10n.errorMsg('$e'))),
                  data: (products) {
                    var filtered = products;
                    if (catFilter != null) {
                      filtered = products.where((p) => p.category == catFilter).toList();
                    }
                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_rounded, size: 48, color: AiraColors.muted.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              Text(context.l10n.noProductsInLibrary, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AiraColors.muted)),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showProductForm(context, ref, null),
                                  icon: const Icon(Icons.add_rounded),
                                  label: Text(context.l10n.addProduct),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: filtered.length,
                      separatorBuilder: (_, i2) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ProductCard(
                        product: filtered[i],
                        onEdit: () => _showProductForm(context, ref, filtered[i]),
                        onDelete: () => _deleteProduct(context, ref, filtered[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProductForm(BuildContext context, WidgetRef ref, Product? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final brandCtrl = TextEditingController(text: existing?.brand ?? '');
    final unitCtrl = TextEditingController(text: existing?.unit ?? 'U');
    final unitCostCtrl = TextEditingController(text: existing?.unitCost?.toStringAsFixed(0) ?? '');
    final priceCtrl = TextEditingController(text: existing?.defaultPrice?.toStringAsFixed(0) ?? '');
    final stockCtrl = TextEditingController(text: existing?.stockQuantity.toString() ?? '0');
    final stockPerContainerCtrl = TextEditingController(text: existing?.stockPerContainer?.toString() ?? '');
    final minAlertCtrl = TextEditingController(text: existing?.minStockAlert?.toString() ?? '');
    var category = existing?.category ?? ProductCategory.botox;

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
                    Icon(Icons.science_rounded, size: 22, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(
                      existing != null ? 'แก้ไขผลิตภัณฑ์' : 'เพิ่มผลิตภัณฑ์ใหม่',
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
                        TextField(controller: nameCtrl, style: airaFieldTextStyle, decoration: airaFieldDecoration(label: 'ชื่อผลิตภัณฑ์ *', prefixIcon: Icons.science_rounded)),
                        const SizedBox(height: 14),
                        TextField(controller: brandCtrl, style: airaFieldTextStyle, decoration: airaFieldDecoration(label: 'แบรนด์', prefixIcon: Icons.branding_watermark_rounded)),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<ProductCategory>(
                          value: category, style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(label: 'หมวดหมู่', prefixIcon: Icons.category_rounded),
                          items: ProductCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(_catLabel(c), style: airaFieldTextStyle))).toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => category = v); },
                        ),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: TextField(controller: unitCtrl, style: airaFieldTextStyle, decoration: airaFieldDecoration(label: 'หน่วย', prefixIcon: Icons.straighten_rounded))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: unitCostCtrl, style: airaFieldTextStyle, decoration: airaFieldDecoration(label: 'ต้นทุน/หน่วย', prefixIcon: Icons.calculate_rounded), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                        ]),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: TextField(controller: priceCtrl, style: airaFieldTextStyle, decoration: airaFieldDecoration(label: 'ราคาขาย', prefixIcon: Icons.payments_rounded), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: stockCtrl, style: airaFieldTextStyle, decoration: airaFieldDecoration(label: 'สต็อก', prefixIcon: Icons.inventory_rounded), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                        ]),
                        const SizedBox(height: 14),
                        TextField(controller: stockPerContainerCtrl, style: airaFieldTextStyle, decoration: airaFieldDecoration(label: 'จำนวนหน่วยต่อขวด/กล่อง', hint: 'เช่น 50', prefixIcon: Icons.science_outlined), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                        const SizedBox(height: 14),
                        TextField(controller: minAlertCtrl, style: airaFieldTextStyle, decoration: airaFieldDecoration(label: 'แจ้งเตือนเมื่อเหลือ (หน่วย)', prefixIcon: Icons.notification_important_rounded), keyboardType: TextInputType.number),
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
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.pleaseFillRequired)),
                            );
                            return;
                          }
                          final clinicId = ref.read(currentClinicIdProvider);
                          if (clinicId == null) return;

                          final product = Product(
                            id: existing?.id ?? const Uuid().v4(),
                            clinicId: clinicId,
                            name: nameCtrl.text.trim(),
                            brand: brandCtrl.text.trim().isEmpty ? null : brandCtrl.text.trim(),
                            category: category,
                            unit: unitCtrl.text.trim().isEmpty ? 'U' : unitCtrl.text.trim(),
                            unitCost: double.tryParse(unitCostCtrl.text.trim()),
                            defaultPrice: double.tryParse(priceCtrl.text.trim()),
                            stockQuantity: double.tryParse(stockCtrl.text.trim()) ?? 0,
                            stockPerContainer: double.tryParse(stockPerContainerCtrl.text.trim()),
                            minStockAlert: int.tryParse(minAlertCtrl.text.trim()),
                          );

                          try {
                            final repo = ref.read(productRepoProvider);
                            if (existing != null) {
                              await repo.updateProduct(product);
                            } else {
                              await repo.create(product);
                            }
                            ref.invalidate(productListProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.errorMsg('$e')), backgroundColor: AiraColors.terra));
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
                            Text(existing != null ? 'บันทึก' : 'เพิ่มผลิตภัณฑ์', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
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

  void _deleteProduct(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.confirmDelete),
        content: Text(context.l10n.deleteProduct(product.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AiraColors.terra),
            onPressed: () async {
              try {
                await ref.read(productRepoProvider).deleteProduct(product.id);
                ref.invalidate(productListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.errorMsg('$e'))));
                }
              }
            },
            child: Text(context.l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static String _catLabel(ProductCategory c) {
    switch (c) {
      case ProductCategory.botox: return 'Botox';
      case ProductCategory.filler: return 'Filler';
      case ProductCategory.biostimulator: return 'Biostimulator';
      case ProductCategory.polynucleotide: return 'Polynucleotide';
      case ProductCategory.skinbooster: return 'Skinbooster';
      case ProductCategory.laser: return 'Laser';
      case ProductCategory.other: return 'อื่นๆ';
    }
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final ProductCategory? value;
  final ProductCategory? current;
  final WidgetRef ref;
  const _CatChip(this.label, this.value, this.current, this.ref);

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return AiraTapEffect(
      onTap: () => ref.read(_prodCatFilterProvider.notifier).state = value,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AiraColors.woodDk : AiraColors.woodWash.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : AiraColors.charcoal)),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ProductCard({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: product.isLowStock ? AiraColors.terra.withValues(alpha: 0.3) : AiraColors.creamDk.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _catColor(product.category).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.science_rounded, size: 20, color: _catColor(product.category)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
                Row(children: [
                  if (product.brand != null) ...[
                    Text(product.brand!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted)),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: _catColor(product.category).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(ProductLibraryScreen._catLabel(product.category), style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: _catColor(product.category))),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.inventory_rounded, size: 12, color: product.isLowStock ? AiraColors.terra : AiraColors.muted),
                  const SizedBox(width: 4),
                  Text(
                    'สต็อก: ${NumberFormat('#,##0.#').format(product.stockQuantity)} ${product.unit}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: product.isLowStock ? FontWeight.w700 : FontWeight.w400,
                      color: product.isLowStock ? AiraColors.terra : AiraColors.muted),
                  ),
                  if (product.defaultPrice != null) ...[
                    const SizedBox(width: 12),
                    Text('฿${NumberFormat('#,##0').format(product.defaultPrice)}', style: AiraFonts.numeric(fontSize: 12, color: AiraColors.woodMid, fontWeight: FontWeight.w600)),
                  ],
                ]),
                if (product.stockPerContainer != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ต่อขวด/กล่อง: ${NumberFormat('#,##0.###').format(product.stockPerContainer)} ${product.unit}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 18, color: AiraColors.muted),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(context.l10n.edit)),
              PopupMenuItem(value: 'delete', child: Text(context.l10n.delete, style: const TextStyle(color: Colors.red))),
            ],
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
          ),
        ],
      ),
    );
  }

  Color _catColor(ProductCategory c) {
    switch (c) {
      case ProductCategory.botox: return AiraColors.woodMid;
      case ProductCategory.filler: return AiraColors.sage;
      case ProductCategory.biostimulator: return AiraColors.gold;
      case ProductCategory.polynucleotide: return const Color(0xFF6A8CAF);
      case ProductCategory.skinbooster: return const Color(0xFF9B7FB8);
      case ProductCategory.laser: return AiraColors.terra;
      case ProductCategory.other: return AiraColors.muted;
    }
  }
}
