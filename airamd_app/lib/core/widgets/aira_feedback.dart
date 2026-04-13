import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';

class AiraFeedback {
  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: AiraColors.sage,
    );
  }

  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: AiraColors.terra,
    );
  }

  static void warning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: AiraColors.gold,
      textColor: AiraColors.charcoal,
    );
  }

  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: AiraColors.woodMid,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Color textColor = Colors.white,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
