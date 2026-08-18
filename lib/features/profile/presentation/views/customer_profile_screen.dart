import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class CustomerProfileScreen extends HookConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final activePortal = user?.activePortal ?? ActivePortal.CUSTOMER;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: CustomScrollView(
        slivers: [
          // ── Header Bar ───────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.lightSurface,
            elevation: 0,
            scrolledUnderElevation: 0,
            floating: false,
            pinned: true,
            expandedHeight: 180,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.lightSurface,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primary, width: 2.5),
                      ),
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user?.name ?? 'EventSphere User',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.email ?? user?.phone ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AppStatusBadge(
                            label: activePortal.name,
                            status: BadgeStatus.accepted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Profile Body ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Portal Switcher ──────────────────────────────────────
                  Text(
                    'Workspace Mode',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.lightBorder),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      children: [
                        _PortalSwitchTile(
                          title: 'Customer Experience',
                          subtitle: 'Book events, packages, and manage passes',
                          icon: Icons.person_outline_rounded,
                          isSelected:
                              activePortal == ActivePortal.CUSTOMER,
                          onTap: () {
                            ref
                                .read(authStateProvider.notifier)
                                .switchPortal(ActivePortal.CUSTOMER);
                            context.go(AppRoutes.home);
                          },
                        ),
                        const Divider(height: 1, color: AppColors.lightBorder),
                        _PortalSwitchTile(
                          title: 'Organizer & Vendor Hub',
                          subtitle:
                              'Manage inquiries, catalog, calendar & payouts',
                          icon: Icons.business_center_outlined,
                          isSelected:
                              activePortal == ActivePortal.ORGANIZER,
                          onTap: () {
                            ref
                                .read(authStateProvider.notifier)
                                .switchPortal(ActivePortal.ORGANIZER);
                            context.go(AppRoutes.organizerDashboard);
                          },
                        ),
                        const Divider(height: 1, color: AppColors.lightBorder),
                        _PortalSwitchTile(
                          title: 'Host & Ticket Scanner',
                          subtitle:
                              'Publish public events, check in attendees via QR',
                          icon: Icons.qr_code_scanner_rounded,
                          isSelected: activePortal == ActivePortal.HOST,
                          onTap: () {
                            ref
                                .read(authStateProvider.notifier)
                                .switchPortal(ActivePortal.HOST);
                            context.go(AppRoutes.hostDashboard);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Account Links ────────────────────────────────────────
                  Text(
                    'Account & Preferences',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _ActionTile(
                    title: 'Business KYC Verification',
                    icon: Icons.verified_user_outlined,
                    onTap: () => context.push(AppRoutes.kycRegistration),
                  ),
                  const SizedBox(height: 10),

                  _ActionTile(
                    title: 'Organizer Subscription Plan',
                    icon: Icons.rocket_launch_outlined,
                    onTap: () => context.push(AppRoutes.onboardingWizard),
                  ),
                  const SizedBox(height: 10),

                  _ActionTile(
                    title: 'Notifications & Alerts',
                    icon: Icons.notifications_none_rounded,
                    onTap: () {
                      AppSnackbar.show(
                        context,
                        message: 'Notification settings updated.',
                        type: SnackbarType.info,
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _ActionTile(
                    title: 'Help Center & Support',
                    icon: Icons.help_outline_rounded,
                    onTap: () {
                      AppSnackbar.show(
                        context,
                        message: 'Support chat is available 24/7.',
                        type: SnackbarType.info,
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  AppSecondaryButton(
                    text: 'Log Out',
                    icon: Icons.logout_rounded,
                    onPressed: () async {
                      await ref.read(authStateProvider.notifier).logout();
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PortalSwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.lightCardAlt,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.primary, size: 20)
          : const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.textMuted),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.icon,
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
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
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
