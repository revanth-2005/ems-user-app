import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

enum BadgeStatus {
  completed,
  rescheduled,
  cancelled,
  pending,
  requested,
  accepted,
  custom,
}

class AppStatusBadge extends StatelessWidget {
  final String label;
  final BadgeStatus status;
  final Color? customColor;
  final IconData? icon;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.status = BadgeStatus.pending,
    this.customColor,
    this.icon,
  });

  Color _getColor() {
    if (customColor != null) return customColor!;
    switch (status) {
      case BadgeStatus.completed:
      case BadgeStatus.accepted:
        return AppColors.statusCompleted;
      case BadgeStatus.rescheduled:
      case BadgeStatus.requested:
        return AppColors.statusRescheduled;
      case BadgeStatus.cancelled:
        return AppColors.statusCancelled;
      case BadgeStatus.pending:
      case BadgeStatus.custom:
        return AppColors.statusPending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
