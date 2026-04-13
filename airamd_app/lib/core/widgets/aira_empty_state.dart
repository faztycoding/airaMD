import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import 'aira_tap_effect.dart';

class AiraEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AiraEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accentColor = AiraColors.woodMid,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: accentColor),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AiraColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.5,
              color: AiraColors.muted,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            AiraTapEffect(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
