import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../providers/providers.dart';

enum AiraPermission {
  settings,
  financial,
  clinical,
}

class AccessGuard extends ConsumerWidget {
  final AiraPermission permission;
  final Widget child;
  const AccessGuard({super.key, required this.permission, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    final allowed = _isAllowed(ref);
    if (allowed) return child;
    return Scaffold(
      backgroundColor: AiraColors.cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _AccessDeniedPanel(
                title: _title(isThai),
                description: _description(isThai),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isAllowed(WidgetRef ref) {
    switch (permission) {
      case AiraPermission.settings:
        return ref.watch(canAccessSettingsProvider);
      case AiraPermission.financial:
        return ref.watch(canAccessFinancialDataProvider);
      case AiraPermission.clinical:
        return ref.watch(canManageClinicalDataProvider);
    }
  }

  String _title(bool isThai) {
    switch (permission) {
      case AiraPermission.settings:
        return isThai ? 'ไม่มีสิทธิ์เข้าถึงการตั้งค่า' : 'No access to settings';
      case AiraPermission.financial:
        return isThai ? 'ไม่มีสิทธิ์เข้าถึงข้อมูลการเงิน' : 'No access to financial data';
      case AiraPermission.clinical:
        return isThai ? 'ไม่มีสิทธิ์เข้าถึงข้อมูลการรักษา' : 'No access to clinical data';
    }
  }

  String _description(bool isThai) {
    switch (permission) {
      case AiraPermission.settings:
        return isThai
            ? 'บัญชีพนักงานถูกจำกัดสิทธิ์สำหรับหน้าตั้งค่า กรุณาใช้บัญชีหมอหรือเจ้าของระบบ'
            : 'Staff accounts are restricted from settings. Please use a doctor or owner account.';
      case AiraPermission.financial:
        return isThai
            ? 'ข้อมูลรายรับ ยอดค้าง และประวัติการชำระจะแสดงเฉพาะบัญชีหมอหรือเจ้าของระบบ'
            : 'Revenue, outstanding balances, and payment history are available only to doctor or owner accounts.';
      case AiraPermission.clinical:
        return isThai
            ? 'การสร้างหรือแก้ไขข้อมูลการรักษา, consent และ face diagram จำกัดเฉพาะบัญชีหมอหรือเจ้าของระบบ'
            : 'Creating or editing treatment records, consent, and face diagrams is limited to doctor or owner accounts.';
    }
  }
}

class InlineAccessGuard extends ConsumerWidget {
  final AiraPermission permission;
  const InlineAccessGuard({super.key, required this.permission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(isThaiProvider);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: _AccessDeniedPanel(
        title: switch (permission) {
          AiraPermission.settings => isThai ? 'ส่วนนี้ถูกจำกัดสิทธิ์' : 'This section is restricted',
          AiraPermission.financial => isThai ? 'ข้อมูลการเงินถูกจำกัดสิทธิ์' : 'Financial data is restricted',
          AiraPermission.clinical => isThai ? 'ข้อมูลการรักษาถูกจำกัดสิทธิ์' : 'Clinical data is restricted',
        },
        description: switch (permission) {
          AiraPermission.settings => isThai ? 'ใช้บัญชีหมอหรือเจ้าของระบบเพื่อเข้าถึงส่วนนี้' : 'Use a doctor or owner account to open this section.',
          AiraPermission.financial => isThai ? 'ใช้บัญชีหมอหรือเจ้าของระบบเพื่อดู spending และ payment history' : 'Use a doctor or owner account to view spending and payment history.',
          AiraPermission.clinical => isThai ? 'ใช้บัญชีหมอหรือเจ้าของระบบเพื่อบันทึกหรือแก้ไขข้อมูลการรักษา' : 'Use a doctor or owner account to create or edit clinical records.',
        },
      ),
    );
  }
}

class _AccessDeniedPanel extends StatelessWidget {
  final String title;
  final String description;
  const _AccessDeniedPanel({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AiraColors.woodPale.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AiraColors.woodDk.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AiraColors.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, size: 30, color: AiraColors.gold),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AiraColors.charcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.5,
              color: AiraColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
