import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/localization/app_localizations.dart';

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
  DateTimeRange? _dateRange;

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
                      Text(context.l10n.auditLogTitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                AiraTapEffect(
                  onTap: () => _exportCsv(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.file_download_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
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
                const SizedBox(width: 8),
                // Date range
                _FilterChip(
                  label: _dateRange != null
                      ? '${DateFormat('d/M').format(_dateRange!.start)}-${DateFormat('d/M').format(_dateRange!.end)}'
                      : '📅',
                  onTap: _pickDateRange,
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
                if (_dateRange != null) {
                  filtered = filtered.where((l) {
                    if (l.timestamp == null) return false;
                    return l.timestamp!.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
                           l.timestamp!.isBefore(_dateRange!.end.add(const Duration(days: 1)));
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 48, color: AiraColors.muted.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(context.l10n.noTransactions, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AiraColors.muted)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => AiraTapEffect(
                    onTap: () => _showLogDetail(filtered[i]),
                    child: _AuditLogCard(log: filtered[i]),
                  ),
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

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _dateRange ?? DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AiraColors.woodMid,
            onPrimary: Colors.white,
            surface: AiraColors.cream,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _showLogDetail(AuditLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AuditLogDetailSheet(log: log),
    );
  }

  Future<void> _exportCsv() async {
    final logsAsync = ref.read(_auditLogsProvider);
    final logs = logsAsync.valueOrNull ?? [];
    if (logs.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Action,Entity Type,Entity ID,User ID,Old Data,New Data');
    for (final log in logs) {
      final ts = log.timestamp?.toIso8601String() ?? '';
      final oldJson = log.oldData != null ? '"${jsonEncode(log.oldData).replaceAll('"', '""')}"' : '';
      final newJson = log.newData != null ? '"${jsonEncode(log.newData).replaceAll('"', '""')}"' : '';
      buffer.writeln('$ts,${log.action},${log.entityType ?? ''},${log.entityId ?? ''},${log.userId ?? ''},$oldJson,$newJson');
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/audit_logs_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv');
      await file.writeAsString(buffer.toString());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.exportFailed('$e')), backgroundColor: AiraColors.terra),
        );
      }
    }
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

// ═══════════════════════════════════════════════════════════════
// AUDIT LOG DETAIL SHEET — Old/New Data Diff
// ═══════════════════════════════════════════════════════════════
class _AuditLogDetailSheet extends StatelessWidget {
  final AuditLog log;
  const _AuditLogDetailSheet({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateStr = log.timestamp != null
        ? DateFormat('d MMM yyyy HH:mm:ss').format(log.timestamp!)
        : 'N/A';

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AiraColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AiraColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text('Audit Log Detail', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
            const SizedBox(height: 16),

            // Info rows
            _DetailRow(label: 'Action', value: log.action),
            _DetailRow(label: 'Entity Type', value: log.entityType ?? '-'),
            _DetailRow(label: 'Entity ID', value: log.entityId ?? '-'),
            _DetailRow(label: 'User ID', value: log.userId ?? '-'),
            _DetailRow(label: 'Timestamp', value: dateStr),
            _DetailRow(label: 'IP Address', value: log.ipAddress ?? '-'),

            const SizedBox(height: 16),

            // Old data
            if (log.oldData != null && log.oldData!.isNotEmpty) ...[
              _SectionHeader(label: 'Old Data', color: AiraColors.terra),
              _JsonBlock(data: log.oldData!, highlightColor: AiraColors.terra.withValues(alpha: 0.05)),
              const SizedBox(height: 12),
            ],

            // New data
            if (log.newData != null && log.newData!.isNotEmpty) ...[
              _SectionHeader(label: 'New Data', color: AiraColors.sage),
              _JsonBlock(data: log.newData!, highlightColor: AiraColors.sage.withValues(alpha: 0.05)),
              const SizedBox(height: 12),
            ],

            // Diff view
            if (log.oldData != null && log.newData != null) ...[
              _SectionHeader(label: 'Changes', color: AiraColors.gold),
              _DiffView(oldData: log.oldData!, newData: log.newData!),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.muted)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AiraColors.charcoal)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AiraColors.charcoal)),
        ],
      ),
    );
  }
}

class _JsonBlock extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color highlightColor;
  const _JsonBlock({required this.data, required this.highlightColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlightColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.entries.map((e) {
          final val = e.value is Map || e.value is List
              ? const JsonEncoder.withIndent('  ').convert(e.value)
              : '${e.value}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '${e.key}: ', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: AiraColors.woodMid)),
                  TextSpan(text: val, style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AiraColors.charcoal)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DiffView extends StatelessWidget {
  final Map<String, dynamic> oldData;
  final Map<String, dynamic> newData;
  const _DiffView({required this.oldData, required this.newData});

  @override
  Widget build(BuildContext context) {
    final allKeys = {...oldData.keys, ...newData.keys};
    final changedKeys = allKeys.where((k) {
      final oldVal = oldData[k];
      final newVal = newData[k];
      return oldVal?.toString() != newVal?.toString();
    }).toList();

    if (changedKeys.isEmpty) {
      return Text('No changes detected', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: changedKeys.map((key) {
          final oldVal = oldData[key]?.toString() ?? '(empty)';
          final newVal = newData[key]?.toString() ?? '(empty)';
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AiraColors.creamDk.withValues(alpha: 0.3))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(key, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: AiraColors.woodMid)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AiraColors.terra.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('- $oldVal', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AiraColors.terra), maxLines: 3, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward_rounded, size: 14, color: AiraColors.muted)),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AiraColors.sage.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('+ $newVal', style: GoogleFonts.spaceGrotesk(fontSize: 10, color: AiraColors.sage), maxLines: 3, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
