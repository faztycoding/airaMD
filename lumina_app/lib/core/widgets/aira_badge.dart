import 'package:flutter/material.dart';
import '../../config/theme.dart';

enum BadgeType { newStatus, confirmed, followUp, vip, star, completed, cancelled }

/// Status badge with color coding
class AiraBadge extends StatelessWidget {
  final String label;
  final BadgeType type;

  const AiraBadge({
    super.key,
    required this.label,
    required this.type,
  });

  factory AiraBadge.fromAppointmentStatus(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return AiraBadge(label: 'ใหม่', type: BadgeType.newStatus);
      case 'CONFIRMED':
        return AiraBadge(label: 'ยืนยัน', type: BadgeType.confirmed);
      case 'FOLLOW_UP':
        return AiraBadge(label: 'ติดตามผล', type: BadgeType.followUp);
      case 'COMPLETED':
        return AiraBadge(label: 'เสร็จ', type: BadgeType.completed);
      case 'CANCELLED':
        return AiraBadge(label: 'ยกเลิก', type: BadgeType.cancelled);
      case 'NO_SHOW':
        return AiraBadge(label: 'ไม่มา', type: BadgeType.cancelled);
      default:
        return AiraBadge(label: status, type: BadgeType.newStatus);
    }
  }

  factory AiraBadge.patientStatus(String status) {
    switch (status.toUpperCase()) {
      case 'VIP':
        return const AiraBadge(label: 'VIP', type: BadgeType.vip);
      case 'STAR':
        return const AiraBadge(label: '⭐⭐⭐', type: BadgeType.star);
      default:
        return AiraBadge(label: status, type: BadgeType.newStatus);
    }
  }

  Color get _backgroundColor {
    switch (type) {
      case BadgeType.newStatus:
        return AiraColors.woodWash;
      case BadgeType.confirmed:
        return AiraColors.sage.withValues(alpha: 0.15);
      case BadgeType.followUp:
        return AiraColors.gold.withValues(alpha: 0.15);
      case BadgeType.vip:
        return AiraColors.gold.withValues(alpha: 0.20);
      case BadgeType.star:
        return AiraColors.terra.withValues(alpha: 0.15);
      case BadgeType.completed:
        return AiraColors.sage.withValues(alpha: 0.15);
      case BadgeType.cancelled:
        return AiraColors.muted.withValues(alpha: 0.15);
    }
  }

  Color get _textColor {
    switch (type) {
      case BadgeType.newStatus:
        return AiraColors.woodDk;
      case BadgeType.confirmed:
        return AiraColors.sage;
      case BadgeType.followUp:
        return AiraColors.gold;
      case BadgeType.vip:
        return AiraColors.gold;
      case BadgeType.star:
        return AiraColors.terra;
      case BadgeType.completed:
        return AiraColors.sage;
      case BadgeType.cancelled:
        return AiraColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      ),
    );
  }
}
