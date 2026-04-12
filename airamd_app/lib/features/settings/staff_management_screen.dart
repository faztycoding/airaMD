import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/aira_premium_form.dart';
import '../../core/localization/app_localizations.dart';

// ─── Providers ────────────────────────────────────────────────
final _showInactiveProvider = StateProvider<bool>((ref) => false);

final _staffListProvider = FutureProvider<List<Staff>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(staffRepoProvider);
  final showInactive = ref.watch(_showInactiveProvider);
  return repo.list(clinicId: clinicId, activeOnly: !showInactive);
});

class StaffManagementScreen extends ConsumerWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(_staffListProvider);
    final showInactive = ref.watch(_showInactiveProvider);
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AiraColors.cream,
      appBar: AppBar(
        title: Text(l.manageStaff),
        actions: [
          // Toggle inactive
          IconButton(
            icon: Icon(showInactive ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 22),
            tooltip: l.isThai ? (showInactive ? 'ซ่อนพนักงานที่ปิดใช้งาน' : 'แสดงพนักงานทั้งหมด') : (showInactive ? 'Hide inactive' : 'Show all'),
            onPressed: () => ref.read(_showInactiveProvider.notifier).state = !showInactive,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: l.isThai ? 'เพิ่มพนักงาน' : 'Add staff',
            onPressed: () => _showStaffDialog(context, ref, null),
          ),
        ],
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(l.errorMsg('$e'))),
        data: (staffList) {
          if (staffList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AiraColors.woodWash.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.people_rounded, size: 32, color: AiraColors.muted.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.isThai ? 'ยังไม่มีพนักงาน' : 'No staff members yet',
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: AiraColors.muted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.isThai ? 'กดปุ่ม + เพื่อเพิ่มพนักงาน' : 'Tap + to add staff',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: staffList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _StaffCard(staff: staffList[i]),
          );
        },
      ),
    );
  }

  static void _showStaffDialog(BuildContext context, WidgetRef ref, Staff? existing) {
    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final nickCtrl = TextEditingController(text: existing?.nickname ?? '');
    final salaryCtrl = TextEditingController(text: existing?.baseSalary?.toStringAsFixed(0) ?? '');
    final roleNotifier = ValueNotifier<StaffRole>(existing?.role ?? StaffRole.receptionist);
    final activeNotifier = ValueNotifier<bool>(existing?.isActive ?? true);
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AiraColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF3D2517), Color(0xFF5A3E2B), Color(0xFF7B5840)]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(children: [
                  Icon(isEdit ? Icons.edit_rounded : Icons.person_add_rounded, size: 22, color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    isEdit
                        ? (context.l10n.isThai ? 'แก้ไขข้อมูลพนักงาน' : 'Edit Staff')
                        : (context.l10n.isThai ? 'เพิ่มพนักงานใหม่' : 'Add New Staff'),
                    style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  )),
                  AiraTapEffect(
                    onTap: () => Navigator.pop(ctx),
                    child: Icon(Icons.close_rounded, size: 20, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ]),
              ),
              // Form
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        style: airaFieldTextStyle,
                        decoration: airaFieldDecoration(
                          label: context.l10n.isThai ? 'ชื่อ-สกุล *' : 'Full Name *',
                          prefixIcon: Icons.person_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nickCtrl,
                        style: airaFieldTextStyle,
                        decoration: airaFieldDecoration(
                          label: context.l10n.nickname,
                          prefixIcon: Icons.badge_rounded,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ValueListenableBuilder<StaffRole>(
                        valueListenable: roleNotifier,
                        builder: (_, role, __) => DropdownButtonFormField<StaffRole>(
                          value: role,
                          style: airaFieldTextStyle,
                          decoration: airaFieldDecoration(
                            label: context.l10n.isThai ? 'บทบาท' : 'Role',
                            prefixIcon: Icons.admin_panel_settings_rounded,
                          ),
                          items: StaffRole.values.map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(_roleLabel(r, context.l10n), style: airaFieldTextStyle),
                          )).toList(),
                          onChanged: (v) { if (v != null) roleNotifier.value = v; },
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: salaryCtrl,
                        style: airaFieldTextStyle,
                        decoration: airaFieldDecoration(
                          label: context.l10n.isThai ? 'เงินเดือน (฿)' : 'Base Salary (฿)',
                          prefixIcon: Icons.payments_rounded,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      if (isEdit) ...[
                        const SizedBox(height: 14),
                        ValueListenableBuilder<bool>(
                          valueListenable: activeNotifier,
                          builder: (_, active, __) => SwitchListTile(
                            title: Text(
                              context.l10n.isThai ? 'เปิดใช้งาน' : 'Active',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            value: active,
                            activeColor: AiraColors.sage,
                            onChanged: (v) => activeNotifier.value = v,
                            contentPadding: EdgeInsets.zero,
                          ),
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
                        final repo = ref.read(staffRepoProvider);

                        final staff = Staff(
                          id: existing?.id ?? const Uuid().v4(),
                          clinicId: clinicId,
                          userId: existing?.userId,
                          fullName: nameCtrl.text.trim(),
                          nickname: nickCtrl.text.trim().isEmpty ? null : nickCtrl.text.trim(),
                          role: roleNotifier.value,
                          baseSalary: double.tryParse(salaryCtrl.text.trim()),
                          isActive: activeNotifier.value,
                          pinHash: existing?.pinHash,
                          avatarUrl: existing?.avatarUrl,
                        );

                        try {
                          if (isEdit) {
                            await repo.updateStaff(staff);
                          } else {
                            await repo.create(staff);
                          }
                          ref.invalidate(_staffListProvider);
                          ref.invalidate(currentStaffProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.saveSuccess), backgroundColor: AiraColors.sage),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.saveFailed('$e')), backgroundColor: AiraColors.terra),
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
    );
  }

  static String _roleLabel(StaffRole role, AppL10n l) {
    switch (role) {
      case StaffRole.owner: return l.owner;
      case StaffRole.doctor: return l.doctor;
      case StaffRole.receptionist: return l.receptionist;
    }
  }
}

class _StaffCard extends ConsumerWidget {
  final Staff staff;
  const _StaffCard({required this.staff});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final roleColor = _roleColor(staff.role);

    return AiraTapEffect(
      onTap: () => StaffManagementScreen._showStaffDialog(context, ref, staff),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: staff.isActive ? AiraColors.creamDk.withValues(alpha: 0.6) : AiraColors.terra.withValues(alpha: 0.2)),
          boxShadow: AiraShadows.card,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [roleColor.withValues(alpha: 0.2), roleColor.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: roleColor.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : '?',
                  style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: roleColor),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          staff.fullName,
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!staff.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: AiraColors.terra.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                          child: Text(l.isThai ? 'ปิดใช้งาน' : 'Inactive', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: AiraColors.terra)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (staff.nickname != null && staff.nickname!.isNotEmpty) ...[
                        Text('"${staff.nickname}"', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted, fontStyle: FontStyle.italic)),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          StaffManagementScreen._roleLabel(staff.role, l),
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: roleColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: AiraColors.muted.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  Color _roleColor(StaffRole role) {
    switch (role) {
      case StaffRole.owner: return const Color(0xFF8B6650);
      case StaffRole.doctor: return AiraColors.sage;
      case StaffRole.receptionist: return AiraColors.gold;
    }
  }
}
