import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../bookings/domain/entities/booking_entities.dart';
import '../providers/organizer_providers.dart';

class OrganizerDashboardScreen extends HookConsumerWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(organizerProfileProvider);
    final inboxAsync = ref.watch(bookingInboxProvider);
    final ledgerAsync = ref.watch(payoutLedgerProvider);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Organizer Portal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              profileAsync.valueOrNull?.businessName ?? 'Business Console',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: Text(
              'Customer View',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            onPressed: () {
              ref
                  .read(authStateProvider.notifier)
                  .switchPortal(ActivePortal.CUSTOMER);
              context.go(AppRoutes.home);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tier & Status Card ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            'PRO PLAN ACTIVE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Verified Business',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'KYC Verified • Zero Commission on Direct Referrals',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded,
                        color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Metric Stat Tiles ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Pending Requests',
                    value:
                        '${inboxAsync.valueOrNull?.where((b) => b.status == BookingStatus.REQUESTED).length ?? 1}',
                    icon: Icons.mark_email_unread_outlined,
                    iconColor: AppColors.accentAmber,
                    onTap: () => context.push(AppRoutes.bookingInbox),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatCard(
                    title: 'Total Earnings',
                    value: CurrencyFormatter.formatPaise(
                        ledgerAsync.valueOrNull?.totalEarningsPaise ?? 48500000),
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.statusCompleted,
                    onTap: () => context.push(AppRoutes.payoutLedger),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Management Tools ───────────────────────────────────────────
            Text(
              'Organizer Management',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            _ToolTile(
              title: 'Booking Inbox & SLA Queues',
              subtitle: 'Accept incoming bookings, respond within SLA time',
              icon: Icons.inbox_rounded,
              badgeText: 'Action Required',
              onTap: () => context.push(AppRoutes.bookingInbox),
            ),
            const SizedBox(height: 12),

            _ToolTile(
              title: 'Catalog & Packages Manager',
              subtitle: 'Manage your package pricing, media, and inclusions',
              icon: Icons.inventory_2_outlined,
              onTap: () => context.push(AppRoutes.catalogManager),
            ),
            const SizedBox(height: 12),

            _ToolTile(
              title: 'Availability & Booking Calendar',
              subtitle: 'Block out dates or set holiday blackout windows',
              icon: Icons.calendar_month_outlined,
              onTap: () => context.push(AppRoutes.availabilityCalendar),
            ),
            const SizedBox(height: 12),

            _ToolTile(
              title: 'Payouts & Settlement Ledger',
              subtitle: 'View advance releases and request bank transfers',
              icon: Icons.payments_outlined,
              onTap: () => context.push(AppRoutes.payoutLedger),
            ),
            const SizedBox(height: 12),

            _ToolTile(
              title: 'KYC & Business Registration',
              subtitle: 'GST, PAN verification, and bank details',
              icon: Icons.badge_outlined,
              onTap: () => context.push(AppRoutes.kycRegistration),
            ),
            const SizedBox(height: 12),

            _ToolTile(
              title: 'Onboarding & Business Plan',
              subtitle: 'Upgrade subscription and setup portfolio details',
              icon: Icons.rocket_launch_outlined,
              onTap: () => context.push(AppRoutes.onboardingWizard),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lightBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? badgeText;
  final VoidCallback onTap;

  const _ToolTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badgeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.lightBorder),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (badgeText != null)
                        AppStatusBadge(
                          label: badgeText!,
                          status: BadgeStatus.requested,
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
