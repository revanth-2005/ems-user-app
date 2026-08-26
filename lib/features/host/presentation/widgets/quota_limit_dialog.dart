import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/app_router.dart';
import '../../../../core/constants/app_colors.dart';

/// Shows the standardized "Hosting Limit Reached" dialog.
/// Triggered whenever the host reaches their active event quota limit,
/// attempts to create/publish with a full quota, or receives a 400 Quota error from backend.
Future<void> showQuotaLimitDialog(
  BuildContext context, {
  String? message,
  String currentPlanName = 'Basic Event Host',
  int maxAllowed = 5,
}) async {
  final displayMsg = message != null && message.trim().isNotEmpty
      ? message.replaceAll('Exception: ', '').replaceAll('NetworkException: ', '')
      : 'Event Host Subscription limit reached: Your current plan ($currentPlanName) allows hosting up to $maxAllowed active events. Please upgrade your Event Hosting plan to create and publish more events.';

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.getSurface(ctx),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hosting Limit Reached',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppColors.getTextPrimary(ctx),
                  ),
                ),
                Text(
                  'Subscription Upgrade Required',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            displayMsg,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: AppColors.getTextSecondary(ctx),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Upgrade to Pro Creator (20 events) or Enterprise (Unlimited).',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextPrimary(ctx),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'Dismiss',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              color: AppColors.getTextSecondary(ctx),
            ),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          icon: const Icon(Icons.rocket_launch_rounded, size: 16),
          label: Text(
            'Upgrade Plan',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          onPressed: () {
            Navigator.of(ctx).pop();
            context.push(AppRoutes.hostSubscription);
          },
        ),
      ],
    ),
  );
}

/// Checks if an error string represents a backend quota limit error.
bool isSubscriptionQuotaError(dynamic error) {
  if (error == null) return false;
  final str = error.toString().toLowerCase();
  return str.contains('subscription limit') ||
      str.contains('limit reached') ||
      str.contains('allows hosting up to') ||
      str.contains('upgrade your event hosting') ||
      str.contains('plan allows hosting') ||
      str.contains('quota') ||
      str.contains('active events');
}
