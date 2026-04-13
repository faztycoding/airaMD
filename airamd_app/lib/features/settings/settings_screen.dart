import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/localization/app_localizations.dart';
import '../../app.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 4, height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B6650), Color(0xFFD4B89A)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.l10n.settings,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28, fontWeight: FontWeight.w700, color: AiraColors.charcoal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Body
                Expanded(
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 300, child: _Sidebar()),
                            const SizedBox(width: 20),
                            Expanded(child: _ContentPanel()),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              _Sidebar(),
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Sidebar
// ═══════════════════════════════════════════════════════════════════
class _Sidebar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile card
          _ProfileCard(),
          const SizedBox(height: 20),
          // Setting groups
          Builder(builder: (context) {
            final l = context.l10n;
            return Column(
              children: [
                _SettingsGroup(l.settingsClinic, [
                  _Item(Icons.business_rounded, l.clinicInfo, l.clinicInfoSubtitle, route: '/settings/clinic-info'),
                  _Item(Icons.people_rounded, l.manageStaff, l.manageStaffSubtitle, route: '/settings/staff'),
                  _Item(Icons.inventory_2_rounded, l.productLibrary, l.productLibrarySubtitle, route: '/settings/products'),
                  _Item(Icons.swap_horiz_rounded, l.stockTransactions, l.stockTransactionsSubtitle, route: '/settings/inventory'),
                  _Item(Icons.payments_rounded, l.financial, l.financialSubtitle, route: '/settings/financial'),
                ]),
                const SizedBox(height: 12),
                _SettingsGroup(l.settingsProcedures, [
                  _Item(Icons.medical_services_rounded, l.serviceList, l.serviceListSubtitle, route: '/settings/services'),
                  _Item(Icons.card_membership_rounded, l.courses, l.manageCourses, route: '/settings/course-overview'),
                  _Item(Icons.description_rounded, l.consentTemplates, l.consentTemplateSubtitle, route: '/settings/consent-templates'),
                  _Item(Icons.timer_rounded, l.treatmentRules, l.treatmentRulesSubtitle, route: '/settings/treatment-rules'),
                ]),
                const SizedBox(height: 12),
                _SettingsGroup(l.system, [
                  _Item(Icons.notifications_rounded, l.notificationSettings, l.notificationSettingsSubtitle, route: '/settings/notifications'),
                  _Item(Icons.chat_rounded, l.messagingConfig, l.messagingConfigSubtitle, route: '/settings/messaging'),
                  _Item(Icons.language_rounded, l.language, l.languageSubtitle, onTap: () => _showLanguagePicker(context, ref)),
                  _Item(Icons.shield_rounded, l.security, l.securitySubtitle, route: '/settings/security'),
                  _Item(Icons.privacy_tip_rounded, 'PDPA', l.privacyPolicy, route: '/settings/privacy'),
                  _Item(Icons.history_rounded, l.auditLogs, l.auditLogTitle, route: '/settings/audit-logs'),
                ]),
              ],
            );
          }),
          const SizedBox(height: 12),
          // ─── Logout Button ───
          _LogoutButton(ref: ref),
          const SizedBox(height: 16),
          const SyncStatusCard(),
          const SizedBox(height: 20),
          // Version
          Text(
            'airaMD v1.0.0',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

void _showLanguagePicker(BuildContext context, WidgetRef ref) {
  final isThai = ref.read(isThaiProvider);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AiraColors.creamDk,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.language,
              style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.w700, color: AiraColors.charcoal,
              ),
            ),
            const SizedBox(height: 16),
            _LangOption(
              flag: '🇹🇭',
              label: 'ภาษาไทย',
              subtitle: 'Thai',
              selected: isThai,
              onTap: () {
                ref.read(localeProvider.notifier).state = const Locale('th', 'TH');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _LangOption(
              flag: '🇺🇸',
              label: 'English',
              subtitle: 'อังกฤษ',
              selected: !isThai,
              onTap: () {
                ref.read(localeProvider.notifier).state = const Locale('en', 'US');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _LangOption extends StatelessWidget {
  final String flag, label, subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _LangOption({
    required this.flag, required this.label, required this.subtitle,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AiraColors.woodWash.withValues(alpha: 0.3) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AiraColors.woodMid : AiraColors.creamDk,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: AiraColors.charcoal)),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: AiraColors.woodMid, size: 22),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  String _roleLabel(StaffRole role, AppL10n l) {
    return switch (role) {
      StaffRole.owner => l.ownerRole,
      StaffRole.doctor => l.doctorRole,
      StaffRole.receptionist => l.staffRole,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(currentStaffProvider).valueOrNull;
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = staff?.fullName ?? user?.email ?? 'airaMD';
    final subtitle = staff != null
        ? _roleLabel(staff.role, context.l10n)
        : (user?.email ?? (context.l10n.isThai ? 'ยังไม่พบข้อมูลพนักงาน' : 'Staff profile unavailable'));
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4F3A), Color(0xFF8B6650)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4F3A).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
    );
  }
}

class _Item {
  final IconData icon;
  final String label, subtitle;
  final String? route;
  final VoidCallback? onTap;
  const _Item(this.icon, this.label, this.subtitle, {this.route, this.onTap});
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_Item> items;
  const _SettingsGroup(this.title, this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AiraColors.muted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: AiraColors.woodDk.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  AiraTapEffect(
                    onTap: item.route != null ? () => context.push(item.route!) : item.onTap,
                    child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AiraColors.woodWash.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.icon, size: 18, color: AiraColors.woodMid),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.charcoal),
                              ),
                              Text(
                                item.subtitle,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 18, color: AiraColors.muted.withValues(alpha: 0.5)),
                      ],
                    ),
                  ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 64,
                      endIndent: 14,
                      color: AiraColors.creamDk.withValues(alpha: 0.5),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Content Panel (right side)
// ═══════════════════════════════════════════════════════════════════
class _ContentPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AiraColors.woodDk.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AiraColors.woodWash.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.settings_rounded,
                size: 32,
                color: AiraColors.muted.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            Builder(builder: (context) {
              final l = context.l10n;
              return Column(
                children: [
                  Text(
                    l.selectMenuToSettings,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AiraColors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.settingsWillShowHere,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AiraColors.muted.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Logout Button ─────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final WidgetRef ref;
  const _LogoutButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AiraTapEffect(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: AiraColors.terra.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AiraColors.terra.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 20, color: AiraColors.terra),
            const SizedBox(width: 10),
            Text(
              l.logoutButton,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AiraColors.terra,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final l = context.l10n;
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AiraColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.logoutButton,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AiraColors.charcoal,
          ),
        ),
        content: Text(
          l.logoutConfirm,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.cancel,
              style: GoogleFonts.plusJakartaSans(color: AiraColors.muted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client.auth.signOut();
              ref.read(appUnlockedProvider.notifier).state = false;
            },
            child: Text(
              l.logoutButton,
              style: GoogleFonts.plusJakartaSans(
                color: AiraColors.terra,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
