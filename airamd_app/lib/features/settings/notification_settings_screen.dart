import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/localization/app_localizations.dart';

// ═══════════════════════════════════════════════════════════════
// NOTIFICATION SETTINGS SCREEN
// ═══════════════════════════════════════════════════════════════

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _notifEnabled = true;
  bool _apptReminder = true;
  bool _followUpReminder = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notif = await PushNotificationService.isNotificationsEnabled();
    final appt = await PushNotificationService.isAppointmentReminderEnabled();
    final followUp = await PushNotificationService.isFollowUpReminderEnabled();
    if (mounted) {
      setState(() {
        _notifEnabled = notif;
        _apptReminder = appt;
        _followUpReminder = followUp;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          // ─── Header ───
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20, right: 20, bottom: 16,
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
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.notificationSettings,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        l.notificationSettingsSubtitle,
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

          // ─── Content ───
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AiraColors.woodMid))
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Master toggle
                      _SettingCard(
                        icon: Icons.notifications_rounded,
                        iconColor: AiraColors.woodMid,
                        title: l.enableNotifications,
                        subtitle: l.enableNotificationsDesc,
                        trailing: Switch.adaptive(
                          value: _notifEnabled,
                          activeColor: AiraColors.sage,
                          onChanged: (v) async {
                            setState(() => _notifEnabled = v);
                            await PushNotificationService.setNotificationsEnabled(v);
                            if (v) {
                              await PushNotificationService.requestPermission();
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Appointment reminders
                      _SettingCard(
                        icon: Icons.calendar_today_rounded,
                        iconColor: AiraColors.gold,
                        title: l.appointmentReminder,
                        subtitle: l.appointmentReminderDesc,
                        enabled: _notifEnabled,
                        trailing: Switch.adaptive(
                          value: _apptReminder && _notifEnabled,
                          activeColor: AiraColors.sage,
                          onChanged: _notifEnabled
                              ? (v) async {
                                  setState(() => _apptReminder = v);
                                  await PushNotificationService.setAppointmentReminderEnabled(v);
                                }
                              : null,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Follow-up reminders
                      _SettingCard(
                        icon: Icons.event_repeat_rounded,
                        iconColor: AiraColors.sage,
                        title: l.followUpReminder,
                        subtitle: l.followUpReminderDesc,
                        enabled: _notifEnabled,
                        trailing: Switch.adaptive(
                          value: _followUpReminder && _notifEnabled,
                          activeColor: AiraColors.sage,
                          onChanged: _notifEnabled
                              ? (v) async {
                                  setState(() => _followUpReminder = v);
                                  await PushNotificationService.setFollowUpReminderEnabled(v);
                                }
                              : null,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AiraColors.woodWash.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 20, color: AiraColors.woodMid.withValues(alpha: 0.7)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l.notificationInfoNote,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AiraColors.muted,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Test notification button
                      AiraTapEffect(
                        onTap: () async {
                          await PushNotificationService.showLocalNotification(
                            title: 'airaMD Test',
                            body: l.testNotificationBody,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l.testNotificationSent),
                                backgroundColor: AiraColors.sage,
                              ),
                            );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AiraColors.woodMid.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_active_rounded, size: 18, color: AiraColors.woodMid),
                              const SizedBox(width: 8),
                              Text(
                                l.testNotification,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AiraColors.woodMid,
                                ),
                              ),
                            ],
                          ),
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

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool enabled;

  const _SettingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AiraColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AiraColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
