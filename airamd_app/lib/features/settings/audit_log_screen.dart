import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/localization/app_localizations.dart';

// ─── Providers ────────────────────────────────────────────────
final _auditLogsProvider = FutureProvider<List<AuditLog>>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null || clinicId.isEmpty) return [];
  try {
    final repo = ref.watch(auditRepoProvider);
    return await repo.getRecent(clinicId: clinicId, limit: 200);
  } catch (e) {
    return [];
  }
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
    final l = context.l10n;
    final previewLogs = logsAsync.valueOrNull ?? const <AuditLog>[];
    final previewFiltered = _applyFilters(previewLogs);

    return Scaffold(
      backgroundColor: AiraColors.cream,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _handleBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l.auditLogs),
        actions: [
          IconButton(
            onPressed: _handleExport,
            icon: const Icon(Icons.file_download_rounded),
          ),
          IconButton(
            onPressed: _handleRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  _AuditOverviewCard(
                    totalCount: previewLogs.length,
                    filteredCount: previewFiltered.length,
                    activeFilterCount: _activeFilterCount,
                    dateRangeLabel: _dateRangeLabel(context),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AiraColors.cardGlow,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.16)),
                      boxShadow: [
                        BoxShadow(
                          color: AiraColors.woodDk.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: AiraColors.gold.withValues(alpha: 0.05),
                          blurRadius: 28,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.isThai ? 'ตัวกรองและการค้นหา' : 'Filters & Search',
                                    style: AiraFonts.body(fontSize: 16, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l.isThai
                                        ? 'ค้นหาและโฟกัสรายการที่ต้องการตรวจสอบได้อย่างรวดเร็ว'
                                        : 'Find the exact activity you want to review more quickly.',
                                    style: AiraFonts.body(fontSize: 12, color: AiraColors.muted, height: 1.45),
                                  ),
                                ],
                              ),
                            ),
                            if (_activeFilterCount > 0)
                              TextButton.icon(
                                onPressed: _clearFilters,
                                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                                label: Text(l.isThai ? 'ล้างตัวกรอง' : 'Reset filters'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: 250,
                              child: _FilterChip(
                                label: _searchQuery.isEmpty
                                    ? l.searchAuditLogs
                                    : (l.isThai ? 'ค้นหา: $_searchQuery' : 'Search: $_searchQuery'),
                                onTap: _openSearchDialog,
                                leadingIcon: Icons.search_rounded,
                                isActive: _searchQuery.isNotEmpty,
                              ),
                            ),
                            SizedBox(
                              width: 170,
                              child: _FilterChip(
                                label: _filterAction == 'ALL' ? (l.isThai ? 'ทุก Action' : 'All actions') : _filterAction,
                                onTap: () => _showFilterDialog('action'),
                                leadingIcon: Icons.bolt_rounded,
                                isActive: _filterAction != 'ALL',
                              ),
                            ),
                            SizedBox(
                              width: 170,
                              child: _FilterChip(
                                label: _filterEntity == 'ALL' ? (l.isThai ? 'ทุก Entity' : 'All entities') : _filterEntity,
                                onTap: () => _showFilterDialog('entity'),
                                leadingIcon: Icons.category_rounded,
                                isActive: _filterEntity != 'ALL',
                              ),
                            ),
                            SizedBox(
                              width: 190,
                              child: _FilterChip(
                                label: _dateRange != null
                                    ? '${DateFormat('d/M').format(_dateRange!.start)} - ${DateFormat('d/M').format(_dateRange!.end)}'
                                    : (l.isThai ? 'ทุกช่วงเวลา' : 'All time'),
                                onTap: _pickDateRange,
                                leadingIcon: Icons.calendar_month_rounded,
                                isActive: _dateRange != null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: logsAsync.when(
                      data: (logs) {
                        final filtered = _applyFilters(logs);

                        if (filtered.isEmpty) {
                          return _AuditEmptyState(hasActiveFilters: _activeFilterCount > 0);
                        }

                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.16)),
                            boxShadow: [
                              BoxShadow(
                                color: AiraColors.woodDk.withValues(alpha: 0.05),
                                blurRadius: 26,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            l.isThai ? 'รายการกิจกรรมล่าสุด' : 'Recent activity',
                                            style: AiraFonts.body(fontSize: 16, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            l.isThai
                                                ? 'แตะรายการเพื่อดูรายละเอียดการเปลี่ยนแปลง'
                                                : 'Tap any entry to inspect its full change details.',
                                            style: AiraFonts.body(fontSize: 12, color: AiraColors.muted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AiraColors.parchment,
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: AiraColors.creamDk),
                                      ),
                                      child: Text(
                                        l.isThai ? '${filtered.length} รายการ' : '${filtered.length} entries',
                                        style: AiraFonts.body(fontSize: 12, fontWeight: FontWeight.w700, color: AiraColors.woodMid),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 1, color: AiraColors.creamDk.withValues(alpha: 0.9)),
                              Expanded(
                                child: ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) => AiraTapEffect(
                                    onTap: () => _showLogDetail(filtered[i]),
                                    child: _AuditLogCard(log: filtered[i]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: AiraColors.woodMid)),
                      error: (e, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Error: $e',
                            textAlign: TextAlign.center,
                            style: AiraFonts.body(fontSize: 13, color: AiraColors.terra),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<AuditLog> _applyFilters(List<AuditLog> logs) {
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
    return filtered;
  }

  int get _activeFilterCount {
    var count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_filterAction != 'ALL') count++;
    if (_filterEntity != 'ALL') count++;
    if (_dateRange != null) count++;
    return count;
  }

  String _dateRangeLabel(BuildContext context) {
    if (_dateRange == null) {
      return context.l10n.isThai ? 'ทุกช่วงเวลา' : 'All time';
    }
    return '${DateFormat('d MMM').format(_dateRange!.start)} - ${DateFormat('d MMM').format(_dateRange!.end)}';
  }

  void _clearFilters() {
    setState(() {
      _filterAction = 'ALL';
      _filterEntity = 'ALL';
      _searchQuery = '';
      _dateRange = null;
    });
  }

  void _handleBack() {
    debugPrint('[AuditLogs] Back pressed');
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/settings');
  }

  Future<void> _handleRefresh() async {
    debugPrint('[AuditLogs] Refresh pressed');
    ref.invalidate(_auditLogsProvider);
    try {
      await ref.read(_auditLogsProvider.future).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.isThai ? 'รีเฟรชข้อมูลเรียบร้อย' : 'Audit logs refreshed'),
          backgroundColor: AiraColors.sage,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.isThai ? 'รีเฟรชข้อมูลไม่สำเร็จ' : 'Failed to refresh audit logs'),
          backgroundColor: AiraColors.terra,
        ),
      );
    }
  }

  Future<void> _handleExport() async {
    debugPrint('[AuditLogs] Export pressed');
    final exported = await _exportCsv();
    if (!mounted) return;
    if (exported == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.isThai ? 'ไม่มีข้อมูลสำหรับส่งออก' : 'No audit logs to export'),
          backgroundColor: AiraColors.woodMid,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.isThai ? 'เตรียมไฟล์ CSV เรียบร้อยแล้ว' : 'CSV file prepared successfully'),
        backgroundColor: AiraColors.sage,
      ),
    );
  }

  Future<void> _openSearchDialog() async {
    final controller = TextEditingController(text: _searchQuery);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          context.l10n.searchAuditLogs,
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.l10n.searchAuditLogs,
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: Text(context.l10n.isThai ? 'ล้าง' : 'Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(context.l10n.isThai ? 'ค้นหา' : 'Search'),
          ),
        ],
      ),
    );
    if (result == null) return;
    setState(() => _searchQuery = result.trim().toLowerCase());
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

  Future<String?> _exportCsv() async {
    final logsAsync = ref.read(_auditLogsProvider);
    final logs = logsAsync.valueOrNull ?? [];
    if (logs.isEmpty) return null;

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
      await Share.shareXFiles([XFile(file.path)]);
      return file.path;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.exportFailed('$e')), backgroundColor: AiraColors.terra),
        );
      }
      return null;
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
              if (type == 'action') {
                _filterAction = v;
              } else {
                _filterEntity = v;
              }
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
  final IconData? leadingIcon;
  final bool isActive;
  const _FilterChip({required this.label, required this.onTap, this.leadingIcon, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return AiraTapEffect(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFFFFFCF8), Color(0xFFF5E7D7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isActive ? null : AiraColors.parchment,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? AiraColors.woodPale.withValues(alpha: 0.6)
                : AiraColors.creamDk.withValues(alpha: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: AiraColors.woodDk.withValues(alpha: isActive ? 0.08 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 16,
                color: isActive ? AiraColors.woodMid : AiraColors.muted,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AiraColors.charcoal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isActive ? AiraColors.woodMid : AiraColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditOverviewCard extends StatelessWidget {
  final int totalCount;
  final int filteredCount;
  final int activeFilterCount;
  final String dateRangeLabel;
  const _AuditOverviewCard({required this.totalCount, required this.filteredCount, required this.activeFilterCount, required this.dateRangeLabel});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AiraColors.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AiraColors.woodDk.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: const Icon(Icons.history_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.auditLogs,
                      style: AiraFonts.heading(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.isThai
                          ? 'ติดตามกิจกรรมในระบบ การเข้าถึงข้อมูล และการเปลี่ยนแปลงสำคัญแบบรวมศูนย์'
                          : 'Track system activity, data access, and key operational changes in one place.',
                      style: AiraFonts.body(fontSize: 13, color: Colors.white.withValues(alpha: 0.82), height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _AuditMetricCard(
                label: l.isThai ? 'ทั้งหมด' : 'Total logs',
                value: '$totalCount',
                icon: Icons.receipt_long_rounded,
              ),
              _AuditMetricCard(
                label: l.isThai ? 'ที่แสดงผล' : 'Visible now',
                value: '$filteredCount',
                icon: Icons.tune_rounded,
              ),
              _AuditMetricCard(
                label: l.isThai ? 'ตัวกรองที่ใช้' : 'Active filters',
                value: '$activeFilterCount',
                icon: Icons.filter_alt_rounded,
              ),
              _AuditMetricCard(
                label: l.isThai ? 'ช่วงเวลา' : 'Time range',
                value: dateRangeLabel,
                icon: Icons.calendar_today_rounded,
                compactValue: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuditMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool compactValue;
  const _AuditMetricCard({required this.label, required this.value, required this.icon, this.compactValue = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AiraFonts.body(fontSize: 11, color: Colors.white.withValues(alpha: 0.72))),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: compactValue
                      ? AiraFonts.body(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700)
                      : AiraFonts.numeric(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditEmptyState extends StatelessWidget {
  final bool hasActiveFilters;
  const _AuditEmptyState({required this.hasActiveFilters});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
          decoration: BoxDecoration(
            gradient: AiraColors.cardGlow,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.16)),
            boxShadow: [
              BoxShadow(
                color: AiraColors.woodDk.withValues(alpha: 0.05),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AiraColors.woodPale.withValues(alpha: 0.20), AiraColors.gold.withValues(alpha: 0.12)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(Icons.history_toggle_off_rounded, size: 34, color: AiraColors.woodMid),
              ),
              const SizedBox(height: 20),
              Text(
                hasActiveFilters ? (l.isThai ? 'ไม่พบข้อมูลที่ตรงกับตัวกรอง' : 'No matching audit logs') : l.noTransactions,
                textAlign: TextAlign.center,
                style: AiraFonts.body(fontSize: 18, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
              ),
              const SizedBox(height: 8),
              Text(
                hasActiveFilters
                    ? (l.isThai
                        ? 'ลองเปลี่ยนเงื่อนไขการค้นหา หรือปรับช่วงเวลาเพื่อดูข้อมูลเพิ่มเติม'
                        : 'Try adjusting your search keywords, entity, action, or time range.')
                    : (l.isThai
                        ? 'เมื่อมีการใช้งานระบบหรือการเปลี่ยนแปลงข้อมูล รายการจะแสดงในส่วนนี้'
                        : 'System events and data changes will appear here once activity is recorded.'),
                textAlign: TextAlign.center,
                style: AiraFonts.body(fontSize: 13, color: AiraColors.muted, height: 1.55),
              ),
            ],
          ),
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
    final title = log.entityId?.isNotEmpty == true
        ? log.entityId!
        : (log.entityType?.isNotEmpty == true ? log.entityType! : (context.l10n.isThai ? 'เหตุการณ์ระบบ' : 'System event'));
    final subtitleParts = <String>[
      if (log.userId?.isNotEmpty == true) 'User ${log.userId}',
      if (dateStr.isNotEmpty) dateStr,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AiraColors.cardGlow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: AiraColors.woodDk.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(999)),
                      child: Text(log.action, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                    ),
                    if (log.entityType != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(color: AiraColors.woodWash.withValues(alpha: 0.38), borderRadius: BorderRadius.circular(999)),
                        child: Text(log.entityType!, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w600, color: AiraColors.woodMid)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AiraFonts.body(fontSize: 15, fontWeight: FontWeight.w700, color: AiraColors.charcoal),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleParts.isEmpty ? (context.l10n.isThai ? 'แตะเพื่อดูรายละเอียด' : 'Tap to view details') : subtitleParts.join('  •  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AiraColors.muted),
                ),
                if (log.entityId != null && log.entityType != log.entityId) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AiraColors.creamDk),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fingerprint_rounded, size: 14, color: AiraColors.muted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ID: ${log.entityId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(fontSize: 11, color: AiraColors.woodMid, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AiraColors.muted.withValues(alpha: 0.8)),
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
