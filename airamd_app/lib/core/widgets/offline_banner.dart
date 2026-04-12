import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../services/offline_sync_service.dart';

// ═══════════════════════════════════════════════════════════════
// OFFLINE BANNER — Shows connectivity + pending sync status
// ═══════════════════════════════════════════════════════════════

/// A banner that shows at the top when offline + pending ops count.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final pendingAsync = ref.watch(pendingOpsCountProvider);

    if (isOnline) {
      // Show a brief "back online" indicator if there were pending ops
      return pendingAsync.when(
        data: (count) {
          if (count > 0) {
            return _SyncBanner(
              color: AiraColors.gold,
              icon: Icons.sync_rounded,
              text: 'กลับออนไลน์แล้ว — มี $count รายการรอซิงค์',
            );
          }
          return const SizedBox.shrink();
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      );
    }

    // Offline state
    return pendingAsync.when(
      data: (count) => _SyncBanner(
        color: AiraColors.terra,
        icon: Icons.cloud_off_rounded,
        text: count > 0
            ? 'ออฟไลน์ — $count รายการรอซิงค์'
            : 'ออฟไลน์ — ข้อมูลจะถูกบันทึกเมื่อกลับมาออนไลน์',
      ),
      loading: () => _SyncBanner(
        color: AiraColors.terra,
        icon: Icons.cloud_off_rounded,
        text: 'ออฟไลน์',
      ),
      error: (_, __) => _SyncBanner(
        color: AiraColors.terra,
        icon: Icons.cloud_off_rounded,
        text: 'ออฟไลน์',
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  const _SyncBanner({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.2))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sync status card for Settings screen — shows last sync time + pending ops.
class SyncStatusCard extends ConsumerWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final pendingAsync = ref.watch(pendingOpsCountProvider);
    final lastSyncAsync = ref.watch(lastSyncTimeProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOnline ? AiraColors.sage.withValues(alpha: 0.2) : AiraColors.terra.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                size: 20,
                color: isOnline ? AiraColors.sage : AiraColors.terra,
              ),
              const SizedBox(width: 8),
              Text(
                isOnline ? 'ออนไลน์' : 'ออฟไลน์',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: isOnline ? AiraColors.sage : AiraColors.terra,
                ),
              ),
              const Spacer(),
              pendingAsync.when(
                data: (count) => count > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AiraColors.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$count รายการรอซิงค์',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AiraColors.gold),
                        ),
                      )
                    : Text('ซิงค์สมบูรณ์', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.sage)),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          lastSyncAsync.when(
            data: (dt) => Text(
              dt != null
                  ? 'ซิงค์ล่าสุด: ${DateFormat('d/M/yy HH:mm').format(dt)}'
                  : 'ยังไม่เคยซิงค์',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
