import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/models.dart';
import '../../core/widgets/aira_tap_effect.dart';
import 'device_providers.dart';

/// Settings screen to manage the clinic's laser/device list. The OWNER can
/// add / edit / delete machines (e.g. Ulthera Prime, Ultraformer III, Oligio)
/// which then appear as quick-pick chips in the treatment form.
class DeviceSettingsScreen extends ConsumerWidget {
  const DeviceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final isThai = l.isThai;
    final devicesAsync = ref.watch(clinicDevicesProvider);

    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B6650), Color(0xFF6B4F3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                AiraTapEffect(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isThai ? 'เครื่อง / อุปกรณ์' : 'Devices',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isThai
                            ? 'จัดการรายการเครื่องเลเซอร์/อุปกรณ์'
                            : 'Manage laser / device presets',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                AiraTapEffect(
                  onTap: () => _showEditor(context, ref),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: devicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('$e',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, color: AiraColors.terra)),
                ),
              ),
              data: (devices) {
                if (devices.isEmpty) {
                  return _EmptyState(
                    isThai: isThai,
                    onSeed: () => _seed(context, ref),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: devices.length,
                  itemBuilder: (context, i) => _DeviceCard(
                    device: devices[i],
                    isThai: isThai,
                    onEdit: () =>
                        _showEditor(context, ref, existing: devices[i]),
                    onDelete: () => _confirmDelete(context, ref, devices[i]),
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seed(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(clinicDevicesProvider.notifier).seedDefaults();
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ClinicDevice d) async {
    final isThai = context.l10n.isThai;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isThai ? 'ลบเครื่อง' : 'Delete device'),
        content: Text(
            isThai ? 'ต้องการลบ "${d.name}" หรือไม่?' : 'Delete "${d.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isThai ? 'ลบ' : 'Delete',
                style: const TextStyle(color: AiraColors.terra)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(clinicDevicesProvider.notifier).remove(d.id);
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  void _showEditor(BuildContext context, WidgetRef ref,
      {ClinicDevice? existing}) {
    final isThai = context.l10n.isThai;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AiraColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AiraColors.woodPale,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                existing == null
                    ? (isThai ? 'เพิ่มเครื่อง' : 'New device')
                    : (isThai ? 'แก้ไขเครื่อง' : 'Edit device'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AiraColors.charcoal,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  hintText:
                      isThai ? 'เช่น Ulthera Prime' : 'e.g. Ulthera Prime',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AiraColors.woodPale),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AiraColors.woodDk, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AiraColors.woodDk,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final notifier = ref.read(clinicDevicesProvider.notifier);
                    try {
                      if (existing == null) {
                        await notifier.add(name: name);
                      } else {
                        await notifier.edit(existing.copyWith(name: name));
                      }
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                    } catch (e) {
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                      if (context.mounted) _showError(context, e);
                    }
                  },
                  child: Text(
                    context.l10n.save,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, Object e) {
    final isThai = context.l10n.isThai;
    final s = '$e';
    final msg = s.contains('row-level security') || s.contains('permission')
        ? (isThai
            ? 'เฉพาะเจ้าของคลินิก (OWNER) เท่านั้นที่จัดการเครื่องได้'
            : 'Only the clinic OWNER can manage devices')
        : context.l10n.errorMsg(s);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AiraColors.terra),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final ClinicDevice device;
  final bool isThai;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _DeviceCard({
    required this.device,
    required this.isThai,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.precision_manufacturing_rounded,
              color: AiraColors.gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              device.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AiraColors.charcoal,
              ),
            ),
          ),
          AiraTapEffect(
            onTap: onEdit,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child:
                  Icon(Icons.edit_rounded, size: 18, color: AiraColors.woodMid),
            ),
          ),
          const SizedBox(width: 8),
          AiraTapEffect(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.delete_outline_rounded,
                  size: 18, color: AiraColors.terra),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isThai;
  final VoidCallback onSeed;
  const _EmptyState({required this.isThai, required this.onSeed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.precision_manufacturing_outlined,
                size: 64, color: AiraColors.woodPale.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              isThai ? 'ยังไม่มีรายการเครื่อง' : 'No devices yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AiraColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isThai
                  ? 'เริ่มด้วยเครื่องมาตรฐาน: Ulthera Prime, Ultraformer III, Oligio'
                  : 'Start with defaults: Ulthera Prime, Ultraformer III, Oligio',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.5,
                color: AiraColors.muted,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AiraColors.woodDk,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: onSeed,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                isThai ? 'ใช้เครื่องมาตรฐาน' : 'Use default devices',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
