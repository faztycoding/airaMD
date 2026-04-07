import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/aira_tap_effect.dart';
import '../../core/widgets/aira_premium_form.dart';
import '../../core/localization/app_localizations.dart';

// ─── Provider ─────────────────────────────────────────────────
final _clinicProvider = FutureProvider<Clinic?>((ref) async {
  final clinicId = ref.watch(currentClinicIdProvider);
  if (clinicId == null) return null;
  final client = ref.watch(supabaseClientProvider);
  final data = await client.from('clinics').select().eq('id', clinicId).maybeSingle();
  return data != null ? Clinic.fromJson(data) : null;
});

class ClinicInfoScreen extends ConsumerStatefulWidget {
  const ClinicInfoScreen({super.key});

  @override
  ConsumerState<ClinicInfoScreen> createState() => _ClinicInfoScreenState();
}

class _ClinicInfoScreenState extends ConsumerState<ClinicInfoScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _lineOaCtrl = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _lineOaCtrl.dispose();
    super.dispose();
  }

  void _populateFields(Clinic clinic) {
    if (_loaded) return;
    _nameCtrl.text = clinic.name;
    _addressCtrl.text = clinic.address ?? '';
    _phoneCtrl.text = clinic.phone ?? '';
    _lineOaCtrl.text = clinic.lineOaId ?? '';
    _loaded = true;
  }

  Future<void> _save(Clinic? existing) async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pleaseFillRequired)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final client = ref.read(supabaseClientProvider);
      final clinicId = ref.read(currentClinicIdProvider);
      final updated = Clinic(
        id: existing?.id ?? clinicId ?? '',
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        lineOaId: _lineOaCtrl.text.trim().isEmpty ? null : _lineOaCtrl.text.trim(),
        settings: existing?.settings ?? {},
      );

      if (existing != null) {
        await client.from('clinics').update(updated.toUpdateJson()).eq('id', existing.id);
      } else {
        await client.from('clinics').insert(updated.toInsertJson());
      }

      ref.invalidate(_clinicProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saveSuccess), backgroundColor: AiraColors.sage),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.saveFailed('$e')), backgroundColor: AiraColors.terra),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clinicAsync = ref.watch(_clinicProvider);
    final l = context.l10n;

    return Scaffold(
      backgroundColor: AiraColors.cream,
      appBar: AppBar(title: Text(l.clinicInfo)),
      body: clinicAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text(l.errorMsg('$e'))),
        data: (clinic) {
          if (clinic != null) _populateFields(clinic);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              children: [
                // Clinic avatar
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B4F3A), Color(0xFF8B6650)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF6B4F3A).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Center(child: Icon(Icons.business_rounded, size: 36, color: Colors.white)),
                ),
                const SizedBox(height: 24),
                // Form fields
                _FieldCard(
                  title: l.isThai ? 'ชื่อคลินิก *' : 'Clinic Name *',
                  icon: Icons.business_rounded,
                  child: TextField(
                    controller: _nameCtrl,
                    style: airaFieldTextStyle,
                    decoration: airaFieldDecoration(label: l.isThai ? 'ชื่อคลินิก' : 'Clinic name', prefixIcon: Icons.business_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                _FieldCard(
                  title: l.address,
                  icon: Icons.location_on_rounded,
                  child: TextField(
                    controller: _addressCtrl,
                    style: airaFieldTextStyle,
                    decoration: airaFieldDecoration(label: l.address, prefixIcon: Icons.location_on_rounded),
                    maxLines: 3,
                    minLines: 2,
                  ),
                ),
                const SizedBox(height: 14),
                _FieldCard(
                  title: l.phone,
                  icon: Icons.phone_rounded,
                  child: TextField(
                    controller: _phoneCtrl,
                    style: airaFieldTextStyle,
                    decoration: airaFieldDecoration(label: l.phone, prefixIcon: Icons.phone_rounded),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(height: 14),
                _FieldCard(
                  title: 'LINE OA ID',
                  icon: Icons.chat_rounded,
                  child: TextField(
                    controller: _lineOaCtrl,
                    style: airaFieldTextStyle,
                    decoration: airaFieldDecoration(label: 'LINE OA ID', hint: '@clinic', prefixIcon: Icons.chat_rounded),
                  ),
                ),
                const SizedBox(height: 28),
                // Save button
                AiraTapEffect(
                  onTap: _saving ? null : () => _save(clinic),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF3D2517), Color(0xFF6B4F3A), Color(0xFF8B6650)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_saving) ...[
                          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          const SizedBox(width: 10),
                        ] else ...[
                          const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          _saving ? l.saving : l.saveChanges,
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _FieldCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.6)),
        boxShadow: [BoxShadow(color: AiraColors.woodDk.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AiraColors.woodMid),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AiraColors.muted)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
