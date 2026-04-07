import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../core/widgets/aira_tap_effect.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: Column(
        children: [
          // ─── Header ───
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B4F3A), Color(0xFF8B6650)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6B4F3A).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                AiraTapEffect(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'นโยบายความเป็นส่วนตัว',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Privacy Policy — PDPA Compliance',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),

          // ─── Content ───
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 60),
                  children: [
                    // Effective date
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AiraColors.sage.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AiraColors.sage.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 16, color: AiraColors.sage),
                          const SizedBox(width: 10),
                          Text(
                            'มีผลบังคับใช้: 1 เมษายน 2569',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AiraColors.sage),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      icon: Icons.info_outline_rounded,
                      title: '1. บทนำ',
                      content:
                          'คลินิกของเรา ("คลินิก") ให้ความสำคัญกับการคุ้มครองข้อมูลส่วนบุคคลของท่าน '
                          'ตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562 (PDPA) '
                          'นโยบายฉบับนี้อธิบายวิธีที่เราเก็บรวบรวม ใช้ เปิดเผย และคุ้มครองข้อมูลส่วนบุคคลของท่าน '
                          'เมื่อท่านใช้บริการของคลินิกผ่านแอปพลิเคชัน airaMD',
                    ),

                    _buildSection(
                      icon: Icons.folder_open_rounded,
                      title: '2. ข้อมูลที่เราเก็บรวบรวม',
                      content: '',
                      bullets: [
                        'ข้อมูลส่วนตัว: ชื่อ-นามสกุล, วันเกิด, เพศ, เลขบัตรประชาชน, หมายเลขหนังสือเดินทาง',
                        'ข้อมูลติดต่อ: เบอร์โทรศัพท์, LINE ID, WhatsApp, อีเมล, ที่อยู่',
                        'ข้อมูลสุขภาพ: ประวัติการแพ้ยา, โรคประจำตัว, การใช้ยา, ประวัติการรักษา (SOAP Notes)',
                        'ข้อมูลชีวมิติ: ลายเซ็นดิจิทัล, รูปใบหน้า (Before/After), ไดอะแกรมการรักษา',
                        'ข้อมูลการเงิน: ประวัติการชำระเงิน, คอร์สที่ซื้อ, ยอดค้างชำระ',
                        'ข้อมูลการใช้แอป: บันทึกการเข้าสู่ระบบ, กิจกรรมในแอป (Audit Logs)',
                      ],
                    ),

                    _buildSection(
                      icon: Icons.gavel_rounded,
                      title: '3. วัตถุประสงค์ในการใช้ข้อมูล',
                      content: '',
                      bullets: [
                        'ให้บริการทางการแพทย์และเสริมความงาม',
                        'จัดทำเวชระเบียนและบันทึกการรักษา',
                        'นัดหมายและแจ้งเตือนผ่าน LINE / WhatsApp',
                        'ติดตามผลการรักษาด้วยรูป Before/After',
                        'จัดการคอร์สการรักษาและการเงิน',
                        'ปฏิบัติตามกฎหมายที่เกี่ยวข้อง',
                        'ปรับปรุงคุณภาพการบริการ',
                      ],
                    ),

                    _buildSection(
                      icon: Icons.share_rounded,
                      title: '4. การเปิดเผยข้อมูล',
                      content:
                          'เราจะไม่เปิดเผยข้อมูลส่วนบุคคลของท่านแก่บุคคลภายนอก ยกเว้นกรณีดังนี้:',
                      bullets: [
                        'ได้รับความยินยอมจากท่าน',
                        'ตามคำสั่งศาลหรือหน่วยงานราชการที่มีอำนาจ',
                        'เพื่อปกป้องชีวิต สุขภาพ หรือผลประโยชน์ที่สำคัญ',
                        'ผู้ให้บริการเทคโนโลยี (Supabase) ที่ปฏิบัติตามมาตรฐานความปลอดภัยสากล',
                      ],
                    ),

                    _buildSection(
                      icon: Icons.lock_rounded,
                      title: '5. มาตรการรักษาความปลอดภัย',
                      content: '',
                      bullets: [
                        'การเข้ารหัสข้อมูลระหว่างส่งและจัดเก็บ (HTTPS/TLS + Encryption at rest)',
                        'ระบบยืนยันตัวตน: PIN Lock + สแกนลายนิ้วมือ/Face ID',
                        'การควบคุมสิทธิ์การเข้าถึงตามบทบาท (RBAC)',
                        'Row-Level Security (RLS) ในระดับฐานข้อมูล',
                        'บันทึกตรวจสอบ (Audit Logs) สำหรับการเปลี่ยนแปลงข้อมูลสำคัญ',
                        'การสำรองข้อมูลอัตโนมัติผ่าน Supabase',
                      ],
                    ),

                    _buildSection(
                      icon: Icons.timer_rounded,
                      title: '6. ระยะเวลาการเก็บรักษาข้อมูล',
                      content:
                          'เราเก็บรักษาข้อมูลส่วนบุคคลตลอดระยะเวลาที่ท่านเป็นผู้รับบริการของคลินิก '
                          'และเก็บต่อไปอีกไม่น้อยกว่า 10 ปี ตามกฎหมายว่าด้วยเวชระเบียน '
                          'หลังพ้นกำหนด ข้อมูลจะถูกลบหรือทำให้ไม่สามารถระบุตัวตนได้',
                    ),

                    _buildSection(
                      icon: Icons.person_rounded,
                      title: '7. สิทธิของเจ้าของข้อมูล',
                      content: 'ท่านมีสิทธิตาม PDPA ดังนี้:',
                      bullets: [
                        'สิทธิในการเข้าถึง: ขอดูข้อมูลส่วนบุคคลของท่าน',
                        'สิทธิในการแก้ไข: ขอแก้ไขข้อมูลให้ถูกต้องและเป็นปัจจุบัน',
                        'สิทธิในการลบ: ขอลบข้อมูล (ภายใต้ข้อจำกัดทางกฎหมาย)',
                        'สิทธิในการระงับ: ขอระงับการใช้ข้อมูลชั่วคราว',
                        'สิทธิในการคัดค้าน: คัดค้านการใช้ข้อมูลในบางกรณี',
                        'สิทธิในการโอนย้าย: ขอรับข้อมูลในรูปแบบที่อ่านได้ด้วยเครื่อง',
                        'สิทธิในการถอนความยินยอม: ถอนความยินยอมได้ทุกเมื่อ',
                      ],
                    ),

                    _buildSection(
                      icon: Icons.child_care_rounded,
                      title: '8. ข้อมูลผู้เยาว์',
                      content:
                          'หากท่านมีอายุต่ำกว่า 20 ปี การเก็บรวบรวมข้อมูลของท่านจะต้องได้รับความยินยอม '
                          'จากผู้ปกครองหรือผู้แทนโดยชอบธรรมก่อน',
                    ),

                    _buildSection(
                      icon: Icons.edit_note_rounded,
                      title: '9. การเปลี่ยนแปลงนโยบาย',
                      content:
                          'คลินิกอาจปรับปรุงนโยบายฉบับนี้เป็นครั้งคราว โดยจะแจ้งให้ท่านทราบผ่านแอปพลิเคชัน '
                          'หรือช่องทางการติดต่อของท่าน การใช้บริการต่อหลังการเปลี่ยนแปลง '
                          'ถือว่าท่านยอมรับนโยบายที่ปรับปรุงแล้ว',
                    ),

                    _buildSection(
                      icon: Icons.phone_rounded,
                      title: '10. ช่องทางการติดต่อ',
                      content:
                          'หากท่านมีคำถามเกี่ยวกับนโยบายฉบับนี้ หรือต้องการใช้สิทธิตาม PDPA '
                          'กรุณาติดต่อเจ้าหน้าที่คุ้มครองข้อมูลส่วนบุคคล (DPO) ของคลินิก '
                          'ผ่านช่องทางที่ระบุในหน้าตั้งค่าของแอปพลิเคชัน',
                    ),

                    const SizedBox(height: 24),

                    // Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AiraColors.woodWash.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user_rounded, size: 20, color: AiraColors.sage),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'airaMD ปฏิบัติตาม พ.ร.บ. คุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562 (PDPA)\nข้อมูลของท่านได้รับการเข้ารหัสและจัดเก็บอย่างปลอดภัย',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AiraColors.muted, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    List<String>? bullets,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AiraColors.creamDk.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AiraColors.woodDk.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AiraColors.woodWash.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: AiraColors.woodMid),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AiraColors.charcoal,
                  ),
                ),
              ],
            ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                content,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AiraColors.charcoal.withValues(alpha: 0.8),
                  height: 1.6,
                ),
              ),
            ],
            if (bullets != null) ...[
              const SizedBox(height: 10),
              ...bullets.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 10, left: 4),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AiraColors.woodMid.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            b,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AiraColors.charcoal.withValues(alpha: 0.75),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
