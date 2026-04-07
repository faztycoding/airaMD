import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/access_guard.dart';
import '../../core/widgets/aira_tap_effect.dart';
import 'digital_notepad_screen.dart';
import 'photo_comparison_screen.dart';
import 'message_history_screen.dart';

// ═══════════════════════════════════════════════════════════════════
// PATIENT PROFILE SCREEN — Full-screen with gradient header + tabs
// ═══════════════════════════════════════════════════════════════════

class PatientProfileScreen extends ConsumerStatefulWidget {
  final String patientId;
  const PatientProfileScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends ConsumerState<PatientProfileScreen> {
  int _selectedSection = 0;

  List<_TabDef> _tabs(bool isThai) => [
    _TabDef(Icons.person_rounded, isThai ? 'ข้อมูลส่วนตัว' : 'Personal Info'),
    _TabDef(Icons.healing_rounded, isThai ? 'ประวัติสุขภาพ (HA)' : 'Health History (HA)'),
    _TabDef(Icons.draw_rounded, 'Face Diagram'),
    _TabDef(Icons.colorize_rounded, 'Injectables'),
    _TabDef(Icons.flash_on_rounded, 'Laser'),
    _TabDef(Icons.science_rounded, 'Treatments'),
    _TabDef(Icons.spa_rounded, isThai ? 'Anti-aging' : 'Anti-aging'),
    _TabDef(Icons.table_chart_rounded, isThai ? 'ตารางคอร์ส' : 'Course Table'),
    _TabDef(Icons.photo_library_rounded, 'Before & After'),
    _TabDef(Icons.description_rounded, isThai ? 'Consent Form' : 'Consent Form'),
    _TabDef(Icons.medication_rounded, isThai ? 'อาหารเสริม' : 'Supplements'),
    _TabDef(Icons.favorite_rounded, isThai ? 'ศัลยกรรม' : 'Surgery'),
    _TabDef(Icons.account_balance_wallet_rounded, 'Spending'),
    _TabDef(Icons.message_rounded, isThai ? 'ข้อความ' : 'Messages'),
    _TabDef(Icons.star_rounded, isThai ? 'สถานะคนไข้' : 'Patient Status'),
  ];

  @override
  Widget build(BuildContext context) {
    final patientAsync = ref.watch(patientByIdProvider(widget.patientId));
    final isThai = ref.watch(isThaiProvider);
    final tabs = _tabs(isThai);

    return patientAsync.when(
      data: (patient) {
        if (patient == null) {
          return Scaffold(
            backgroundColor: AiraColors.cream,
            body: Center(child: Text(isThai ? 'ไม่พบข้อมูลผู้รับบริการ' : 'Patient not found', style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AiraColors.muted))),
          );
        }
        return Scaffold(
          backgroundColor: AiraColors.cream,
          body: Column(
            children: [
              _ProfileHeader(
                patient: patient,
                onBack: () => context.pop(),
                onEdit: () => context.push('/patients/${patient.id}/edit'),
                onDelete: () => _confirmDeletePatient(context, ref, patient, isThai),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 960;
                    final horizontalPadding = isWide ? 24.0 : 12.0;
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1460),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 0),
                          child: isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 272,
                                      child: _buildSidebar(tabs),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(child: _buildContentShell(patient)),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildHorizontalPicker(tabs),
                                    const SizedBox(height: 12),
                                    Expanded(child: _buildContentShell(patient)),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(backgroundColor: AiraColors.cream, body: Center(child: CircularProgressIndicator(color: AiraColors.woodMid))),
      error: (e, _) => Scaffold(backgroundColor: AiraColors.cream, body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AiraColors.terra),
          const SizedBox(height: 12),
          Text(isThai ? 'โหลดข้อมูลไม่สำเร็จ' : 'Failed to load patient data', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal)),
          const SizedBox(height: 4),
          Text('$e', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => ref.invalidate(patientByIdProvider(widget.patientId)), child: Text(isThai ? 'ลองใหม่' : 'Retry')),
        ],
      ))),
    );
  }

  void _confirmDeletePatient(BuildContext context, WidgetRef ref, Patient patient, bool isThai) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: AiraColors.terra.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_rounded, size: 30, color: AiraColors.terra),
        ),
        title: Text(
          isThai ? 'ลบผู้รับบริการออกจากระบบ?' : 'Remove patient?',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isThai
                  ? 'ข้อมูลของ "${patient.fullName}" จะถูกซ่อนจากระบบ แต่ยังคงเก็บไว้ในฐานข้อมูลตามข้อกำหนดทางการแพทย์'
                  : 'Data for "${patient.fullName}" will be hidden but preserved in the database for medical compliance.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AiraColors.terra.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AiraColors.terra),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isThai ? 'การกระทำนี้สามารถกู้คืนได้ภายหลัง' : 'This action can be reversed later.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.terra),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isThai ? 'ยกเลิก' : 'Cancel', style: GoogleFonts.plusJakartaSans(color: AiraColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AiraColors.terra,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = ref.read(patientRepoProvider);
                await repo.softDelete(patient.id);
                ref.invalidate(patientListProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isThai ? 'ลบ "${patient.fullName}" ออกจากระบบแล้ว' : '"${patient.fullName}" removed',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: AiraColors.terra,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AiraColors.terra),
                  );
                }
              }
            },
            child: Text(isThai ? 'ยืนยันลบ' : 'Confirm Delete', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(List<_TabDef> tabs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          return _ProfileSectionNavItem(
            icon: tab.icon,
            label: tab.label,
            selected: index == _selectedSection,
            onTap: () => setState(() => _selectedSection = index),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalPicker(List<_TabDef> tabs) {
    return SizedBox(
      height: 54,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final selected = index == _selectedSection;
            return Padding(
              padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 8),
              child: AiraTapEffect(
                onTap: () => setState(() => _selectedSection = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AiraColors.woodDk : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AiraColors.woodDk : AiraColors.woodPale.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab.icon, size: 16, color: selected ? Colors.white : AiraColors.woodDk),
                      const SizedBox(width: 8),
                      Text(
                        tab.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : AiraColors.charcoal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildContentShell(Patient patient) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: _buildSectionContent(patient),
    );
  }

  Widget _buildSectionContent(Patient patient) {
    final canManageClinicalData = ref.watch(canManageClinicalDataProvider);
    final canAccessFinancialData = ref.watch(canAccessFinancialDataProvider);
    switch (_selectedSection) {
      case 0:
        return _InfoTab(patient: patient);
      case 1:
        return _HATab(patient: patient);
      case 2: // Face Diagram + Digital Notepad embedded
        if (!canManageClinicalData) {
          return const InlineAccessGuard(permission: AiraPermission.clinical);
        }
        return _FaceDiagramWithNotepad(patientId: patient.id);
      case 3:
        if (!canManageClinicalData) {
          return const InlineAccessGuard(permission: AiraPermission.clinical);
        }
        return _TreatmentListTab(patientId: patient.id, category: 'INJECTABLE', label: 'Injectable');
      case 4:
        if (!canManageClinicalData) {
          return const InlineAccessGuard(permission: AiraPermission.clinical);
        }
        return _TreatmentListTab(patientId: patient.id, category: 'LASER', label: 'Laser');
      case 5:
        if (!canManageClinicalData) {
          return const InlineAccessGuard(permission: AiraPermission.clinical);
        }
        return _TreatmentListTab(patientId: patient.id, category: 'TREATMENT', label: 'Treatment');
      case 6:
        if (!canManageClinicalData) {
          return const InlineAccessGuard(permission: AiraPermission.clinical);
        }
        return _AntiAgingTab(patientId: patient.id);
      case 7:
        if (!canAccessFinancialData) {
          return const InlineAccessGuard(permission: AiraPermission.financial);
        }
        return _CourseOverviewSection(patientId: patient.id);
      case 8:
        if (!canManageClinicalData) {
          return const InlineAccessGuard(permission: AiraPermission.clinical);
        }
        return _PhotosTab(patientId: patient.id);
      case 9: // Consent Form
        if (!canManageClinicalData) {
          return const InlineAccessGuard(permission: AiraPermission.clinical);
        }
        return _ConsentFormTab(patientId: patient.id);
      case 10: // Supplements
        if (!canManageClinicalData) {
          return const InlineAccessGuard(permission: AiraPermission.clinical);
        }
        return _SupplementsTab(patientId: patient.id);
      case 11:
        if (!canManageClinicalData) {
          return const InlineAccessGuard(permission: AiraPermission.clinical);
        }
        return _SurgeryTab();
      case 12:
        if (!canAccessFinancialData) {
          return const InlineAccessGuard(permission: AiraPermission.financial);
        }
        return _FinanceTab(patientId: patient.id);
      case 13: // Messages
        return MessageHistoryTab(patientId: patient.id, patient: patient);
      case 14: // Patient Status (hidden from patients)
        return _PatientStatusTab(patient: patient);
      default:
        return _InfoTab(patient: patient);
    }
  }
}

class _TabDef {
  final IconData icon;
  final String label;
  const _TabDef(this.icon, this.label);
}

class _ProfileSectionNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ProfileSectionNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AiraColors.woodDk.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AiraColors.woodDk.withValues(alpha: 0.22) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? AiraColors.woodDk : AiraColors.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AiraColors.charcoal : AiraColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// PROFILE HEADER — Brown gradient with avatar, name, badges, actions
// ═══════════════════════════════════════════════════════════════════

class _ProfileHeader extends ConsumerWidget {
  final Patient patient;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ProfileHeader({required this.patient, required this.onBack, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5A3E2B), Color(0xFF7B5B43), Color(0xFFBE9B7D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // ─── Top bar: back + language toggle ───
          Row(
            children: [
              AiraTapEffect(
                onTap: onBack,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              _LangPill(),
            ],
          ),
          const SizedBox(height: 16),
          // ─── Avatar circle ───
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Center(
              child: Text(
                patient.firstName.isNotEmpty ? patient.firstName[0] : '?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ─── Name + VIP badge ───
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                patient.fullName,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2,
                ),
              ),
              if (patient.status == PatientStatus.vip) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFC4922A), Color(0xFFD4A84A)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('VIP', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
              if (patient.status == PatientStatus.star) ...[
                const SizedBox(width: 8),
                Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (_) => const Icon(Icons.star_rounded, size: 14, color: Color(0xFFC4922A)))),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (patient.nickname != null && patient.nickname!.isNotEmpty)
            Text(
              'ชื่อเล่น: ${patient.nickname}',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.white.withValues(alpha: 0.7)),
            ),
          const SizedBox(height: 2),
          Text(
            '${patient.age != null ? "อายุ ${patient.age} ปี" : ""}${patient.hn != null ? " • HN: ${patient.hn}" : ""}',
            style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 14),
          // ─── Action buttons ───
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeaderActionBtn(
                icon: Icons.chat_rounded,
                label: 'LINE',
                color: const Color(0xFF06C755),
              ),
              const SizedBox(width: 10),
              _HeaderActionBtn(
                icon: Icons.message_rounded,
                label: isThai ? 'ข้อความ' : 'Message',
                color: Colors.white.withValues(alpha: 0.15),
                textColor: Colors.white,
              ),
              const SizedBox(width: 10),
              AiraTapEffect(
                onTap: onEdit,
                child: _HeaderActionBtn(
                  icon: Icons.edit_rounded,
                  label: isThai ? 'แก้ไข' : 'Edit',
                  color: Colors.white.withValues(alpha: 0.15),
                  textColor: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              AiraTapEffect(
                onTap: onDelete,
                child: _HeaderActionBtn(
                  icon: Icons.delete_outline_rounded,
                  label: isThai ? 'ลบ' : 'Delete',
                  color: const Color(0xFFD32F2F).withValues(alpha: 0.25),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  const _HeaderActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isThai = ref.watch(isThaiProvider);
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AiraTapEffect(
                onTap: () {
                  ref.read(localeProvider.notifier).state = const Locale('th', 'TH');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isThai ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'TH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              AiraTapEffect(
                onTap: () {
                  ref.read(localeProvider.notifier).state = const Locale('en', 'US');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isThai ? Colors.transparent : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'EN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 1: ข้อมูล (Info) — Personal info, status, ID docs
// ═══════════════════════════════════════════════════════════════════

class _InfoTab extends ConsumerWidget {
  final Patient patient;
  const _InfoTab({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          title: isThai ? 'ข้อมูลส่วนตัว' : 'Personal Info',
          children: [
            _InfoRow(isThai ? 'ชื่อ / ชื่อเล่น' : 'Name / Nickname', '${patient.fullName}${patient.nickname != null ? "\n${patient.nickname}" : ""}'),
            if (patient.dateOfBirth != null)
              _InfoRow(isThai ? 'วันเกิด' : 'Date of Birth', '${patient.dateOfBirth!.day}/${patient.dateOfBirth!.month}/${patient.dateOfBirth!.year} (${patient.age} ${isThai ? 'ปี' : 'yrs'})'),
            if (patient.gender != null) _InfoRow(isThai ? 'เพศ' : 'Gender', patient.gender!.label(isThai: isThai)),
            if (patient.phone != null) _InfoRow(isThai ? 'เบอร์โทร' : 'Phone', patient.phone!),
            if (patient.lineId != null) _InfoRow('Line ID', patient.lineId!),
            if (patient.email != null) _InfoRow('Email', patient.email!),
            if (patient.address != null) _InfoRow(isThai ? 'ที่อยู่' : 'Address', patient.address!),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: isThai ? 'เอกสารยืนยันตัวตน' : 'Identification Documents',
          icon: Icons.badge_rounded,
          iconColor: AiraColors.woodMid,
          children: [
            if (patient.nationalId != null) _InfoRow(isThai ? 'บัตรประชาชน' : 'National ID Card', patient.nationalId!),
            if (patient.passportNo != null) _InfoRow(isThai ? 'พาสปอร์ต' : 'Passport', patient.passportNo!),
            if (patient.nationalId == null && patient.passportNo == null)
              Text(isThai ? 'ยังไม่มีข้อมูลเอกสาร' : 'No documents on file', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted)),
          ],
        ),
        if (patient.notes != null && patient.notes!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionCard(title: isThai ? 'หมายเหตุ' : 'Notes', children: [
            Text(patient.notes!, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.charcoal)),
          ]),
        ],
      ],
    );
  }
}

class _StatusSelector extends StatelessWidget {
  final PatientStatus current;
  const _StatusSelector({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatusChipSelect('ปกติ', current == PatientStatus.normal, AiraColors.sage)),
        const SizedBox(width: 10),
        Expanded(child: _StatusChipSelect('VIP', current == PatientStatus.vip, AiraColors.gold)),
        const SizedBox(width: 10),
        Expanded(child: _StatusChipSelect('STAR', current == PatientStatus.star, AiraColors.terra)),
      ],
    );
  }
}

class _StatusChipSelect extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  const _StatusChipSelect(this.label, this.selected, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.12) : AiraColors.parchment,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? color.withValues(alpha: 0.4) : AiraColors.woodPale.withValues(alpha: 0.2),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? color : AiraColors.muted,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 2: HA — Allergies, medical history
// ═══════════════════════════════════════════════════════════════════

class _HATab extends ConsumerWidget {
  final Patient patient;
  const _HATab({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final hasAllergies = patient.drugAllergies.isNotEmpty;
    final hasConditions = patient.medicalConditions.isNotEmpty;
    final yes = isThai ? 'ใช่' : 'Yes';
    final no = isThai ? 'ไม่ใช่' : 'No';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          title: isThai ? 'แพ้ยา' : 'Drug Allergies',
          icon: Icons.warning_amber_rounded,
          iconColor: AiraColors.danger,
          children: [
            if (hasAllergies) ...[
              Wrap(
                spacing: 8, runSpacing: 8,
                children: patient.drugAllergies.map((a) => _AllergyChip(a)).toList(),
              ),
              if (patient.allergySymptoms != null) ...[
                const SizedBox(height: 8),
                _InfoRow(isThai ? 'อาการ' : 'Symptoms', patient.allergySymptoms!),
              ],
            ] else
              Text(isThai ? 'ไม่มีประวัติแพ้ยา' : 'No drug allergies', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: isThai ? 'โรคประจำตัว' : 'Medical Conditions',
          children: [
            if (hasConditions)
              Wrap(
                spacing: 8, runSpacing: 8,
                children: patient.medicalConditions.map((c) => _ConditionChip(c)).toList(),
              )
            else
              Text(isThai ? 'ไม่มีโรคประจำตัว' : 'No medical conditions', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: isThai ? 'บุหรี่ / แอลกอฮอล์ / ยา' : 'Smoking / Alcohol / Medication',
          children: [
            _InfoRow(isThai ? 'สูบบุหรี่' : 'Smoking', patient.smoking.label(isThai: isThai)),
            _InfoRow(isThai ? 'แอลกอฮอล์' : 'Alcohol', patient.alcohol.label(isThai: isThai)),
            _InfoRow(isThai ? 'ใช้เรตินอยด์' : 'Using Retinoids', patient.isUsingRetinoids ? yes : no),
            _InfoRow(isThai ? 'ยาต้านการแข็งตัวของเลือด' : 'On Anticoagulant', patient.isOnAnticoagulant ? yes : no),
          ],
        ),
      ],
    );
  }
}

class _AllergyChip extends StatelessWidget {
  final String label;
  const _AllergyChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AiraColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AiraColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_rounded, size: 14, color: AiraColors.danger),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AiraColors.danger)),
        ],
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  final String label;
  const _ConditionChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AiraColors.sage.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AiraColors.sage.withValues(alpha: 0.25)),
      ),
      child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.sage)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 3-5: Treatment List Tabs (Injectable / Laser / Treatment)
// ═══════════════════════════════════════════════════════════════════

class _TreatmentListTab extends ConsumerWidget {
  final String patientId;
  final String category;
  final String label;
  const _TreatmentListTab({required this.patientId, required this.category, required this.label});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treatmentsAsync = ref.watch(_treatmentsByPatientCategoryProvider((patientId: patientId, category: category)));

    return treatmentsAsync.when(
      data: (treatments) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AiraTapEffect(
            onTap: () => context.push('/patients/$patientId/treatments/new?category=$category'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Center(
                child: Text('+ บันทึก $label ใหม่', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...treatments.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TreatmentCard(
                  date: _formatDate(t.date),
                  title: '${_categoryIcon(category)} ${t.treatmentName}',
                  subtitle: t.chiefComplaint,
                  products: [],
                  category: category,
                ),
              )),
          if (treatments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 48, color: AiraColors.muted.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    Text('ยังไม่มีบันทึก $label', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted)),
                  ],
                ),
              ),
            ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  String _categoryIcon(String cat) {
    switch (cat) {
      case 'INJECTABLE': return '💉';
      case 'LASER': return '⚡';
      default: return '🧪';
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _TreatmentCard extends StatelessWidget {
  final String date;
  final String title;
  final String? subtitle;
  final List<String> products;
  final String category;
  const _TreatmentCard({
    required this.date,
    required this.title,
    this.subtitle,
    required this.products,
    required this.category,
  });

  Color get _accentColor {
    switch (category) {
      case 'INJECTABLE': return AiraColors.woodMid;
      case 'LASER': return AiraColors.gold;
      default: return AiraColors.sage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: _accentColor, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                      ),
                    ),
                    Icon(Icons.expand_more_rounded, color: AiraColors.muted.withValues(alpha: 0.5), size: 22),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted)),
                ],
              ],
            ),
          ),
          // ─── Product chips ───
          if (products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: products
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _accentColor.withValues(alpha: 0.15)),
                          ),
                          child: Text(p, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: _accentColor)),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// (Old _NewRecordTab removed — merged into Face Diagram tab in Phase 2)

