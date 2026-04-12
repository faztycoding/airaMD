import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import 'aira_tap_effect.dart';

/// Shared premium form widgets used across all form screens.
/// Provides consistent modern UI styling with airaClinic branding.

// ═══════════════════════════════════════════════════════════════
// Premium Hero Header — gradient header with branding + save btn
// ═══════════════════════════════════════════════════════════════
class AiraPremiumHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool loading;
  final VoidCallback onBack;
  final VoidCallback? onSave;
  final String saveLabel;
  final List<AiraStepInfo>? steps;

  const AiraPremiumHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.loading = false,
    required this.onBack,
    this.onSave,
    this.saveLabel = 'บันทึก',
    this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, steps != null ? 20 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D2517), Color(0xFF5A3E2B), Color(0xFF7B5840), Color(0xFFA8806A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF3D2517).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AiraTapEffect(
                onTap: onBack,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'aira',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 14, fontWeight: FontWeight.w400,
                            color: AiraColors.woodPale, letterSpacing: 2,
                          ),
                        ),
                        Text(
                          'CLINIC',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: AiraColors.woodPale.withValues(alpha: 0.7), letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (onSave != null) ...[
                const SizedBox(width: 12),
                AiraTapEffect(
                  onTap: loading ? null : onSave,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFD4A276), Color(0xFFC4922A)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFC4922A).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(saveLabel, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                  ),
                ),
              ],
            ],
          ),
          if (steps != null && steps!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (int i = 0; i < steps!.length; i++) ...[
                  _buildStepDot(steps![i].num, steps![i].label, true),
                  if (i < steps!.length - 1) _buildStepLine(),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepDot(int num, String label, bool active) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: active ? 0.5 : 0.15), width: 1.5),
            ),
            child: Center(
              child: Text('$num', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: active ? 1.0 : 0.4))),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 9, color: Colors.white.withValues(alpha: active ? 0.7 : 0.3)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 20, height: 1.5,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(1)),
    );
  }
}

class AiraStepInfo {
  final int num;
  final String label;
  const AiraStepInfo(this.num, this.label);
}

/// Factory to create step info list
List<AiraStepInfo> premiumSteps(List<(int, String)> steps) =>
    steps.map((s) => AiraStepInfo(s.$1, s.$2)).toList();

// ═══════════════════════════════════════════════════════════════
// Section Header — step number + title + subtitle
// ═══════════════════════════════════════════════════════════════
class AiraSectionHeader extends StatelessWidget {
  final int step;
  final IconData icon;
  final String title;
  final String? subtitle;

  const AiraSectionHeader({
    super.key,
    this.step = 0,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          if (step > 0) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AiraColors.primaryGradient,
                boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Center(
                child: Text('$step', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            Icon(icon, size: 22, color: AiraColors.woodMid),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
                if (subtitle != null)
                  Text(subtitle!, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Premium Card — white card with colored accent bar
// ═══════════════════════════════════════════════════════════════
class AiraPremiumCard extends StatelessWidget {
  final Color accentColor;
  final List<Widget> children;

  const AiraPremiumCard({
    super.key,
    required this.accentColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: accentColor.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 4, color: accentColor.withValues(alpha: 0.6)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Premium Save Button — full-width gradient button
// ═══════════════════════════════════════════════════════════════
class AiraPremiumSaveButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const AiraPremiumSaveButton({
    super.key,
    required this.label,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3D2517), Color(0xFF6B4F3A), Color(0xFF8B6650)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            else ...[
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Premium Branding Footer
// ═══════════════════════════════════════════════════════════════
class AiraBrandingFooter extends StatelessWidget {
  const AiraBrandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.35,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_hospital_rounded, size: 12, color: AiraColors.muted),
            const SizedBox(width: 4),
            Text(
              'airaCLINIC',
              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: AiraColors.muted, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Premium InputDecoration helper — consistent field styling
// ═══════════════════════════════════════════════════════════════
InputDecoration airaFieldDecoration({
  required String label,
  String? hint,
  IconData? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
    hintText: hint,
    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted.withValues(alpha: 0.4)),
    prefixIcon: prefixIcon != null
        ? Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(prefixIcon, size: 18, color: AiraColors.woodLt),
          )
        : null,
    prefixIconConstraints: prefixIcon != null ? const BoxConstraints(minWidth: 40, minHeight: 0) : null,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AiraColors.parchment.withValues(alpha: 0.5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AiraColors.woodPale.withValues(alpha: 0.25))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AiraColors.woodPale.withValues(alpha: 0.25))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AiraColors.woodMid, width: 2)),
  );
}

/// Premium-styled TextFormField with consistent look
TextStyle get airaFieldTextStyle => GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.charcoal);

// ═══════════════════════════════════════════════════════════════
// Premium Safety Check Button — outlined sage-colored
// ═══════════════════════════════════════════════════════════════
class AiraSafetyCheckButton extends StatelessWidget {
  final VoidCallback onTap;

  const AiraSafetyCheckButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AiraColors.sage.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AiraColors.sage.withValues(alpha: 0.4), width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_rounded, size: 20, color: AiraColors.sage),
            const SizedBox(width: 10),
            Text(
              'ตรวจสอบความปลอดภัย',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.sage),
            ),
          ],
        ),
      ),
    );
  }
}
