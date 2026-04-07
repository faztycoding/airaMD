import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/theme.dart';
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
                  _Item(Icons.language_rounded, l.language, l.languageSubtitle),
                  _Item(Icons.shield_rounded, l.security, l.securitySubtitle, route: '/settings/security'),
                  _Item(Icons.cloud_sync_rounded, l.cloudData, l.cloudDataSubtitle),
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

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            child: const Center(
              child: Icon(Icons.medical_services_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. Pammy',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Admin',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.edit_rounded, size: 16, color: Colors.white.withValues(alpha: 0.8)),
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
  const _Item(this.icon, this.label, this.subtitle, {this.route});
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
                    onTap: item.route != null ? () => context.push(item.route!) : null,
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
