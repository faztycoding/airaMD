part of 'treatment_form_screen.dart';

/// Read-only summary card shown beneath the doctor dropdown so the doctor's
/// name, schedule status and medical license number (เลข ว.) are clearly
/// visible side-by-side. Per client request — they couldn't tell the
/// dropdown was the doctor field, and wanted the license number on its
/// own line.
class _DoctorInfoCard extends StatelessWidget {
  final String fullName;
  final String? licenseNumber;
  final String statusLabel;
  final bool isThai;

  const _DoctorInfoCard({
    required this.fullName,
    required this.licenseNumber,
    required this.statusLabel,
    required this.isThai,
  });

  @override
  Widget build(BuildContext context) {
    final hasLicense =
        licenseNumber != null && licenseNumber!.trim().isNotEmpty;
    final licenseDisplay = hasLicense ? licenseNumber!.trim() : '—';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AiraColors.woodPale.withValues(alpha: 0.12),
            AiraColors.gold.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AiraColors.woodMid.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_pin_rounded,
                  size: 18, color: AiraColors.woodMid),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fullName.isEmpty
                      ? (isThai ? 'ไม่ระบุชื่อ' : 'Unnamed')
                      : fullName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AiraColors.charcoal,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AiraColors.sage.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AiraColors.sage,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.badge_rounded,
                size: 16,
                color: hasLicense ? AiraColors.gold : AiraColors.terra,
              ),
              const SizedBox(width: 8),
              Text(
                isThai ? 'เลข ว.' : 'License No.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AiraColors.muted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                licenseDisplay,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: hasLicense ? AiraColors.charcoal : AiraColors.terra,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          if (!hasLicense) ...[
            const SizedBox(height: 4),
            Text(
              isThai
                  ? 'หมอท่านนี้ยังไม่ได้บันทึกเลข ว. — แก้ที่ "จัดการพนักงาน"'
                  : 'No license number on file — set it in "Staff Management"',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AiraColors.terra,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
