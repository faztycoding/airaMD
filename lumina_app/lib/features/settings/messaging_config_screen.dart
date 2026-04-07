import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/services/messaging_service.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/aira_premium_form.dart';
import '../../core/localization/app_localizations.dart';

// ═══════════════════════════════════════════════════════════════
// MESSAGING CONFIG SCREEN — LINE OA / WhatsApp Business setup
// ═══════════════════════════════════════════════════════════════

class MessagingConfigScreen extends ConsumerStatefulWidget {
  const MessagingConfigScreen({super.key});

  @override
  ConsumerState<MessagingConfigScreen> createState() => _MessagingConfigScreenState();
}

class _MessagingConfigScreenState extends ConsumerState<MessagingConfigScreen> {
  final _tokenCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  bool _smsEnabled = false;
  bool _lineConfigured = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final token = await MessagingService.getLineChannelToken();
    final secret = await MessagingService.getLineChannelSecret();
    final sms = await MessagingService.isSmsEnabled();
    if (mounted) {
      setState(() {
        _tokenCtrl.text = token ?? '';
        _secretCtrl.text = secret ?? '';
        _smsEnabled = sms;
        _lineConfigured = token != null && token.isNotEmpty;
        _loading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _saving = true);
    try {
      await MessagingService.setLineChannelToken(_tokenCtrl.text.trim());
      await MessagingService.setLineChannelSecret(_secretCtrl.text.trim());
      await MessagingService.setSmsEnabled(_smsEnabled);
      ref.invalidate(lineApiConfiguredProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.saveSuccess),
            backgroundColor: AiraColors.sage,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.saveFailed('$e')),
            backgroundColor: AiraColors.terra,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
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
                        l.messagingConfig,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        l.messagingConfigSubtitle,
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
                      // LINE OA Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _lineConfigured
                              ? AiraColors.sage.withValues(alpha: 0.08)
                              : AiraColors.gold.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _lineConfigured
                                ? AiraColors.sage.withValues(alpha: 0.2)
                                : AiraColors.gold.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _lineConfigured ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                              color: _lineConfigured ? AiraColors.sage : AiraColors.gold,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _lineConfigured ? l.lineApiConnected : l.lineApiNotConfigured,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _lineConfigured ? AiraColors.sage : AiraColors.gold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // LINE Configuration
                      Text(
                        'LINE Official Account',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AiraColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.lineConfigDesc,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AiraColors.muted,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Channel Access Token
                      TextField(
                        controller: _tokenCtrl,
                        style: airaFieldTextStyle,
                        obscureText: true,
                        decoration: airaFieldDecoration(
                          label: 'Channel Access Token',
                          prefixIcon: Icons.vpn_key_rounded,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Channel Secret
                      TextField(
                        controller: _secretCtrl,
                        style: airaFieldTextStyle,
                        obscureText: true,
                        decoration: airaFieldDecoration(
                          label: 'Channel Secret',
                          prefixIcon: Icons.lock_rounded,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // SMS Toggle
                      Container(
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
                                color: AiraColors.woodWash.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.sms_rounded, size: 20, color: AiraColors.woodMid),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SMS', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AiraColors.charcoal)),
                                  Text(l.smsDesc, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted)),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _smsEnabled,
                              activeColor: AiraColors.sage,
                              onChanged: (v) => setState(() => _smsEnabled = v),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // How it works info
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AiraColors.woodWash.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline_rounded, size: 18, color: AiraColors.gold),
                                const SizedBox(width: 8),
                                Text(
                                  l.howItWorks,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AiraColors.charcoal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(icon: Icons.looks_one_rounded, text: l.lineStep1),
                            _InfoRow(icon: Icons.looks_two_rounded, text: l.lineStep2),
                            _InfoRow(icon: Icons.looks_3_rounded, text: l.lineStep3),
                            _InfoRow(icon: Icons.looks_4_rounded, text: l.lineStep4),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Save button
                      AiraTapEffect(
                        onTap: _saving ? null : _saveConfig,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AiraColors.woodDk.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _saving
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    l.save,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AiraColors.woodMid),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
