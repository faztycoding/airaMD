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
import '../../core/localization/app_localizations.dart';
import 'digital_notepad_screen.dart';
import 'photo_comparison_screen.dart';
import 'message_history_screen.dart';

part '_profile_header.dart';
part '_profile_info_tabs.dart';
part '_profile_photos_tab.dart';
part '_profile_finance_tab.dart';
part '_profile_form_tabs.dart';

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

  List<_TabDef> _tabs(
    AppL10n l, {
    required bool canManageClinicalData,
    required bool canAccessFinancialData,
  }) {
    return [
      _TabDef(0, Icons.person_rounded, l.personalInfo),
      _TabDef(1, Icons.healing_rounded, l.healthHistory),
      if (canManageClinicalData) ...[
        _TabDef(2, Icons.draw_rounded, l.faceDiagram),
        _TabDef(3, Icons.colorize_rounded, 'Injectables'),
        _TabDef(4, Icons.flash_on_rounded, l.laser),
        _TabDef(5, Icons.science_rounded, l.treatment),
        _TabDef(6, Icons.spa_rounded, l.antiAging),
      ],
      if (canAccessFinancialData) _TabDef(7, Icons.table_chart_rounded, l.courseTable),
      if (canManageClinicalData) ...[
        _TabDef(8, Icons.photo_library_rounded, l.beforeAfter),
        _TabDef(9, Icons.description_rounded, l.consentForm),
        _TabDef(10, Icons.medication_rounded, l.supplements),
        _TabDef(11, Icons.favorite_rounded, l.surgery),
      ],
      if (canAccessFinancialData) _TabDef(12, Icons.account_balance_wallet_rounded, l.spending),
      _TabDef(13, Icons.message_rounded, l.messages),
      if (canManageClinicalData) _TabDef(14, Icons.star_rounded, l.patientStatus),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final patientAsync = ref.watch(patientByIdProvider(widget.patientId));
    final l = context.l10n;
    final canManageClinicalData = ref.watch(canManageClinicalDataProvider);
    final canAccessFinancialData = ref.watch(canAccessFinancialDataProvider);
    final effectiveRole = ref.watch(effectiveStaffRoleProvider);
    final tabs = _tabs(
      l,
      canManageClinicalData: canManageClinicalData,
      canAccessFinancialData: canAccessFinancialData,
    );
    if (tabs.isNotEmpty && !tabs.any((tab) => tab.sectionId == _selectedSection)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedSection = tabs.first.sectionId);
      });
    }

    return patientAsync.when(
      data: (patient) {
        if (patient == null) {
          return Scaffold(
            backgroundColor: AiraColors.cream,
            body: Center(child: Text(l.patientNotFound, style: GoogleFonts.plusJakartaSans(fontSize: 16, color: AiraColors.muted))),
          );
        }
        final hasLineContact = patient.lineId != null && patient.lineId!.isNotEmpty;
        final hasMessagingContact = hasLineContact || (patient.phone != null && patient.phone!.isNotEmpty);
        return Scaffold(
          backgroundColor: AiraColors.cream,
          body: Column(
            children: [
              _ProfileHeader(
                patient: patient,
                onBack: () => context.pop(),
                onEdit: () => context.push('/patients/${patient.id}/edit'),
                onDelete: () => _confirmDeletePatient(context, ref, patient),
                onOpenMessages: hasMessagingContact ? () => setState(() => _selectedSection = 13) : null,
                canEdit: canManageClinicalData,
                canDelete: effectiveRole == StaffRole.owner,
                showLineAction: hasLineContact,
                showMessageAction: hasMessagingContact,
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
          Text(l.failedToLoadPatient, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal)),
          const SizedBox(height: 4),
          Text('$e', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => ref.invalidate(patientByIdProvider(widget.patientId)), child: Text(l.retry)),
        ],
      ))),
    );
  }

  void _confirmDeletePatient(BuildContext context, WidgetRef ref, Patient patient) {
    final l = context.l10n;
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
          l.deletePatient,
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.isThai
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
                      l.actionReversible,
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
            child: Text(l.cancel, style: GoogleFonts.plusJakartaSans(color: AiraColors.muted)),
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
                        l.deletedPatient(patient.fullName),
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
            child: Text(l.confirmDelete, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
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
            selected: tab.sectionId == _selectedSection,
            onTap: () => setState(() => _selectedSection = tab.sectionId),
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
            final selected = tab.sectionId == _selectedSection;
            return Padding(
              padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 8),
              child: AiraTapEffect(
                onTap: () => setState(() => _selectedSection = tab.sectionId),
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
  final int sectionId;
  final IconData icon;
  final String label;
  const _TabDef(this.sectionId, this.icon, this.label);
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
// Part files — extracted from this screen for maintainability
// ═══════════════════════════════════════════════════════════════════
