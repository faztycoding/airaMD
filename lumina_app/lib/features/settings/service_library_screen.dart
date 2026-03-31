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

/// Active category filter for services.
final _svcCatFilterProvider = StateProvider<ServiceCategory?>((ref) => null);

class ServiceLibraryScreen extends ConsumerWidget {
  const ServiceLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(serviceListProvider);
    final catFilter = ref.watch(_svcCatFilterProvider);

    return Scaffold(
      backgroundColor: AiraColors.cream,
      appBar: AppBar(
        title: const Text('บริการ / หัตถการ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showServiceForm(context, ref, null),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                _CatChip('ทั้งหมด', null, catFilter, ref),
                const SizedBox(width: 8),
                ...ServiceCategory.values.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CatChip(_catLabel(c), c, catFilter, ref),
                )),
              ],
            ),
          ),
          Expanded(
            child: servicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
              data: (services) {
                var filtered = services;
                if (catFilter != null) {
                  filtered = services.where((s) => s.category == catFilter).toList();
                }
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.15)),
                          boxShadow: [
                            BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8)),
                            BoxShadow(color: AiraColors.gold.withValues(alpha: 0.06), blurRadius: 40, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AiraColors.woodPale.withValues(alpha: 0.18), AiraColors.gold.withValues(alpha: 0.10)],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.2)),
                              ),
                              child: Icon(Icons.medical_services_rounded, size: 32, color: AiraColors.woodMid),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              catFilter != null ? 'ไม่มีบริการในหมวดนี้' : 'ยังไม่มีบริการ / หัตถการ',
                              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'เพิ่มรายการบริการเพื่อจัดการราคา\nหมวดหมู่ และค่าตอบแทนแพทย์',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted, height: 1.5),
                            ),
                            const SizedBox(height: 28),
                            AiraTapEffect(
                              onTap: () => _showServiceForm(context, ref, null),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3D2517), Color(0xFF6B4F3A), Color(0xFF8B6650)],
                                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text('เพิ่มบริการใหม่', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, i2) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ServiceCard(
                    service: filtered[i],
                    onEdit: () => _showServiceForm(context, ref, filtered[i]),
                    onDelete: () => _deleteService(context, ref, filtered[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showServiceForm(BuildContext context, WidgetRef ref, Service? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(text: existing?.defaultPrice?.toStringAsFixed(0) ?? '');
    final feeValueCtrl = TextEditingController(text: existing?.doctorFeeValue?.toStringAsFixed(0) ?? '');
    final costCtrl = TextEditingController(text: existing?.estimatedCost?.toStringAsFixed(0) ?? '');
    var category = existing?.category ?? ServiceCategory.treatment;
    var feeType = existing?.doctorFeeType ?? DoctorFeeType.none;

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
                    Icon(Icons.medical_services_rounded, size: 22, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(
                      existing != null ? 'แก้ไขบริการ' : 'เพิ่มบริการใหม่',
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
                        TextField(controller: nameCtrl, style: airaFieldTextStyle, decoration: airaFieldDecoration(label: 'ชื่อบริการ *', prefixIcon: Icons.medical_services_rounded)),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<ServiceCategory>(
                          value: category, style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(label: 'หมวดหมู่', prefixIcon: Icons.category_rounded),
                          items: ServiceCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(_catLabel(c), style: airaFieldTextStyle))).toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => category = v); },
                        ),
                        const SizedBox(height: 14),
                        TextField(controller: priceCtrl, style: airaFieldTextStyle, decoration: airaFieldDecoration(label: 'ราคาเริ่มต้น (฿)', prefixIcon: Icons.payments_rounded), keyboardType: TextInputType.number),
                        const SizedBox(height: 14),
                        TextField(controller: costCtrl, style: airaFieldTextStyle, decoration: airaFieldDecoration(label: 'ต้นทุนโดยประมาณ (฿)', prefixIcon: Icons.calculate_rounded), keyboardType: TextInputType.number),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<DoctorFeeType>(
                          value: feeType, style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(label: 'ค่าตอบแทนแพทย์', prefixIcon: Icons.account_balance_wallet_rounded),
                          items: DoctorFeeType.values.map((t) => DropdownMenuItem(value: t, child: Text(_feeLabel(t), style: airaFieldTextStyle))).toList(),
                          onChanged: (v) { if (v != null) setDialogState(() => feeType = v); },
                        ),
                        if (feeType != DoctorFeeType.none) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: feeValueCtrl, style: airaFieldTextStyle,
                            decoration: airaFieldDecoration(
                              label: feeType == DoctorFeeType.percentage ? 'เปอร์เซ็นต์ (%)' : 'จำนวนเงิน (฿)',
                              prefixIcon: feeType == DoctorFeeType.percentage ? Icons.percent_rounded : Icons.attach_money_rounded,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
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
                          decoration: BoxDecoration(
                            color: AiraColors.creamDk,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(child: Text('ยกเลิก', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.muted))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: AiraTapEffect(
                        onTap: () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          final clinicId = ref.read(currentClinicIdProvider);
                          if (clinicId == null) return;

                          final service = Service(
                            id: existing?.id ?? const Uuid().v4(),
                            clinicId: clinicId,
                            name: nameCtrl.text.trim(),
                            category: category,
                            defaultPrice: double.tryParse(priceCtrl.text.trim()),
                            doctorFeeType: feeType,
                            doctorFeeValue: double.tryParse(feeValueCtrl.text.trim()),
                            estimatedCost: double.tryParse(costCtrl.text.trim()),
                          );

                          try {
                            final repo = ref.read(serviceRepoProvider);
                            if (existing != null) {
                              await repo.updateService(service);
                            } else {
                              await repo.create(service);
                            }
                            ref.invalidate(serviceListProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ผิดพลาด: $e'), backgroundColor: AiraColors.terra));
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
                            Text(existing != null ? 'บันทึก' : 'เพิ่มบริการ', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
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

  void _deleteService(BuildContext context, WidgetRef ref, Service service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันลบ'),
        content: Text('ต้องการลบบริการ "${service.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AiraColors.terra),
            onPressed: () async {
              try {
                await ref.read(serviceRepoProvider).deleteService(service.id);
                ref.invalidate(serviceListProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ผิดพลาด: $e')));
                }
              }
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static String _catLabel(ServiceCategory c) {
    switch (c) {
      case ServiceCategory.ha: return 'HA';
      case ServiceCategory.injectable: return 'Injectable';
      case ServiceCategory.laser: return 'Laser';
      case ServiceCategory.treatment: return 'Treatment';
      case ServiceCategory.other: return 'อื่นๆ';
    }
  }

  static String _feeLabel(DoctorFeeType t) {
    switch (t) {
      case DoctorFeeType.fixedAmount: return 'จำนวนคงที่ (฿)';
      case DoctorFeeType.percentage: return 'เปอร์เซ็นต์ (%)';
      case DoctorFeeType.none: return 'ไม่มี';
    }
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final ServiceCategory? value;
  final ServiceCategory? current;
  final WidgetRef ref;
  const _CatChip(this.label, this.value, this.current, this.ref);

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return AiraTapEffect(
      onTap: () => ref.read(_svcCatFilterProvider.notifier).state = value,
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

class _ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ServiceCard({required this.service, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _catColor(service.category).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.medical_services_rounded, size: 20, color: _catColor(service.category)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: _catColor(service.category).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(ServiceLibraryScreen._catLabel(service.category), style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: _catColor(service.category))),
                  ),
                  if (service.defaultPrice != null) ...[
                    const SizedBox(width: 8),
                    Text('฿${NumberFormat('#,##0').format(service.defaultPrice)}', style: AiraFonts.numeric(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.woodMid)),
                  ],
                ]),
                if (service.doctorFeeType != DoctorFeeType.none && service.doctorFeeValue != null)
                  Text(
                    'ค่าแพทย์: ${service.doctorFeeType == DoctorFeeType.percentage ? '${service.doctorFeeValue!.toStringAsFixed(0)}%' : '฿${NumberFormat('#,##0').format(service.doctorFeeValue)}'}',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AiraColors.muted),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 18, color: AiraColors.muted),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
              const PopupMenuItem(value: 'delete', child: Text('ลบ', style: TextStyle(color: Colors.red))),
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

  Color _catColor(ServiceCategory c) {
    switch (c) {
      case ServiceCategory.ha: return AiraColors.sage;
      case ServiceCategory.injectable: return AiraColors.woodMid;
      case ServiceCategory.laser: return AiraColors.terra;
      case ServiceCategory.treatment: return AiraColors.gold;
      case ServiceCategory.other: return AiraColors.muted;
    }
  }
}
