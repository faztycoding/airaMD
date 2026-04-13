part of 'patient_profile_screen.dart';

// ═══════════════════════════════════════════════════════════════════
// PROFILE HEADER — Brown gradient with avatar, name, badges, actions
// ═══════════════════════════════════════════════════════════════════

class _ProfileHeader extends ConsumerWidget {
  final Patient patient;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpenMessages;
  final bool canEdit;
  final bool canDelete;
  final bool showLineAction;
  final bool showMessageAction;
  const _ProfileHeader({required this.patient, required this.onBack, required this.onEdit, required this.onDelete, this.onOpenMessages, this.canEdit = true, this.canDelete = true, this.showLineAction = true, this.showMessageAction = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5A3E2B), Color(0xFF7B5B43), Color(0xFFBE9B7D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // ─── Top bar: back + language toggle ───
          Row(
            children: [
              AiraTapEffect(
                onTap: onBack,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              _LangPill(),
            ],
          ),
          const SizedBox(height: 16),
          // ─── Avatar circle ───
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.25),
                  Colors.white.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Center(
              child: Text(
                patient.firstName.isNotEmpty ? patient.firstName[0] : '?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ─── Name + VIP badge ───
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                patient.fullName,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2,
                ),
              ),
              if (patient.status == PatientStatus.vip) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFC4922A), Color(0xFFD4A84A)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('VIP', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ],
              if (patient.status == PatientStatus.star) ...[
                const SizedBox(width: 8),
                Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (_) => const Icon(Icons.star_rounded, size: 14, color: Color(0xFFC4922A)))),
              ],
            ],
          ),
          const SizedBox(height: 4),
          if (patient.nickname != null && patient.nickname!.isNotEmpty)
            Text(
              '${l.nickname}: ${patient.nickname}',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.white.withValues(alpha: 0.7)),
            ),
          const SizedBox(height: 2),
          Text(
            '${patient.age != null ? "${l.age} ${patient.age} ${l.years}" : ""}${patient.hn != null ? " • HN: ${patient.hn}" : ""}',
            style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 14),
          // ─── Action buttons ───
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showLineAction) ...[
                AiraTapEffect(
                  onTap: onOpenMessages,
                  child: _HeaderActionBtn(
                    icon: Icons.chat_rounded,
                    label: 'LINE',
                    color: const Color(0xFF06C755),
                  ),
                ),
              ],
              if (showLineAction && showMessageAction) const SizedBox(width: 10),
              if (showMessageAction)
                AiraTapEffect(
                  onTap: onOpenMessages,
                  child: _HeaderActionBtn(
                    icon: Icons.message_rounded,
                    label: l.message,
                    color: Colors.white.withValues(alpha: 0.15),
                    textColor: Colors.white,
                  ),
                ),
              if (canEdit) ...[
                const SizedBox(width: 10),
                AiraTapEffect(
                  onTap: onEdit,
                  child: _HeaderActionBtn(
                    icon: Icons.edit_rounded,
                    label: l.edit,
                    color: Colors.white.withValues(alpha: 0.15),
                    textColor: Colors.white,
                  ),
                ),
              ],
              if (canDelete) ...[
                const SizedBox(width: 10),
                AiraTapEffect(
                  onTap: onDelete,
                  child: _HeaderActionBtn(
                    icon: Icons.delete_outline_rounded,
                    label: l.delete,
                    color: const Color(0xFFD32F2F).withValues(alpha: 0.25),
                    textColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  const _HeaderActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isThai = ref.watch(isThaiProvider);
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AiraTapEffect(
                onTap: () {
                  ref.read(localeProvider.notifier).state = const Locale('th', 'TH');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isThai ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'TH',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              AiraTapEffect(
                onTap: () {
                  ref.read(localeProvider.notifier).state = const Locale('en', 'US');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isThai ? Colors.transparent : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'EN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

