import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../bookings/domain/entities/booking_entities.dart';
import '../../../chatbot/presentation/widgets/floating_ai_assistant_button.dart';
import '../providers/organizer_providers.dart';

class OrganizerHubScreen extends HookConsumerWidget {
  const OrganizerHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(organizerProfileProvider);
    final packagesAsync = ref.watch(organizerPackagesProvider);
    final servicesAsync = ref.watch(organizerServicesProvider);
    final bookingsAsync = ref.watch(bookingInboxProvider);
    final ledgerAsync = ref.watch(payoutLedgerProvider);

    return Scaffold(
      backgroundColor: AppColors.getBg(context),
      floatingActionButton: const FloatingOrganizerCopilotButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.getTextPrimary(context), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Organizer Hub',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Subscription & Settings',
            icon: Icon(Icons.settings_outlined,
                color: AppColors.getTextPrimary(context)),
            onPressed: () => context.push(AppRoutes.organizerSubscription),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          final packages = packagesAsync.valueOrNull ?? [];
          final services = servicesAsync.valueOrNull ?? [];
          final bookings = bookingsAsync.valueOrNull ?? [];
          final ledger = ledgerAsync.valueOrNull;

          final activePackages = packages.where((p) => p.isActive).length;
          final activeServices = services.where((s) => s.isActive).length;
          final pendingBookings =
              bookings.where((b) => b.status == BookingStatus.REQUESTED).length;
          final confirmedBookings =
              bookings.where((b) => b.status == BookingStatus.ACCEPTED).length;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(organizerProfileProvider);
              ref.invalidate(organizerPackagesProvider);
              ref.invalidate(organizerServicesProvider);
              ref.invalidate(bookingInboxProvider);
              ref.invalidate(payoutLedgerProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Business Summary Header Card ───────────────────────────
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              '${profile.plan.label.toUpperCase()} ACTIVE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'KYC VERIFIED',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        profile.businessName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.businessMode.title} • ${profile.city}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${profile.rating} (${profile.reviewCount} reviews)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '• 0% Commission',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Business Metrics Row ───────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context: context,
                        title: 'Revenue',
                        value: CurrencyFormatter.formatPaise(
                            ledger?.totalEarningsPaise ?? 0),
                        subtitle: 'This Month',
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: Colors.green,
                        onTap: () => context.push(AppRoutes.organizerEarnings),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricTile(
                        context: context,
                        title: pendingBookings > 0
                            ? 'Action Needed'
                            : 'All Handled',
                        value: '$pendingBookings Requests',
                        subtitle: '24h SLA Active',
                        icon: Icons.pending_actions_rounded,
                        iconColor: pendingBookings > 0
                            ? Colors.amber.shade800
                            : Colors.grey,
                        isAlert: pendingBookings > 0,
                        onTap: () => context.push(AppRoutes.organizerBookings),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricTile(
                        context: context,
                        title: 'Confirmed',
                        value: '$confirmedBookings Events',
                        subtitle: 'Upcoming Slots',
                        icon: Icons.event_available_outlined,
                        iconColor: AppColors.primary,
                        onTap: () => context.push(AppRoutes.organizerCalendar),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Catalog & Operations Menu ──────────────────────────────
                Text(
                  'Manage Catalog & Operations',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 12),

                _buildMenuItem(
                  context: context,
                  icon: Icons.inventory_2_outlined,
                  iconColor: Colors.indigo,
                  title: 'Packages Management',
                  subtitle:
                      '${packages.length} created • $activePackages active / ${profile.maxActivePackages} limit',
                  badgeText: activePackages >= profile.maxActivePackages
                      ? 'Cap Reached'
                      : null,
                  badgeColor: Colors.orange,
                  route: AppRoutes.organizerPackages,
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.design_services_outlined,
                  iconColor: Colors.teal,
                  title: 'Standalone Services',
                  subtitle:
                      '${services.length} created • $activeServices active / ${profile.maxActiveServices} limit',
                  badgeText: activeServices >= profile.maxActiveServices
                      ? 'Cap Reached'
                      : null,
                  badgeColor: Colors.orange,
                  route: AppRoutes.organizerServices,
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.assignment_outlined,
                  iconColor: Colors.deepOrange,
                  title: 'Booking Requests & SLA',
                  subtitle: 'Accept or reject client inquiries within 24 hours',
                  badgeText:
                      pendingBookings > 0 ? '$pendingBookings Pending' : null,
                  badgeColor: Colors.red,
                  route: AppRoutes.organizerBookings,
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.calendar_month_outlined,
                  iconColor: Colors.blue,
                  title: 'Availability Calendar',
                  subtitle: 'Block blackout dates and view confirmed schedules',
                  route: AppRoutes.organizerCalendar,
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: Colors.green,
                  title: 'Earnings & Bank Payouts',
                  subtitle: '0% platform commission ledger & bank settlements',
                  route: AppRoutes.organizerEarnings,
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.collections_outlined,
                  iconColor: Colors.purple,
                  title: 'Portfolio Showcase',
                  subtitle: 'Client-facing photo & 4K video past work gallery',
                  route: AppRoutes.organizerPortfolio,
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.workspace_premium_outlined,
                  iconColor: Colors.amber.shade900,
                  title: 'Subscription & Active Quotas',
                  subtitle:
                      'Current: ${profile.plan.label} • Upgrade plan & active caps',
                  route: AppRoutes.organizerSubscription,
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool isAlert = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alertBg = isDark ? const Color(0xFF2E1C00) : Colors.amber.shade50;
    final alertBorder = isDark ? Colors.amber.shade700 : Colors.amber.shade300;
    final alertTextColor =
        isDark ? Colors.amber.shade300 : Colors.amber.shade900;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isAlert ? alertBg : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isAlert ? alertBorder : AppColors.getBorder(context),
          ),
          boxShadow: AppColors.getCardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isAlert
                    ? alertTextColor
                    : AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isAlert
                    ? alertTextColor
                    : AppColors.getTextSecondary(context),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppColors.getTextMuted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String route,
    String? badgeText,
    Color badgeColor = Colors.red,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: AppColors.getCardShadow(context),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            ),
            if (badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.getTextSecondary(context),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Colors.grey),
        onTap: () => context.push(route),
      ),
    );
  }
}
