import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/localization/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
              left: 20,
              right: 20,
              bottom: 16,
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
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
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
                        l.privacyPolicyTitle,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        l.privacyPolicySubtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),

          // ─── Content ───
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
                  children: [
                    // Effective date
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AiraColors.sage.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AiraColors.sage.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 16, color: AiraColors.sage),
                          const SizedBox(width: 10),
                          Text(
                            l.effectiveDate,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.sage),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildSection(icon: Icons.info_outline_rounded, title: l.pdpaSec1Title, content: l.pdpaSec1Content),
                    _buildSection(icon: Icons.folder_open_rounded, title: l.pdpaSec2Title, content: '', bullets: l.pdpaSec2Bullets),
                    _buildSection(icon: Icons.gavel_rounded, title: l.pdpaSec3Title, content: '', bullets: l.pdpaSec3Bullets),
                    _buildSection(icon: Icons.share_rounded, title: l.pdpaSec4Title, content: l.pdpaSec4Content, bullets: l.pdpaSec4Bullets),
                    _buildSection(icon: Icons.lock_rounded, title: l.pdpaSec5Title, content: '', bullets: l.pdpaSec5Bullets),
                    _buildSection(icon: Icons.timer_rounded, title: l.pdpaSec6Title, content: l.pdpaSec6Content),
                    _buildSection(icon: Icons.person_rounded, title: l.pdpaSec7Title, content: l.pdpaSec7Content, bullets: l.pdpaSec7Bullets),
                    _buildSection(icon: Icons.child_care_rounded, title: l.pdpaSec8Title, content: l.pdpaSec8Content),
                    _buildSection(icon: Icons.edit_note_rounded, title: l.pdpaSec9Title, content: l.pdpaSec9Content),
                    _buildSection(icon: Icons.phone_rounded, title: l.pdpaSec10Title, content: l.pdpaSec10Content),

                    const SizedBox(height: 24),

                    // Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AiraColors.woodWash.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user_rounded, size: 20, color: AiraColors.sage),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l.pdpaFooter,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    List<String>? bullets,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AiraColors.woodDk.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AiraColors.woodWash.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AiraColors.woodMid),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AiraColors.charcoal,
                  ),
                ),
              ],
            ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                content,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AiraColors.charcoal.withValues(alpha: 0.8),
                  height: 1.6,
                ),
              ),
            ],
            if (bullets != null) ...[
              const SizedBox(height: 10),
              ...bullets.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 10, left: 4),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AiraColors.woodMid.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            b,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AiraColors.charcoal.withValues(alpha: 0.75),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