class _FaceDiagramSection extends ConsumerWidget {
  final String patientId;
  const _FaceDiagramSection({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final diagramsAsync = ref.watch(diagramsByPatientProvider(patientId));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ─── New Diagram Button ───
        AiraTapEffect(
          onTap: () => context.push('/patients/$patientId/diagram'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  isThai ? 'สร้าง Diagram ใหม่' : 'New Diagram',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ─── Saved Diagrams List ───
        _SectionCard(
          title: isThai ? 'Diagram ที่บันทึกแล้ว' : 'Saved Diagrams',
          icon: Icons.draw_rounded,
          iconColor: AiraColors.woodMid,
          children: [
            Text(
              isThai
                  ? 'แต่ละ Diagram บันทึกแยกครั้ง เซฟแล้วแก้ไขไม่ได้ (Immutable Lock)'
                  : 'Each diagram is saved separately and cannot be edited after saving.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted),
            ),
            const SizedBox(height: 12),
            diagramsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error: $e',
                  style: GoogleFonts.plusJakartaSans(color: AiraColors.terra)),
              data: (diagrams) {
                if (diagrams.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AiraColors.parchment,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.draw_rounded, size: 36, color: AiraColors.muted.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text(
                          isThai ? 'ยังไม่มี Diagram' : 'No diagrams yet',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AiraColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // Group diagrams by session (same minute)
                const viewOrder = [DiagramView.front, DiagramView.leftSide, DiagramView.rightSide, DiagramView.side, DiagramView.lipZone];
                final Map<String, List<FaceDiagram>> sessions = {};
                for (final d in diagrams) {
                  final key = d.createdAt != null
                      ? '${d.createdAt!.year}-${d.createdAt!.month}-${d.createdAt!.day} ${d.createdAt!.hour}:${d.createdAt!.minute}'
                      : 'unknown';
                  sessions.putIfAbsent(key, () => []).add(d);
                }
                // Sort each group by view order
                for (final g in sessions.values) {
                  g.sort((a, b) => viewOrder.indexOf(a.viewType).compareTo(viewOrder.indexOf(b.viewType)));
                }

                return Column(
                  children: sessions.entries.map((entry) {
                    final group = entry.value;
                    final first = group.first;
                    final dateStr = first.createdAt != null
                        ? '${first.createdAt!.day}/${first.createdAt!.month}/${first.createdAt!.year}  ${first.createdAt!.hour.toString().padLeft(2, '0')}:${first.createdAt!.minute.toString().padLeft(2, '0')}'
                        : '-';

                    String viewLabel(DiagramView v) => switch (v) {
                      DiagramView.front => isThai ? 'ด้านหน้า' : 'Front',
                      DiagramView.side => isThai ? 'ด้านข้าง' : 'Side',
                      DiagramView.leftSide => isThai ? 'ด้านซ้าย' : 'Left',
                      DiagramView.rightSide => isThai ? 'ด้านขวา' : 'Right',
                      DiagramView.lipZone => isThai ? 'ริมฝีปาก' : 'Lip',
                    };

                    IconData viewIcon(DiagramView v) => switch (v) {
                      DiagramView.front => Icons.face_rounded,
                      DiagramView.side => Icons.face_3_rounded,
                      DiagramView.leftSide => Icons.face_3_rounded,
                      DiagramView.rightSide => Icons.face_3_rounded,
                      DiagramView.lipZone => Icons.mood_rounded,
                    };

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.18)),
                          boxShadow: [
                            BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── Header: date + lock badge ───
                            Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AiraColors.woodPale.withValues(alpha: 0.25), AiraColors.gold.withValues(alpha: 0.15)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.draw_rounded, size: 18, color: AiraColors.woodMid),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isThai ? 'บันทึก Diagram' : 'Diagram Session',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                                      ),
                                      Text(
                                        dateStr,
                                        style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AiraColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AiraColors.terra.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.lock_rounded, size: 12, color: AiraColors.terra),
                                      const SizedBox(width: 3),
                                      Text(
                                        isThai ? 'ล็อก' : 'Locked',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AiraColors.terra),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // ─── View pills — one per view in this session ───
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: group.map((d) {
                                return AiraTapEffect(
                                  onTap: () => context.push('/patients/$patientId/diagram?diagramId=${d.id}'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AiraColors.parchment,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(viewIcon(d.viewType), size: 16, color: AiraColors.woodMid),
                                        const SizedBox(width: 6),
                                        Text(
                                          viewLabel(d.viewType),
                                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.charcoal),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right_rounded, size: 14, color: AiraColors.muted),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${group.length} ${isThai ? 'มุมมอง' : 'views'}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _CourseOverviewSection extends ConsumerWidget {
  final String patientId;
  const _CourseOverviewSection({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesByPatientProvider(patientId));
    return coursesAsync.when(
      data: (courses) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
                  'เปิดตารางคอร์สทั้งหมด',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AiraColors.woodDk),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...courses.map((course) {
            final total = course.sessionsTotal ?? (course.sessionsBought + course.sessionsBonus);
            final detail = 'ซื้อ ${course.sessionsBought} แถม ${course.sessionsBonus}'
                '${course.expiryDate != null ? ' • ครบกำหนด ${course.expiryDate!.day}/${course.expiryDate!.month}/${course.expiryDate!.year}' : ' • ไม่กำหนดวันหมดอายุ'}'
                '${course.price != null ? ' • ฿${course.price!.toStringAsFixed(0)}' : ''}';
            final color = switch (course.status) {
              CourseStatus.completed => AiraColors.sage,
              CourseStatus.low => AiraColors.gold,
              CourseStatus.expired => AiraColors.terra,
              CourseStatus.active => AiraColors.woodMid,
            };
            final statusLabel = switch (course.status) {
              CourseStatus.completed => 'ครบแล้ว',
              CourseStatus.low => 'ใกล้หมด',
              CourseStatus.expired => 'หมดอายุ',
              CourseStatus.active => 'ใช้อยู่',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CourseCard(
                name: course.name,
                detail: detail,
                sessionsTotal: total,
                sessionsUsed: course.sessionsUsed,
                color: color,
                statusLabel: statusLabel,
              ),
            );
          }),
          if (courses.isEmpty)
            _SectionCard(
              title: 'ยังไม่มีคอร์ส',
              children: [
                Text(
                  'กดเปิดตารางคอร์สเพื่อสร้างคอร์สใหม่หรือดูรายการทั้งหมดของคนไข้รายนี้',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
                ),
              ],
            ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _NewRecordTypeBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _NewRecordTypeBtn(this.icon, this.label, this.color, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 7: รูปภาพ (Photos) — Before / After panels
// ═══════════════════════════════════════════════════════════════════

// Provider for treatment records filtered by patient + category
final _treatmentsByPatientCategoryProvider = FutureProvider.family<List<TreatmentRecord>, ({String patientId, String category})>((ref, params) async {
  final repo = ref.watch(treatmentRepoProvider);
  final all = await repo.getByPatient(patientId: params.patientId);
  return all.where((t) => t.category.dbValue == params.category).toList();
});

final _beforeAfterPairsProvider = FutureProvider.family<Map<String, List<PatientPhoto>>, String>((ref, patientId) async {
  final repo = ref.watch(photoRepoProvider);
  return repo.getBeforeAfterPairs(patientId: patientId);
});

class _PhotosTab extends ConsumerStatefulWidget {
  final String patientId;
  const _PhotosTab({required this.patientId});
  @override
  ConsumerState<_PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends ConsumerState<_PhotosTab> {
  final _picker = ImagePicker();
  bool _uploading = false;

  // ─── Helpers ───
  static const _photoTypes = [
    (type: PhotoType.angleFront, label: 'Front', thLabel: 'หน้าตรง'),
    (type: PhotoType.angleLeft45, label: 'Left 45°', thLabel: '45° ซ้าย'),
    (type: PhotoType.angleLeft90, label: 'Left 90°', thLabel: '90° ซ้าย'),
    (type: PhotoType.angleRight45, label: 'Right 45°', thLabel: '45° ขวา'),
    (type: PhotoType.angleRight90, label: 'Right 90°', thLabel: '90° ขวา'),
  ];

  PatientPhoto? _findByType(List<PatientPhoto> photos, PhotoType type) {
    for (final p in photos) {
      if (p.imageType == type) return p;
    }
    return null;
  }

  String _photoUrl(PatientPhoto photo) {
    final path = (photo.thumbnailPath?.isNotEmpty ?? false) ? photo.thumbnailPath! : photo.storagePath;
    if (path.startsWith('http')) return path;
    return Supabase.instance.client.storage.from(AppConstants.bucketPatientPhotos).getPublicUrl(path);
  }

  // ─── Create new comparison set ───
  Future<void> _createNewSet(bool isThai) async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isThai ? 'สร้างชุดเปรียบเทียบใหม่' : 'New Comparison Set',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isThai ? 'ตั้งชื่อชุดเปรียบเทียบ เช่น "Botox หน้าผาก" หรือ "Filler ปาก"' : 'Name this set, e.g. "Botox Forehead"',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: InputDecoration(
                hintText: isThai ? 'ชื่อชุดเปรียบเทียบ' : 'Set name',
                hintStyle: GoogleFonts.plusJakartaSans(color: AiraColors.muted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isThai ? 'ยกเลิก' : 'Cancel', style: GoogleFonts.plusJakartaSans(color: AiraColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AiraColors.woodMid,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            child: Text(isThai ? 'สร้าง' : 'Create', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (label == null || label.isEmpty) return;

    // Create an initial "before" placeholder record so the set appears
    final clinicId = ref.read(currentClinicIdProvider);
    if (clinicId == null) return;
    try {
      final repo = ref.read(photoRepoProvider);
      await repo.create(PatientPhoto(
        id: '',
        clinicId: clinicId,
        patientId: widget.patientId,
        imageType: PhotoType.before,
        storagePath: '',
        description: label,
        treatmentDate: DateTime.now(),
      ));
      ref.invalidate(_beforeAfterPairsProvider(widget.patientId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AiraColors.terra),
        );
      }
    }
  }

  // ─── Pick & upload photo for a slot ───
  Future<void> _uploadPhoto(String setLabel, PhotoType type, bool isThai) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 2048, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final clinicId = ref.read(currentClinicIdProvider);
      if (clinicId == null) throw Exception('No clinic');
      final bytes = await picked.readAsBytes();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = picked.name.split('.').last;
      final storagePath = '$clinicId/${widget.patientId}/ba_${ts}_${type.dbValue}.$ext';

      await Supabase.instance.client.storage
          .from(AppConstants.bucketPatientPhotos)
          .uploadBinary(storagePath, bytes, fileOptions: FileOptions(contentType: 'image/$ext', upsert: true));

      final repo = ref.read(photoRepoProvider);
      await repo.create(PatientPhoto(
        id: '',
        clinicId: clinicId,
        patientId: widget.patientId,
        imageType: type,
        storagePath: storagePath,
        description: setLabel,
        treatmentDate: DateTime.now(),
      ));
      ref.invalidate(_beforeAfterPairsProvider(widget.patientId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isThai ? 'อัพโหลดรูปสำเร็จ' : 'Photo uploaded', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: AiraColors.sage,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('Bucket not found')
            ? (isThai ? 'กรุณาสร้าง Storage Bucket "patient-photos" ใน Supabase Dashboard' : 'Create "patient-photos" bucket in Supabase')
            : 'Error: $e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AiraColors.terra));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isThai = ref.watch(isThaiProvider);
    final pairsAsync = ref.watch(_beforeAfterPairsProvider(widget.patientId));

    return Stack(
      children: [
        pairsAsync.when(
          data: (pairs) {
            // Group by description instead of treatment_record_id
            final Map<String, List<PatientPhoto>> grouped = {};
            for (final entry in pairs.values) {
              for (final photo in entry) {
                final key = (photo.description?.isNotEmpty ?? false) ? photo.description! : 'ชุดเปรียบเทียบ';
                grouped.putIfAbsent(key, () => []).add(photo);
              }
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ─── New Set Button ───
                AiraTapEffect(
                  onTap: () => _createNewSet(isThai),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo_rounded, size: 20, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          isThai ? 'สร้างชุดเปรียบเทียบใหม่' : 'New Comparison Set',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Info Card ───
                _SectionCard(
                  title: 'Before & After',
                  icon: Icons.photo_library_rounded,
                  iconColor: AiraColors.woodMid,
                  children: [
                    Text(
                      isThai
                          ? 'เปรียบเทียบ Before / After แต่ละมุม: หน้าตรง, 45° ซ้าย, 90° ซ้าย, 45° ขวา, 90° ขวา'
                          : 'Compare Before / After for each angle: Front, Left 45°, Left 90°, Right 45°, Right 90°',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── Empty State ───
                if (grouped.isEmpty)
                  _SectionCard(
                    title: isThai ? 'ยังไม่มีรูปเปรียบเทียบ' : 'No comparison photos yet',
                    children: [
                      Text(
                        isThai
                            ? 'กดปุ่ม "สร้างชุดเปรียบเทียบใหม่" ด้านบน แล้วอัพโหลดรูป Before/After ได้เลย'
                            : 'Tap "New Comparison Set" above to start uploading Before/After photos.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
                      ),
                    ],
                  ),

                // ─── Comparison Sets ───
                ...grouped.entries.map((entry) {
                  final setLabel = entry.key;
                  final photos = entry.value;
                  final firstDate = photos.firstWhere((p) => p.treatmentDate != null, orElse: () => photos.first).treatmentDate;
                  final dateStr = firstDate != null ? '${firstDate.day}/${firstDate.month}/${firstDate.year}' : '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.18)),
                        boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [AiraColors.gold.withValues(alpha: 0.3), AiraColors.woodPale.withValues(alpha: 0.2)]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.compare_rounded, size: 18, color: AiraColors.woodMid),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(setLabel, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
                                    if (dateStr.isNotEmpty)
                                      Text(dateStr, style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AiraColors.muted)),
                                  ],
                                ),
                              ),
                              Text(
                                '${photos.where((p) => p.storagePath.isNotEmpty).length}/10',
                                style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AiraColors.woodMid),
                              ),
                              const SizedBox(width: 8),
                              AiraTapEffect(
                                onTap: () => _openComparison(setLabel, photos, isThai),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.compare_rounded, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(isThai ? 'เปรียบเทียบ' : 'Compare', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // ─── Before / After grid per angle ───
                          ...['angleFront', 'angleLeft45', 'angleLeft90', 'angleRight45', 'angleRight90'].map((angleKey) {
                            final slot = _photoTypes.firstWhere((s) => s.type.name == angleKey);
                            return _CollapsibleAngleCard(
                              slot: slot,
                              setLabel: setLabel,
                              photos: photos,
                              isThai: isThai,
                              onUpload: _uploadPhoto,
                              onView: _showFullPhoto,
                              photoUrl: _photoUrl,
                              findByType: _findByType,
                              slotPlaceholder: _buildSlotPlaceholder,
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        if (_uploading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
      ],
    );
  }

  Widget _buildSlotPlaceholder(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AiraColors.woodPale.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.3), style: BorderStyle.solid),
      ),
      child: Center(
        child: Icon(icon, size: 24, color: AiraColors.muted.withValues(alpha: 0.4)),
      ),
    );
  }

  void _openComparison(String setLabel, List<PatientPhoto> photos, bool isThai) {
    // Build comparison slots: Before + After for the front angle,
    // then Before + After for other angles that have photos
    final slots = <ComparisonSlot>[];
    for (final pt in _photoTypes) {
      final before = _findByType(photos, pt.type);
      if (before != null && before.storagePath.isNotEmpty) {
        slots.add(ComparisonSlot(
          label: '${isThai ? pt.thLabel : pt.label} — BEFORE',
          imageUrl: _photoUrl(before),
          dateLabel: before.treatmentDate != null ? '${before.treatmentDate!.day}/${before.treatmentDate!.month}/${before.treatmentDate!.year}' : null,
        ));
      }
      // Check for after photo
      final afterDesc = '${setLabel}_after_${pt.type.name}';
      final afterPhoto = photos.where((p) => p.description == afterDesc && p.storagePath.isNotEmpty).isEmpty
          ? null
          : photos.firstWhere((p) => p.description == afterDesc && p.storagePath.isNotEmpty);
      if (afterPhoto != null) {
        slots.add(ComparisonSlot(
          label: '${isThai ? pt.thLabel : pt.label} — AFTER',
          imageUrl: _photoUrl(afterPhoto),
          dateLabel: afterPhoto.treatmentDate != null ? '${afterPhoto.treatmentDate!.day}/${afterPhoto.treatmentDate!.month}/${afterPhoto.treatmentDate!.year}' : null,
        ));
      }
    }
    // Take up to 4 slots for comparison
    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isThai ? 'ยังไม่มีรูปให้เปรียบเทียบ' : 'No photos to compare'),
          backgroundColor: AiraColors.terra,
        ),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PhotoComparisonScreen(
        setLabel: setLabel,
        slots: slots.take(4).toList(),
      ),
    ));
  }

  void _showFullPhoto(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8, right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 7: Anti-aging — Anti-aging treatments
// ═══════════════════════════════════════════════════════════════════

class _AntiAgingTab extends StatelessWidget {
  final String patientId;
  const _AntiAgingTab({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AiraTapEffect(
          onTap: () => context.push('/patients/$patientId/treatments/new?category=OTHER'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 6),
                Text('+ บันทึก Anti-aging ใหม่', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Anti-aging Treatments',
          icon: Icons.spa_rounded,
          iconColor: AiraColors.gold,
          children: [
            Text(
              'บันทึกการรักษา Anti-aging เช่น HIFU, Thermage, Ultherapy, ร้อยไหม, และการรักษาฟื้นฟูผิวอื่นๆ',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
            ),
            const SizedBox(height: 16),
            _AntiAgingItem('HIFU / Ultherapy', 'ยกกระชับผิวหน้า', ['1 เดือน', '3 เดือน', '6 เดือน'], patientId: patientId),
            const Divider(height: 24),
            _AntiAgingItem('Thermage FLX', 'กระชับรูขุมขน', ['1 เดือน', '3 เดือน', '6 เดือน', '1 ปี'], patientId: patientId),
            const Divider(height: 24),
            _AntiAgingItem('ร้อยไหม', 'ยกกระชับใบหน้า', ['1 เดือน', '3 เดือน', '6 เดือน', '1 ปี'], patientId: patientId),
          ],
        ),
      ],
    );
  }
}

class _AntiAgingItem extends StatefulWidget {
  final String name;
  final String desc;
  final List<String> timeline;
  final String patientId;
  const _AntiAgingItem(this.name, this.desc, this.timeline, {required this.patientId});

  @override
  State<_AntiAgingItem> createState() => _AntiAgingItemState();
}

class _AntiAgingItemState extends State<_AntiAgingItem> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.spa_rounded, size: 14, color: AiraColors.gold),
            const SizedBox(width: 6),
            Expanded(child: Text(widget.name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal))),
            AiraTapEffect(
              onTap: () => context.push('/patients/${widget.patientId}/treatments/new?category=OTHER'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AiraColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('+ บันทึก', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AiraColors.gold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: widget.timeline.asMap().entries.map((e) {
            final selected = _selectedIndex == e.key;
            return AiraTapEffect(
              onTap: () => setState(() => _selectedIndex = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AiraColors.gold.withValues(alpha: 0.18) : AiraColors.parchment,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AiraColors.gold : AiraColors.woodPale.withValues(alpha: 0.3),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  e.value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AiraColors.gold : AiraColors.muted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 6),
        Text('✨ ${widget.desc}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.gold)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Before/After Collapsible Angle Card Widget
// ═══════════════════════════════════════════════════════════════════

class _CollapsibleAngleCard extends StatefulWidget {
  final ({PhotoType type, String label, String thLabel}) slot;
  final String setLabel;
  final List<PatientPhoto> photos;
  final bool isThai;
  final Function(String, PhotoType, bool) onUpload;
  final Function(BuildContext, String) onView;
  final String Function(PatientPhoto) photoUrl;
  final PatientPhoto? Function(List<PatientPhoto>, PhotoType) findByType;
  final Widget Function(IconData) slotPlaceholder;

  const _CollapsibleAngleCard({
    required this.slot,
    required this.setLabel,
    required this.photos,
    required this.isThai,
    required this.onUpload,
    required this.onView,
    required this.photoUrl,
    required this.findByType,
    required this.slotPlaceholder,
  });

  @override
  State<_CollapsibleAngleCard> createState() => _CollapsibleAngleCardState();
}

class _CollapsibleAngleCardState extends State<_CollapsibleAngleCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final angleLabel = widget.isThai ? widget.slot.thLabel : widget.slot.label;
    final beforePhoto = widget.findByType(widget.photos, widget.slot.type);
    final hasBeforeImg = beforePhoto != null && beforePhoto.storagePath.isNotEmpty;
    final afterPhoto = widget.photos.where((p) => p.description == '${widget.setLabel}_after_${widget.slot.type.name}' && p.storagePath.isNotEmpty).isEmpty
        ? null
        : widget.photos.firstWhere((p) => p.description == '${widget.setLabel}_after_${widget.slot.type.name}' && p.storagePath.isNotEmpty);
    final hasAfterImg = afterPhoto != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AiraColors.parchment,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            // ─── Collapsible Header ───
            AiraTapEffect(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: AiraColors.woodDk.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.vertical(
                    top: const Radius.circular(16),
                    bottom: Radius.circular(_isExpanded ? 0 : 16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: AiraColors.woodMid),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        angleLabel,
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                      ),
                    ),
                    // Photo count indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (hasBeforeImg || hasAfterImg) ? AiraColors.sage.withValues(alpha: 0.15) : AiraColors.woodPale.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${hasBeforeImg ? 1 : 0}/${hasAfterImg ? 1 : 0}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: (hasBeforeImg || hasAfterImg) ? AiraColors.sage : AiraColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: AiraColors.woodMid),
                    ),
                  ],
                ),
              ),
            ),
            // ─── Expandable Content ───
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Before ──
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: AiraColors.woodMid.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('BEFORE', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AiraColors.woodMid, letterSpacing: 0.5)),
                          ),
                          const SizedBox(height: 8),
                          AiraTapEffect(
                            onTap: hasBeforeImg
                                ? () => widget.onView(context, widget.photoUrl(beforePhoto))
                                : () => widget.onUpload(widget.setLabel, widget.slot.type, widget.isThai),
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: hasBeforeImg
                                    ? Image.network(widget.photoUrl(beforePhoto), fit: BoxFit.cover,
                                        errorBuilder: (_, e, s) => widget.slotPlaceholder(Icons.broken_image_rounded))
                                    : widget.slotPlaceholder(Icons.add_a_photo_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── Divider ──
                    Container(
                      width: 1,
                      height: 160,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      color: AiraColors.woodPale.withValues(alpha: 0.3),
                    ),
                    // ── After ──
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: AiraColors.sage.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('AFTER', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AiraColors.sage, letterSpacing: 0.5)),
                          ),
                          const SizedBox(height: 8),
                          AiraTapEffect(
                            onTap: hasAfterImg
                                ? () => widget.onView(context, widget.photoUrl(afterPhoto!))
                                : () => widget.onUpload('${widget.setLabel}_after_${widget.slot.type.name}', widget.slot.type, widget.isThai),
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: hasAfterImg
                                    ? Image.network(widget.photoUrl(afterPhoto!), fit: BoxFit.cover,
                                        errorBuilder: (_, e, s) => widget.slotPlaceholder(Icons.broken_image_rounded))
                                    : widget.slotPlaceholder(Icons.add_a_photo_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}

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
                  Text('คอร์สของคนไข้', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
                ],
              ),
              const SizedBox(height: 12),
              if (activeCourses.isEmpty)
                _SectionCard(
                  title: 'ยังไม่มีคอร์ส',
                  children: [
                    Text('ยังไม่มีคอร์สที่ผูกกับคนไข้รายนี้', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
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
                    Text('ไม่มียอดค้างชำระ', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
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
                  Text('ประวัติการชำระ', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
                ],
              ),
              const SizedBox(height: 12),
              if (history.isEmpty)
                _SectionCard(
                  title: 'ยังไม่มีประวัติการเงิน',
                  children: [
                    Text('เมื่อมีการบันทึกรับชำระหรือค่าใช้จ่าย ข้อมูลจะแสดงในส่วนนี้', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
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
              Text('ใช้แล้ว $sessionsUsed/$sessionsTotal ครั้ง', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted)),
              Text('เหลือ $remaining ครั้ง', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
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

// ═══════════════════════════════════════════════════════════════════
// Face Diagram + Digital Notepad combined tab
// ═══════════════════════════════════════════════════════════════════

class _FaceDiagramWithNotepad extends ConsumerWidget {
  final String patientId;
  const _FaceDiagramWithNotepad({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final diagramsAsync = ref.watch(diagramsByPatientProvider(patientId));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ─── New Diagram Button ───
        AiraTapEffect(
          onTap: () => context.push('/patients/$patientId/diagram'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  isThai ? 'สร้าง Diagram ใหม่' : 'New Diagram',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ─── Saved Diagrams List (sorted by date, newest first) ───
        _SectionCard(
          title: isThai ? 'Diagram ที่บันทึกแล้ว' : 'Saved Diagrams',
          icon: Icons.draw_rounded,
          iconColor: AiraColors.woodMid,
          children: [
            Text(
              isThai
                  ? 'แต่ละ Diagram บันทึกแยกครั้ง เซฟแล้วแก้ไขไม่ได้ (Immutable Lock)'
                  : 'Each diagram is saved separately and cannot be edited after saving.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
            ),
            const SizedBox(height: 12),
            diagramsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Error: $e',
                  style: GoogleFonts.plusJakartaSans(color: AiraColors.terra)),
              data: (diagrams) {
                if (diagrams.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AiraColors.parchment,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.draw_rounded, size: 36, color: AiraColors.muted.withValues(alpha: 0.4)),
                        const SizedBox(height: 8),
                        Text(
                          isThai ? 'ยังไม่มี Diagram' : 'No diagrams yet',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: AiraColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                const viewOrder = [DiagramView.front, DiagramView.leftSide, DiagramView.rightSide, DiagramView.side, DiagramView.lipZone];
                final Map<String, List<FaceDiagram>> sessions = {};
                for (final d in diagrams) {
                  final key = d.createdAt != null
                      ? '${d.createdAt!.year}-${d.createdAt!.month}-${d.createdAt!.day} ${d.createdAt!.hour}:${d.createdAt!.minute}'
                      : 'unknown';
                  sessions.putIfAbsent(key, () => []).add(d);
                }
                for (final g in sessions.values) {
                  g.sort((a, b) => viewOrder.indexOf(a.viewType).compareTo(viewOrder.indexOf(b.viewType)));
                }
                // Sort sessions by date (newest first)
                final sortedEntries = sessions.entries.toList()
                  ..sort((a, b) {
                    final aDate = a.value.first.createdAt ?? DateTime(2000);
                    final bDate = b.value.first.createdAt ?? DateTime(2000);
                    return bDate.compareTo(aDate);
                  });

                return Column(
                  children: sortedEntries.map((entry) {
                    final group = entry.value;
                    final first = group.first;
                    final dateStr = first.createdAt != null
                        ? '${first.createdAt!.day}/${first.createdAt!.month}/${first.createdAt!.year}  ${first.createdAt!.hour.toString().padLeft(2, '0')}:${first.createdAt!.minute.toString().padLeft(2, '0')}'
                        : '-';

                    String viewLabel(DiagramView v) => switch (v) {
                      DiagramView.front => isThai ? 'ด้านหน้า' : 'Front',
                      DiagramView.side => isThai ? 'ด้านข้าง' : 'Side',
                      DiagramView.leftSide => isThai ? 'ด้านซ้าย' : 'Left',
                      DiagramView.rightSide => isThai ? 'ด้านขวา' : 'Right',
                      DiagramView.lipZone => isThai ? 'ริมฝีปาก' : 'Lip',
                    };

                    IconData viewIcon(DiagramView v) => switch (v) {
                      DiagramView.front => Icons.face_rounded,
                      DiagramView.side => Icons.face_3_rounded,
                      DiagramView.leftSide => Icons.face_3_rounded,
                      DiagramView.rightSide => Icons.face_3_rounded,
                      DiagramView.lipZone => Icons.mood_rounded,
                    };

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.18)),
                          boxShadow: [
                            BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AiraColors.woodPale.withValues(alpha: 0.25), AiraColors.gold.withValues(alpha: 0.15)],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.draw_rounded, size: 18, color: AiraColors.woodMid),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isThai ? 'บันทึก Diagram' : 'Diagram Session',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                                      ),
                                      Text(dateStr, style: GoogleFonts.spaceGrotesk(fontSize: 13, color: AiraColors.muted)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AiraColors.terra.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.lock_rounded, size: 12, color: AiraColors.terra),
                                      const SizedBox(width: 3),
                                      Text(
                                        isThai ? 'ล็อก' : 'Locked',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AiraColors.terra),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: group.map((d) {
                                return AiraTapEffect(
                                  onTap: () => context.push('/patients/$patientId/diagram?diagramId=${d.id}'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AiraColors.parchment,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(viewIcon(d.viewType), size: 16, color: AiraColors.woodMid),
                                        const SizedBox(width: 6),
                                        Text(
                                          viewLabel(d.viewType),
                                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.charcoal),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.chevron_right_rounded, size: 14, color: AiraColors.muted),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${group.length} ${isThai ? 'มุมมอง' : 'views'}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ─── Progress Note ───
        _ProgressNoteSection(isThai: isThai),
        const SizedBox(height: 16),

        // ─── Treatment Record / Laser Parameters ───
        _TreatmentRecordSection(isThai: isThai),
        const SizedBox(height: 16),

        // ─── Instructions & Follow-up ───
        _InstructionsFollowUpSection(isThai: isThai),
        const SizedBox(height: 24),

        // ─── Digital Notepad (embedded) ───
        _SectionCard(
          title: isThai ? 'Digital Notepad' : 'Digital Notepad',
          icon: Icons.edit_note_rounded,
          iconColor: AiraColors.sage,
          children: [
            Text(
              isThai ? 'โน้ตเพิ่มเติมสำหรับ session นี้' : 'Additional notes for this session',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
            ),
            const SizedBox(height: 12),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 500,
          child: NotepadSection(patientId: patientId),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Progress Note — Response to Treatment + Adverse Events
// ═══════════════════════════════════════════════════════════════════

class _ProgressNoteSection extends StatefulWidget {
  final bool isThai;
  const _ProgressNoteSection({required this.isThai});

  @override
  State<_ProgressNoteSection> createState() => _ProgressNoteSectionState();
}

class _ProgressNoteSectionState extends State<_ProgressNoteSection> {
  String? _response; // improved, stable, worsened
  final Set<String> _adverseEvents = {};
  final _otherCtrl = TextEditingController();

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isThai = widget.isThai;
    return _SectionCard(
      title: 'Progress Note',
      icon: Icons.assignment_rounded,
      iconColor: AiraColors.woodMid,
      children: [
        // ─── Response to Previous Treatment ───
        Text(
          isThai ? 'ผลตอบสนองต่อการรักษาครั้งก่อน' : 'Response to Previous Treatment',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildResponseChip('improved', isThai ? 'ดีขึ้น (Improved)' : 'Improved', AiraColors.sage),
            _buildResponseChip('stable', isThai ? 'คงที่ (Stable)' : 'Stable', AiraColors.gold),
            _buildResponseChip('worsened', isThai ? 'แย่ลง (Worsened)' : 'Worsened', AiraColors.terra),
          ],
        ),
        const SizedBox(height: 20),

        // ─── Adverse Events ───
        Text(
          isThai ? 'อาการข้างเคียง (Adverse Events)' : 'Adverse Events',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildEventChip('none', isThai ? 'ไม่มี (None)' : 'None'),
            _buildEventChip('erythema', 'Erythema'),
            _buildEventChip('burn', 'Burn'),
            _buildEventChip('pih', 'PIH'),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _otherCtrl,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal),
          decoration: InputDecoration(
            hintText: isThai ? 'อื่นๆ (ระบุ)...' : 'Other (Specify)...',
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted.withValues(alpha: 0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AiraColors.woodPale)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AiraColors.woodPale)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseChip(String value, String label, Color color) {
    final selected = _response == value;
    return AiraTapEffect(
      onTap: () => setState(() => _response = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AiraColors.parchment,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : AiraColors.woodPale.withValues(alpha: 0.3), width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 18, color: selected ? color : AiraColors.muted),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? color : AiraColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventChip(String value, String label) {
    final selected = _adverseEvents.contains(value);
    final color = value == 'none' ? AiraColors.sage : AiraColors.terra;
    return AiraTapEffect(
      onTap: () {
        setState(() {
          if (value == 'none') {
            _adverseEvents.clear();
            _adverseEvents.add('none');
          } else {
            _adverseEvents.remove('none');
            if (selected) {
              _adverseEvents.remove(value);
            } else {
              _adverseEvents.add(value);
            }
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AiraColors.parchment,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : AiraColors.woodPale.withValues(alpha: 0.3), width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: 18, color: selected ? color : AiraColors.muted),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? color : AiraColors.muted)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Treatment Record / Laser Parameters
// ═══════════════════════════════════════════════════════════════════

class _TreatmentRecordSection extends StatelessWidget {
  final bool isThai;
  const _TreatmentRecordSection({required this.isThai});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: isThai ? 'บันทึกการรักษา / Laser Parameters' : 'Treatment Record / Laser Parameters',
      icon: Icons.flash_on_rounded,
      iconColor: AiraColors.gold,
      children: [
        // ─── Assessment ───
        _buildField(isThai ? 'การวินิจฉัย (Assessment / Diagnosis)' : 'Assessment (Diagnosis / Problem List)', '', 2),
        const SizedBox(height: 12),

        // ─── Plan of Treatment ───
        _buildField(isThai ? 'แผนการรักษา (Plan of Treatment)' : 'Plan of Treatment', '', 2),
        const SizedBox(height: 16),

        // ─── Laser Parameters ───
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AiraColors.gold.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AiraColors.gold.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on_rounded, size: 16, color: AiraColors.gold),
                  const SizedBox(width: 6),
                  Text(
                    'Laser Parameters',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildCompactField('Device / Laser Type', 'เช่น Gentle YAG')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildCompactField('Energy / Fluence', 'เช่น 24')),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildCompactField('Pulse Duration / Spot Size', 'เช่น 12')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildCompactField('Total Shots / Passes', 'เช่น 208')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, String hint, int maxLines) {
    return TextField(
      maxLines: maxLines,
      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.muted),
        hintText: hint.isEmpty ? null : hint,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted.withValues(alpha: 0.4)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AiraColors.woodPale)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AiraColors.woodPale)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AiraColors.woodMid, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildCompactField(String label, String hint) {
    return TextField(
      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AiraColors.muted),
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted.withValues(alpha: 0.4)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AiraColors.woodPale)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AiraColors.woodPale)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AiraColors.gold, width: 2)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Instructions & Follow-up + Next Appointment
// ═══════════════════════════════════════════════════════════════════

class _InstructionsFollowUpSection extends StatefulWidget {
  final bool isThai;
  const _InstructionsFollowUpSection({required this.isThai});

  @override
  State<_InstructionsFollowUpSection> createState() => _InstructionsFollowUpSectionState();
}

class _InstructionsFollowUpSectionState extends State<_InstructionsFollowUpSection> {
  final Set<String> _instructions = {};
  final _otherInstructionCtrl = TextEditingController();
  String _nextAppt = 'as_needed'; // 'date' or 'as_needed'
  DateTime? _nextApptDate;
  TimeOfDay? _nextApptTime;

  @override
  void dispose() {
    _otherInstructionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isThai = widget.isThai;
    return _SectionCard(
      title: isThai ? 'คำแนะนำ & นัดติดตามผล' : 'Instructions & Follow-up',
      icon: Icons.checklist_rounded,
      iconColor: AiraColors.sage,
      children: [
        // ─── Instruction checkboxes ───
        _buildInstruction('avoid_sun', isThai ? 'หลีกเลี่ยงแสงแดด (Avoid sun exposure)' : 'Avoid sun exposure'),
        _buildInstruction('sunscreen', isThai ? 'ทาครีมกันแดด SPF 30+ (Apply sunscreen SPF 30+)' : 'Apply sunscreen SPF 30+'),
        _buildInstruction('medication', isThai ? 'ทายาตามแพทย์สั่ง / มอยส์เจอไรเซอร์' : 'Apply prescribed medication / moisturizer'),
        const SizedBox(height: 8),
        TextField(
          controller: _otherInstructionCtrl,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal),
          decoration: InputDecoration(
            hintText: isThai ? 'อื่นๆ (ระบุ)...' : 'Other (Specify)...',
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted.withValues(alpha: 0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AiraColors.woodPale)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AiraColors.woodPale)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            prefixIcon: const Icon(Icons.edit_rounded, size: 18, color: AiraColors.muted),
          ),
        ),
        const SizedBox(height: 20),

        // ─── Next Appointment ───
        Text(
          isThai ? 'นัดหมายครั้งถัดไป' : 'Next Appointment',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildApptChip('date', isThai ? 'กำหนดวัน-เวลา' : 'Set Date & Time', Icons.calendar_today_rounded),
            _buildApptChip('as_needed', isThai ? 'ตามความจำเป็น (As needed)' : 'As needed', Icons.access_time_rounded),
          ],
        ),
        if (_nextAppt == 'date') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AiraTapEffect(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _nextApptDate ?? DateTime.now().add(const Duration(days: 14)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _nextApptDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AiraColors.woodPale),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: AiraColors.woodMid),
                        const SizedBox(width: 8),
                        Text(
                          _nextApptDate != null ? '${_nextApptDate!.day}/${_nextApptDate!.month}/${_nextApptDate!.year}' : (isThai ? 'เลือกวันที่' : 'Select date'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _nextApptDate != null ? AiraColors.charcoal : AiraColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AiraTapEffect(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _nextApptTime ?? const TimeOfDay(hour: 10, minute: 0),
                    );
                    if (picked != null) setState(() => _nextApptTime = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AiraColors.woodPale),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: AiraColors.woodMid),
                        const SizedBox(width: 8),
                        Text(
                          _nextApptTime != null ? '${_nextApptTime!.hour.toString().padLeft(2, '0')}:${_nextApptTime!.minute.toString().padLeft(2, '0')}' : (isThai ? 'เลือกเวลา' : 'Select time'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _nextApptTime != null ? AiraColors.charcoal : AiraColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInstruction(String value, String label) {
    final selected = _instructions.contains(value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AiraTapEffect(
        onTap: () {
          setState(() {
            if (selected) {
              _instructions.remove(value);
            } else {
              _instructions.add(value);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AiraColors.sage.withValues(alpha: 0.08) : AiraColors.parchment,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AiraColors.sage.withValues(alpha: 0.3) : AiraColors.woodPale.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 20,
                color: selected ? AiraColors.sage : AiraColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AiraColors.charcoal : AiraColors.muted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApptChip(String value, String label, IconData icon) {
    final selected = _nextAppt == value;
    final color = AiraColors.woodMid;
    return AiraTapEffect(
      onTap: () => setState(() => _nextAppt = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : AiraColors.parchment,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : AiraColors.woodPale.withValues(alpha: 0.3), width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? Icons.check_circle_rounded : icon, size: 18, color: selected ? color : AiraColors.muted),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? color : AiraColors.muted)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Consent Form Tab — Separate tab with per-session saving
// ═══════════════════════════════════════════════════════════════════

class _ConsentFormTab extends ConsumerWidget {
  final String patientId;
  const _ConsentFormTab({required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AiraTapEffect(
          onTap: () => context.push('/patients/$patientId/consent'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  isThai ? 'สร้าง Consent Form ใหม่' : 'New Consent Form',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: isThai ? 'Consent Form ที่บันทึกแล้ว' : 'Saved Consent Forms',
          icon: Icons.description_rounded,
          iconColor: AiraColors.gold,
          children: [
            Text(
              isThai
                  ? 'Consent Form แต่ละครั้งจะบันทึกแยกเป็น session เพื่อเก็บเป็นหลักฐานทางการแพทย์'
                  : 'Each consent form is saved per session for medical compliance.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AiraColors.parchment,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.description_rounded, size: 36, color: AiraColors.muted.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text(
                    isThai ? 'กดปุ่มด้านบนเพื่อสร้าง Consent Form ใหม่' : 'Tap button above to create new consent form',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Supplements Tab — อาหารเสริม
// ═══════════════════════════════════════════════════════════════════

class _SupplementsTab extends StatefulWidget {
  final String patientId;
  const _SupplementsTab({required this.patientId});

  @override
  State<_SupplementsTab> createState() => _SupplementsTabState();
}

class _SupplementsTabState extends State<_SupplementsTab> {
  final List<Map<String, String>> _supplements = [
    {'name': 'Vitamin C', 'dosage': '1,000 mg/วัน'},
    {'name': 'Collagen', 'dosage': '5,000 mg/วัน'},
    {'name': 'Glutathione', 'dosage': '500 mg/วัน'},
  ];

  static const _colors = [AiraColors.gold, AiraColors.woodMid, AiraColors.sage, AiraColors.terra, AiraColors.woodLt];
  static const _icons = [Icons.local_pharmacy_rounded, Icons.science_rounded, Icons.spa_rounded, Icons.medication_rounded, Icons.health_and_safety_rounded];

  void _addSupplement() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('เพิ่มอาหารเสริม', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: GoogleFonts.plusJakartaSans(fontSize: 15),
              decoration: InputDecoration(
                labelText: 'ชื่ออาหารเสริม',
                hintText: 'เช่น Vitamin D, Omega-3...',
                hintStyle: GoogleFonts.plusJakartaSans(color: AiraColors.muted.withValues(alpha: 0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                prefixIcon: const Icon(Icons.medication_rounded, size: 20, color: AiraColors.woodMid),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: dosageCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 15),
              decoration: InputDecoration(
                labelText: 'ปริมาณ / ขนาดรับประทาน',
                hintText: 'เช่น 1,000 mg/วัน',
                hintStyle: GoogleFonts.plusJakartaSans(color: AiraColors.muted.withValues(alpha: 0.5)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                prefixIcon: const Icon(Icons.straighten_rounded, size: 20, color: AiraColors.woodMid),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('ยกเลิก', style: GoogleFonts.plusJakartaSans(color: AiraColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AiraColors.sage,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final dosage = dosageCtrl.text.trim();
              if (name.isNotEmpty) {
                setState(() => _supplements.add({'name': name, 'dosage': dosage.isEmpty ? '-' : dosage}));
                Navigator.pop(ctx);
              }
            },
            child: Text('เพิ่ม', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AiraTapEffect(
          onTap: _addSupplement,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 6),
                Text('+ เพิ่มอาหารเสริม', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'อาหารเสริม / Supplements',
          icon: Icons.medication_rounded,
          iconColor: AiraColors.sage,
          children: [
            Text(
              'บันทึกอาหารเสริมที่ผู้รับบริการใช้อยู่',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted),
            ),
            const SizedBox(height: 16),
            if (_supplements.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AiraColors.parchment, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Icon(Icons.medication_rounded, size: 36, color: AiraColors.muted.withValues(alpha: 0.4)),
                    const SizedBox(height: 8),
                    Text('ยังไม่มีข้อมูลอาหารเสริม', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ...List.generate(_supplements.length, (i) {
              final s = _supplements[i];
              final color = _colors[i % _colors.length];
              final icon = _icons[i % _icons.length];
              return Column(
                children: [
                  if (i > 0) const Divider(height: 20),
                  _SupplementItemRow(
                    name: s['name']!,
                    dosage: s['dosage']!,
                    icon: icon,
                    color: color,
                    onDelete: () => setState(() => _supplements.removeAt(i)),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _SupplementItemRow extends StatelessWidget {
  final String name;
  final String dosage;
  final IconData icon;
  final Color color;
  final VoidCallback onDelete;
  const _SupplementItemRow({required this.name, required this.dosage, required this.icon, required this.color, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
              Text(dosage, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted)),
            ],
          ),
        ),
        AiraTapEffect(
          onTap: onDelete,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AiraColors.terra.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.close_rounded, size: 16, color: AiraColors.terra),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Patient Status Tab — Hidden from patients, behind Spending
// ═══════════════════════════════════════════════════════════════════

class _PatientStatusTab extends ConsumerWidget {
  final Patient patient;
  const _PatientStatusTab({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionCard(
          title: isThai ? 'สถานะคนไข้ (ภายในเท่านั้น)' : 'Patient Status (Internal Only)',
          icon: Icons.star_rounded,
          iconColor: AiraColors.gold,
          children: [
            Text(
              isThai
                  ? 'ส่วนนี้ใช้ภายในคลินิกเท่านั้น คนไข้จะไม่เห็นข้อมูลนี้'
                  : 'This section is for internal use only. Patients cannot see this.',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted),
            ),
            const SizedBox(height: 16),
            _StatusSelector(current: patient.status),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SHARED COMPONENTS (continued)
// ═══════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.charcoal),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
