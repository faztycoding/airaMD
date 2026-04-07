import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';

// ─── Providers ────────────────────────────────────────────────
final _auditLogsProvider = FutureProvider<List<AuditLog>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return [];
  final repo = ref.watch(auditRepoProvider);
  return repo.getRecent(clinicId: clinicId, limit: 200);
});

// ═══════════════════════════════════════════════════════════════
// AUDIT LOG SCREEN
// ═══════════════════════════════════════════════════════════════
class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  String _filterAction = 'ALL';
  String _filterEntity = 'ALL';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(_auditLogsProvider);

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
              boxShadow: [BoxShadow(color: const Color(0xFF6B4F3A).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                AiraTapEffect(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Audit Logs', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('ประวัติการใช้งานระบบ', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                AiraTapEffect(
                  onTap: () => ref.invalidate(_auditLogsProvider),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ─── Filters ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Search
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'ค้นหา...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AiraColors.muted),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AiraColors.creamDk)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Action filter
                Expanded(
                  flex: 2,
                  child: _FilterChip(
                    label: _filterAction == 'ALL' ? 'ทุก Action' : _filterAction,
                    onTap: () => _showFilterDialog('action'),
                  ),
                ),
                const SizedBox(width: 8),
                // Entity filter
                Expanded(
                  flex: 2,
                  child: _FilterChip(
                    label: _filterEntity == 'ALL' ? 'ทุก Entity' : _filterEntity,
                    onTap: () => _showFilterDialog('entity'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ─── Logs list ───
          Expanded(
            child: logsAsync.when(
              data: (logs) {
                var filtered = logs;
                if (_filterAction != 'ALL') {
                  filtered = filtered.where((l) => l.action == _filterAction).toList();
                }
                if (_filterEntity != 'ALL') {
                  filtered = filtered.where((l) => l.entityType == _filterEntity).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((l) =>
                    (l.action.toLowerCase().contains(_searchQuery)) ||
                    (l.entityType?.toLowerCase().contains(_searchQuery) ?? false) ||
                    (l.entityId?.toLowerCase().contains(_searchQuery) ?? false) ||
                    (l.userId?.toLowerCase().contains(_searchQuery) ?? false)
                  ).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 48, color: AiraColors.muted.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('ไม่มีรายการ', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _AuditLogCard(log: filtered[i]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(String type) {
    final logsAsync = ref.read(_auditLogsProvider);
    final logs = logsAsync.valueOrNull ?? [];

    final values = <String>{'ALL'};
    for (final l in logs) {
      if (type == 'action') {
        values.add(l.action);
      } else {
        if (l.entityType != null) values.add(l.entityType!);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(type == 'action' ? 'เลือก Action' : 'เลือก Entity',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
        children: values.map((v) => SimpleDialogOption(
          onPressed: () {
            setState(() {
              if (type == 'action') _filterAction = v;
              else _filterEntity = v;
            });
            Navigator.pop(ctx);
          },
          child: Text(v, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
        )).toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AiraColors.woodWash.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AiraColors.charcoal), overflow: TextOverflow.ellipsis),
            ),
            const Icon(Icons.arrow_drop_down_rounded, size: 18, color: AiraColors.muted),
          ],
        ),
      ),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  final AuditLog log;
  const _AuditLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _actionStyle(log.action);
    final dateStr = log.timestamp != null
        ? DateFormat('d/M/yy HH:mm:ss').format(log.timestamp!)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                      child: Text(log.action, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                    ),
                    if (log.entityType != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AiraColors.woodWash.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
                        child: Text(log.entityType!, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w600, color: AiraColors.woodMid)),
                      ),
                    ],
                    const Spacer(),
                    Text(dateStr, style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AiraColors.muted)),
                  ],
                ),
                if (log.entityId != null) ...[
                  const SizedBox(height: 4),
                  Text('ID: ${log.entityId}', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AiraColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                if (log.userId != null) ...[
                  const SizedBox(height: 2),
                  Text('User: ${log.userId}', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AiraColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _actionStyle(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('create') || lower.contains('insert') || lower.contains('add')) {
      return (Icons.add_circle_rounded, AiraColors.sage);
    }
    if (lower.contains('update') || lower.contains('edit')) {
      return (Icons.edit_rounded, AiraColors.gold);
    }
    if (lower.contains('delete') || lower.contains('remove')) {
      return (Icons.delete_rounded, AiraColors.terra);
    }
    if (lower.contains('login') || lower.contains('auth')) {
      return (Icons.login_rounded, AiraColors.woodMid);
    }
    if (lower.contains('view') || lower.contains('read') || lower.contains('access')) {
      return (Icons.visibility_rounded, AiraColors.muted);
    }
    return (Icons.history_rounded, AiraColors.charcoal);
  }
}
