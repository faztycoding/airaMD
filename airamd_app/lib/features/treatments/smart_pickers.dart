import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/aira_premium_form.dart';
import '../../core/localization/app_localizations.dart';

/// ════════════════════════════════════════════════════════════════════
/// Smart pickers for the treatment form (Phase 5 — Smart Catalog).
///
/// Each picker is a bottom sheet with:
///   • Search-as-you-type field
///   • Category chip filter
///   • Scrollable list of items
///
/// Returns the user's selection via `Navigator.pop(ctx, value)`, or
/// `null` if the sheet is dismissed.
/// ════════════════════════════════════════════════════════════════════

// ─── Service picker ─────────────────────────────────────────────────

/// Lets the doctor pick a `Service` from the seeded catalog. Used to
/// auto-fill the treatment name + category in the treatment form.
Future<Service?> pickService({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<Service>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ServicePickerSheet(parentRef: ref),
  );
}

class _ServicePickerSheet extends ConsumerStatefulWidget {
  final WidgetRef parentRef;
  const _ServicePickerSheet({required this.parentRef});

  @override
  ConsumerState<_ServicePickerSheet> createState() =>
      _ServicePickerSheetState();
}

class _ServicePickerSheetState extends ConsumerState<_ServicePickerSheet> {
  String _query = '';
  ServiceCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final asyncServices = ref.watch(serviceListProvider);
    final isThai = context.l10n.isThai;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AiraColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              _DragHandle(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.search_rounded,
                      size: 22, color: AiraColors.woodMid),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isThai
                          ? 'เลือกบริการจากแคตตาล็อก'
                          : 'Pick a Service',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AiraColors.charcoal,
                      ),
                    ),
                  ),
                  AiraTapEffect(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        size: 22, color: AiraColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                style: airaFieldTextStyle,
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: airaFieldDecoration(
                  label: '',
                  hint: isThai
                      ? 'พิมพ์ชื่อบริการ... (เช่น Pico, Oligio)'
                      : 'Type to search... (e.g. Pico, Oligio)',
                  prefixIcon: Icons.search_rounded,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: context.l10n.all,
                      isActive: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    const SizedBox(width: 8),
                    ...ServiceCategory.values.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _CategoryChip(
                            label: _serviceCategoryLabel(c, isThai),
                            isActive: _filter == c,
                            onTap: () => setState(() => _filter = c),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: asyncServices.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AiraColors.woodMid)),
                  error: (e, _) => Center(
                    child: Text(
                      isThai
                          ? 'โหลดบริการไม่สำเร็จ: $e'
                          : 'Failed to load services: $e',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AiraColors.terra,
                      ),
                    ),
                  ),
                  data: (services) {
                    var filtered = services;
                    if (_filter != null) {
                      filtered = filtered
                          .where((s) => s.category == _filter)
                          .toList();
                    }
                    if (_query.isNotEmpty) {
                      filtered = filtered
                          .where((s) =>
                              s.name.toLowerCase().contains(_query))
                          .toList();
                    }
                    if (filtered.isEmpty) {
                      return _EmptyState(
                        message: isThai
                            ? 'ไม่พบบริการที่ตรงกับคำค้นหา'
                            : 'No matching services',
                      );
                    }
                    return ListView.separated(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final s = filtered[i];
                        return _ServiceTile(
                          service: s,
                          onTap: () => Navigator.pop(context, s),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _serviceCategoryLabel(ServiceCategory c, bool isThai) {
    switch (c) {
      case ServiceCategory.ha:
        return 'HA';
      case ServiceCategory.injectable:
        return isThai ? 'ฉีด' : 'Injectable';
      case ServiceCategory.laser:
        return isThai ? 'เลเซอร์' : 'Laser';
      case ServiceCategory.treatment:
        return isThai ? 'ทรีทเมนต์' : 'Treatment';
      case ServiceCategory.other:
        return isThai ? 'อื่นๆ' : 'Other';
    }
  }
}

class _ServiceTile extends StatelessWidget {
  final Service service;
  final VoidCallback onTap;
  const _ServiceTile({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AiraColors.woodWash.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medical_services_rounded,
                  size: 18, color: AiraColors.woodMid),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AiraColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _serviceCategoryShort(service.category),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AiraColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (service.defaultPrice != null)
              Text(
                '฿${NumberFormat('#,##0').format(service.defaultPrice)}',
                style: AiraFonts.numeric(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AiraColors.gold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _serviceCategoryShort(ServiceCategory c) {
    switch (c) {
      case ServiceCategory.ha:
        return 'HA';
      case ServiceCategory.injectable:
        return 'Injectable';
      case ServiceCategory.laser:
        return 'Laser';
      case ServiceCategory.treatment:
        return 'Treatment';
      case ServiceCategory.other:
        return 'Other';
    }
  }
}

// ─── Product picker ─────────────────────────────────────────────────

/// Result returned by [pickProductForUse] — shaped the same as the
/// existing `_productsUsed` entries in `treatment_form_screen`.
typedef ProductUseEntry = Map<String, dynamic>;

/// Lets the doctor pick a product + quantity from the seeded inventory.
/// Returns a map: `{name, brand?, quantity, unit, product_id}`.
Future<ProductUseEntry?> pickProductForUse({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<ProductUseEntry>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProductPickerSheet(parentRef: ref),
  );
}

class _ProductPickerSheet extends ConsumerStatefulWidget {
  final WidgetRef parentRef;
  const _ProductPickerSheet({required this.parentRef});

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  String _query = '';
  ProductCategory? _filter;
  Product? _selected;
  final _qtyCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncProducts = ref.watch(productListProvider);
    final isThai = context.l10n.isThai;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AiraColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              _DragHandle(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.inventory_2_rounded,
                      size: 22, color: AiraColors.woodMid),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isThai
                          ? 'เลือกผลิตภัณฑ์จากคลัง'
                          : 'Pick a Product',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AiraColors.charcoal,
                      ),
                    ),
                  ),
                  AiraTapEffect(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        size: 22, color: AiraColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                style: airaFieldTextStyle,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: airaFieldDecoration(
                  label: '',
                  hint: isThai
                      ? 'พิมพ์ชื่อผลิตภัณฑ์... (เช่น Restylane, Botox)'
                      : 'Type to search... (e.g. Restylane, Botox)',
                  prefixIcon: Icons.search_rounded,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CategoryChip(
                      label: context.l10n.all,
                      isActive: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    const SizedBox(width: 8),
                    ...ProductCategory.values.map((c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _CategoryChip(
                            label: _productCategoryLabel(c, isThai),
                            isActive: _filter == c,
                            onTap: () => setState(() => _filter = c),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: asyncProducts.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AiraColors.woodMid)),
                  error: (e, _) => Center(
                    child: Text(
                      isThai
                          ? 'โหลดผลิตภัณฑ์ไม่สำเร็จ: $e'
                          : 'Failed to load products: $e',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AiraColors.terra,
                      ),
                    ),
                  ),
                  data: (products) {
                    var filtered = products;
                    if (_filter != null) {
                      filtered = filtered
                          .where((p) => p.category == _filter)
                          .toList();
                    }
                    if (_query.isNotEmpty) {
                      filtered = filtered.where((p) {
                        final n = p.name.toLowerCase();
                        final b = (p.brand ?? '').toLowerCase();
                        return n.contains(_query) || b.contains(_query);
                      }).toList();
                    }
                    if (filtered.isEmpty) {
                      return _EmptyState(
                        message: isThai
                            ? 'ไม่พบผลิตภัณฑ์ที่ตรงกับคำค้นหา'
                            : 'No matching products',
                      );
                    }
                    return ListView.separated(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final p = filtered[i];
                        return _ProductTile(
                          product: p,
                          isSelected: _selected?.id == p.id,
                          onTap: () => setState(() => _selected = p),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_selected != null) ...[
                const SizedBox(height: 12),
                _SelectedProductBar(
                  product: _selected!,
                  qtyCtrl: _qtyCtrl,
                  onAdd: () {
                    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
                    if (qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isThai
                                ? 'กรุณาระบุจำนวนที่มากกว่า 0'
                                : 'Quantity must be greater than 0',
                          ),
                          backgroundColor: AiraColors.terra,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, <String, dynamic>{
                      'product_id': _selected!.id,
                      'name': _selected!.name,
                      if (_selected!.brand != null) 'brand': _selected!.brand,
                      'unit': _selected!.unit,
                      'quantity': qty,
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  String _productCategoryLabel(ProductCategory c, bool isThai) {
    switch (c) {
      case ProductCategory.botox:
        return 'Botox';
      case ProductCategory.filler:
        return isThai ? 'Filler' : 'Filler';
      case ProductCategory.biostimulator:
        return isThai ? 'Bio' : 'Biostim';
      case ProductCategory.polynucleotide:
        return 'PN';
      case ProductCategory.skinbooster:
        return 'Booster';
      case ProductCategory.lipolytic:
        return isThai ? 'Lipo' : 'Lipolytic';
      case ProductCategory.laser:
        return isThai ? 'เลเซอร์' : 'Laser';
      case ProductCategory.other:
        return isThai ? 'อื่นๆ' : 'Other';
    }
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final VoidCallback onTap;
  const _ProductTile({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lowStock = product.minStockAlert != null &&
        product.stockQuantity <= product.minStockAlert!;
    return AiraTapEffect(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AiraColors.woodWash.withValues(alpha: 0.6)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AiraColors.woodDk.withValues(alpha: 0.5)
                : AiraColors.creamDk.withValues(alpha: 0.6),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AiraColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.inventory_2_rounded,
                  size: 18, color: AiraColors.gold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AiraColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (product.brand != null) product.brand!,
                      _productCategoryShort(product.category),
                    ].join(' • '),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AiraColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${NumberFormat('#,##0.###').format(product.stockQuantity)} ${product.unit}',
                  style: AiraFonts.numeric(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: lowStock ? AiraColors.terra : AiraColors.sage,
                  ),
                ),
                if (lowStock)
                  Text(
                    context.l10n.low,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      color: AiraColors.terra,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _productCategoryShort(ProductCategory c) {
    switch (c) {
      case ProductCategory.botox:
        return 'Botox';
      case ProductCategory.filler:
        return 'Filler';
      case ProductCategory.biostimulator:
        return 'Biostim';
      case ProductCategory.polynucleotide:
        return 'Polynucleotide';
      case ProductCategory.skinbooster:
        return 'Booster';
      case ProductCategory.lipolytic:
        return 'Lipolytic';
      case ProductCategory.laser:
        return 'Laser';
      case ProductCategory.other:
        return 'Other';
    }
  }
}

class _SelectedProductBar extends StatelessWidget {
  final Product product;
  final TextEditingController qtyCtrl;
  final VoidCallback onAdd;
  const _SelectedProductBar({
    required this.product,
    required this.qtyCtrl,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isThai = context.l10n.isThai;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AiraColors.woodWash.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AiraColors.charcoal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${isThai ? 'สต็อก' : 'Stock'}: ${NumberFormat('#,##0.###').format(product.stockQuantity)} ${product.unit}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AiraColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: TextField(
              controller: qtyCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: airaFieldTextStyle.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              decoration: airaFieldDecoration(
                label: '',
                hint: isThai ? 'จำนวน' : 'Qty',
              ),
            ),
          ),
          const SizedBox(width: 8),
          AiraTapEffect(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: AiraColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_rounded,
                      size: 18, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    context.l10n.add,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Template picker ────────────────────────────────────────────────

/// Lets the doctor pick a treatment combo template to pre-fill the form.
Future<TreatmentTemplate?> pickTreatmentTemplate({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<TreatmentTemplate>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TemplatePickerSheet(parentRef: ref),
  );
}

class _TemplatePickerSheet extends ConsumerStatefulWidget {
  final WidgetRef parentRef;
  const _TemplatePickerSheet({required this.parentRef});

  @override
  ConsumerState<_TemplatePickerSheet> createState() =>
      _TemplatePickerSheetState();
}

class _TemplatePickerSheetState extends ConsumerState<_TemplatePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final asyncTemplates = ref.watch(treatmentTemplateListProvider);
    final isThai = context.l10n.isThai;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AiraColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              _DragHandle(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 22, color: AiraColors.woodMid),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isThai
                          ? 'เลือก Combo Template'
                          : 'Pick a Combo Template',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AiraColors.charcoal,
                      ),
                    ),
                  ),
                  AiraTapEffect(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close_rounded,
                        size: 22, color: AiraColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                style: airaFieldTextStyle,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                decoration: airaFieldDecoration(
                  label: '',
                  hint: isThai
                      ? 'ค้นหา... (เช่น Acne, Midface)'
                      : 'Search... (e.g. Acne, Midface)',
                  prefixIcon: Icons.search_rounded,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: asyncTemplates.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AiraColors.woodMid)),
                  error: (e, _) => Center(
                    child: Text(
                      isThai
                          ? 'โหลด template ไม่สำเร็จ: $e'
                          : 'Failed to load templates: $e',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AiraColors.terra,
                      ),
                    ),
                  ),
                  data: (templates) {
                    var filtered = templates;
                    if (_query.isNotEmpty) {
                      filtered = filtered
                          .where((t) =>
                              t.name.toLowerCase().contains(_query) ||
                              (t.description?.toLowerCase() ?? '')
                                  .contains(_query))
                          .toList();
                    }
                    if (filtered.isEmpty) {
                      return _EmptyState(
                        message: isThai
                            ? 'ยังไม่มี template ในคลินิกนี้'
                            : 'No templates yet',
                      );
                    }
                    return ListView.separated(
                      controller: scrollCtrl,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final t = filtered[i];
                        return _TemplateTile(
                          template: t,
                          onTap: () => Navigator.pop(context, t),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final TreatmentTemplate template;
  final VoidCallback onTap;
  const _TemplateTile({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final productCount = template.suggestedProducts.length;
    final serviceCount = template.suggestedServices.length;
    final isThai = context.l10n.isThai;
    return AiraTapEffect(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AiraColors.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      size: 16, color: AiraColors.gold),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    template.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AiraColors.charcoal,
                    ),
                  ),
                ),
              ],
            ),
            if (template.description != null) ...[
              const SizedBox(height: 8),
              Text(
                template.description!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AiraColors.muted,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (productCount > 0)
                  _MiniBadge(
                    icon: Icons.inventory_2_rounded,
                    label: isThai
                        ? '$productCount ผลิตภัณฑ์'
                        : '$productCount products',
                    color: AiraColors.gold,
                  ),
                if (serviceCount > 0)
                  _MiniBadge(
                    icon: Icons.medical_services_rounded,
                    label: isThai
                        ? '$serviceCount บริการ'
                        : '$serviceCount services',
                    color: AiraColors.woodMid,
                  ),
                if (template.defaultInstructions.isNotEmpty)
                  _MiniBadge(
                    icon: Icons.checklist_rounded,
                    label: isThai
                        ? '${template.defaultInstructions.length} คำแนะนำ'
                        : '${template.defaultInstructions.length} instructions',
                    color: AiraColors.sage,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ─────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AiraColors.woodPale.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AiraColors.woodDk : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AiraColors.woodDk
                : AiraColors.creamDk.withValues(alpha: 0.6),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : AiraColors.charcoal,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded,
              size: 40, color: AiraColors.muted.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AiraColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MiniBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
