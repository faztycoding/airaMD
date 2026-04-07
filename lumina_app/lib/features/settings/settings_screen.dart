import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/widgets/aira_tap_effect.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 4, height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B6650), Color(0xFFD4B89A)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ตั้งค่า',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28, fontWeight: FontWeight.w700, color: AiraColors.charcoal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Body
                Expanded(
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 300, child: _Sidebar()),
                            const SizedBox(width: 20),
                            Expanded(child: _ContentPanel()),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              _Sidebar(),
                              const SizedBox(height: 120),
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

// ═══════════════════════════════════════════════════════════════════
// Sidebar
// ═══════════════════════════════════════════════════════════════════
class _Sidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile card
          _ProfileCard(),
          const SizedBox(height: 20),
          // Setting groups
          _SettingsGroup('คลินิก', [
            _Item(Icons.business_rounded, 'ข้อมูลคลินิก', 'ชื่อ ที่อยู่ เวลาเปิด'),
            _Item(Icons.people_rounded, 'จัดการพนักงาน', 'เพิ่ม/แก้ไข บทบาท'),
            _Item(Icons.inventory_2_rounded, 'คลังผลิตภัณฑ์', 'Botox, Filler, สต๊อก', route: '/settings/products'),
            _Item(Icons.payments_rounded, 'การเงิน', 'รายรับ ค้างชำระ ปิดยอด', route: '/settings/financial'),
          ]),
          const SizedBox(height: 12),
          _SettingsGroup('หัตถการ', [
            _Item(Icons.medical_services_rounded, 'รายการบริการ', 'ราคาหัตถการทั้งหมด', route: '/settings/services'),
            _Item(Icons.card_membership_rounded, 'คอร์ส', 'จัดการคอร์สทรีทเมนต์', route: '/courses'),
            _Item(Icons.description_rounded, 'ใบยินยอม', 'เทมเพลต Consent Form'),
            _Item(Icons.timer_rounded, 'กฎระยะห่าง', 'Botox, Filler, HIFU...'),
          ]),
          const SizedBox(height: 12),
          _SettingsGroup('ระบบ', [
            _Item(Icons.language_rounded, 'ภาษา', 'ไทย / English'),
            _Item(Icons.shield_rounded, 'ความปลอดภัย', 'PIN, Auto-lock'),
            _Item(Icons.cloud_sync_rounded, 'ข้อมูลคลาวด์', 'Backup, Sync'),
            _Item(Icons.privacy_tip_rounded, 'PDPA', 'นโยบายความเป็นส่วนตัว', route: '/settings/privacy'),
          ]),
          const SizedBox(height: 20),
          // Version
          Text(
            'airaMD v1.0.0',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4F3A), Color(0xFF8B6650)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4F3A).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
            ),
            child: const Center(
              child: Icon(Icons.medical_services_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. Pammy',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Admin',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.edit_rounded, size: 16, color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

class _Item {
  final IconData icon;
  final String label, subtitle;
  final String? route;
  const _Item(this.icon, this.label, this.subtitle, {this.route});
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_Item> items;
  const _SettingsGroup(this.title, this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AiraColors.muted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: AiraColors.woodDk.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  AiraTapEffect(
                    onTap: item.route != null ? () => context.push(item.route!) : null,
                    child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AiraColors.woodWash.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.icon, size: 18, color: AiraColors.woodMid),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.charcoal),
                              ),
                              Text(
                                item.subtitle,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AiraColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 18, color: AiraColors.muted.withValues(alpha: 0.5)),
                      ],
                    ),
                  ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 64,
                      endIndent: 14,
                      color: AiraColors.creamDk.withValues(alpha: 0.5),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Content Panel (right side)
// ═══════════════════════════════════════════════════════════════════
class _ContentPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AiraColors.woodDk.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AiraColors.woodWash.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.settings_rounded,
                size: 32,
                color: AiraColors.muted.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'เลือกเมนูด้านซ้ายเพื่อตั้งค่า',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AiraColors.muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'การตั้งค่าจะแสดงในพื้นที่นี้',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AiraColors.muted.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
