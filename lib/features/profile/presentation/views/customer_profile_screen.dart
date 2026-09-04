import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../organizer/domain/entities/organizer_entities.dart';
import '../../../organizer/presentation/providers/organizer_providers.dart';

class CustomerProfileScreen extends HookConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final activePortal = user?.activePortal ?? ActivePortal.CUSTOMER;
    final themeMode = ref.watch(themeModeProvider);

    final organizerProfileAsync = ref.watch(organizerProfileProvider);
    final organizerProfile = organizerProfileAsync.valueOrNull ?? OrganizerProfile.empty;

    void showStatusSimulatorSheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Organizer State Simulator 🛠️',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                'Simulate each state machine branch specified in the spec:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              const SizedBox(height: 12),
              _buildSimItem(
                context,
                title: '1. State: none (New User)',
                subtitle: 'Profile tile shows "Earn by listing services & packages"',
                color: Colors.blue,
                onTap: () {
                  ref.read(organizerProfileProvider.notifier).setKycStatusForTesting(
                        KycStatus.none,
                        isSetupComplete: false,
                      );
                  Navigator.pop(ctx);
                },
              ),
              _buildSimItem(
                context,
                title: '2. State: pending (Under Review ⏳)',
                subtitle: 'Profile tile shows "KYC Verification Under Review"',
                color: Colors.orange,
                onTap: () {
                  ref.read(organizerProfileProvider.notifier).setKycStatusForTesting(
                        KycStatus.pending,
                        isSetupComplete: false,
                      );
                  Navigator.pop(ctx);
                },
              ),
              _buildSimItem(
                context,
                title: '3. State: rejected (Action Needed ⚠️)',
                subtitle: 'Profile tile shows "KYC Action Required"',
                color: Colors.red,
                onTap: () {
                  ref.read(organizerProfileProvider.notifier).setKycStatusForTesting(
                        KycStatus.rejected,
                        rejectionReason:
                            'PAN card name does not match the GST certificate entity title.',
                        isSetupComplete: false,
                      );
                  Navigator.pop(ctx);
                },
              ),
              _buildSimItem(
                context,
                title: '4. State: approved & setup incomplete',
                subtitle: 'Opens 2-Step Onboarding Setup Wizard',
                color: Colors.amber.shade800,
                onTap: () {
                  ref.read(organizerProfileProvider.notifier).setKycStatusForTesting(
                        KycStatus.approved,
                        isSetupComplete: false,
                      );
                  Navigator.pop(ctx);
                },
              ),
              _buildSimItem(
                context,
                title: '5. State: approved & setup complete',
                subtitle: 'Direct entry to full Organizer Hub & Sub-modules',
                color: Colors.green,
                onTap: () {
                  ref.read(organizerProfileProvider.notifier).setKycStatusForTesting(
                        KycStatus.approved,
                        isSetupComplete: true,
                      );
                  Navigator.pop(ctx);
                },
              ),
              _buildSimItem(
                context,
                title: '6. State: suspended',
                subtitle: 'Opens Account Suspended Notice Screen',
                color: Colors.red.shade900,
                onTap: () {
                  ref.read(organizerProfileProvider.notifier).setKycStatusForTesting(
                        KycStatus.suspended,
                        rejectionReason:
                            'Account temporarily suspended due to repeated SLA expiration.',
                        isSetupComplete: true,
                      );
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getBg(context),
      body: CustomScrollView(
        slivers: [
          // ── Header Bar ───────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.getSurface(context),
            elevation: 0,
            scrolledUnderElevation: 0,
            floating: false,
            pinned: true,
            expandedHeight: 175,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.getSurface(context),
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.avatarGradient,
                      ),
                      child: Center(
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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
                            user?.name ?? 'TrueGather User',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? user?.phone ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              AppStatusBadge(
                                label: activePortal.name,
                                customColor: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              _HeaderThemeToggle(
                                currentMode: themeMode,
                                onModeChanged: (newMode) {
                                  ref
                                      .read(themeModeProvider.notifier)
                                      .setTheme(newMode);
                                },
                              ),
                            ],
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
                  // ── Organizer & Business Hub Entry Tile ─────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Business & Organizer Portal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.tune_rounded, size: 14),
                        label: Text(
                          'Test States',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11),
                        ),
                        onPressed: showStatusSimulatorSheet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // The Dynamic Organizer Entry Tile (Sections 1 & 6.1)
                  _buildOrganizerEntryTile(context, organizerProfile),

                  const SizedBox(height: 12),

                  // Host & Ticket Scanner Tile
                  _PortalSwitchTile(
                    title: 'Host & Ticket Scanner',
                    subtitle: 'Publish public events & check in attendees via QR',
                    icon: Icons.qr_code_scanner_rounded,
                    isSelected: activePortal == ActivePortal.HOST,
                    onTap: () {
                      ref
                          .read(authStateProvider.notifier)
                          .switchPortal(ActivePortal.HOST);
                      context.go(AppRoutes.hostDashboard);
                    },
                  ),

                  const SizedBox(height: 24),

                  // ── My Customer Account ──────────────────────────────────
                  Text(
                    'My Orders & Events',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _ActionTile(
                    title: 'My Bookings & Event Tickets',
                    icon: Icons.confirmation_number_outlined,
                    onTap: () => context.push(AppRoutes.bookings),
                  ),
                  const SizedBox(height: 8),

                  _ActionTile(
                    title: 'Followed Studios & Organizers',
                    icon: Icons.favorite_outline_rounded,
                    onTap: () => context.push(AppRoutes.following),
                  ),
                  const SizedBox(height: 8),

                  _ActionTile(
                    title: 'My Shopping Cart',
                    icon: Icons.shopping_bag_outlined,
                    onTap: () => context.push(AppRoutes.cart),
                  ),

                  const SizedBox(height: 24),

                  // ── Preferences & Support ─────────────────────────────────
                  Text(
                    'Settings & Preferences',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _ActionTile(
                    title: 'Notifications & Alerts',
                    icon: Icons.notifications_none_rounded,
                    onTap: () => context.push(AppRoutes.notifications),
                  ),
                  const SizedBox(height: 8),

                  _ActionTile(
                    title: 'AI Event Planner Assistant',
                    icon: Icons.auto_awesome_outlined,
                    onTap: () => context.push(AppRoutes.chatbot),
                  ),
                  const SizedBox(height: 8),

                  _ActionTile(
                    title: 'Help Center & Support',
                    icon: Icons.help_outline_rounded,
                    onTap: () {
                      AppSnackbar.show(
                        context,
                        message: 'TrueGather 24/7 Support Desk is active.',
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

  // ── Dynamic Organizer Entry Tile (Specification Sections 1 & 6.1) ─────────
  Widget _buildOrganizerEntryTile(
      BuildContext context, OrganizerProfile profile) {
    String subtitle;
    String badgeText;
    Color badgeColor;
    IconData icon = Icons.storefront_outlined;

    switch (profile.kycStatus) {
      case KycStatus.none:
        subtitle = "Earn by listing services & packages";
        badgeText = "Start Selling";
        badgeColor = Colors.blue;
        break;
      case KycStatus.pending:
      case KycStatus.underReview:
        subtitle = "KYC Verification Under Review ⏳";
        badgeText = "In Review";
        badgeColor = Colors.orange;
        break;
      case KycStatus.rejected:
        subtitle = "KYC Action Required ⚠️";
        badgeText = "Action Needed";
        badgeColor = Colors.red;
        break;
      case KycStatus.approved:
        if (!profile.isSetupComplete) {
          subtitle = "Setup Wizard Required — Choose Mode";
          badgeText = "Complete Setup";
          badgeColor = Colors.amber.shade800;
        } else {
          subtitle = "Dashboard, Bookings, Packages & Earnings";
          badgeText = "Active Hub";
          badgeColor = Colors.green;
        }
        icon = Icons.dashboard_outlined;
        break;
      case KycStatus.suspended:
        subtitle = "Account Suspended — Contact Support";
        badgeText = "Suspended";
        badgeColor = Colors.red;
        break;
    }

    return GestureDetector(
      onTap: () => _handleOrganizerNavigation(context, profile),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: badgeColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Organizer Hub",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      color: badgeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.getTextSecondary(context), size: 22),
          ],
        ),
      ),
    );
  }

  // ── Navigation Router (Section 6.1) ───────────────────────────────────────
  void _handleOrganizerNavigation(
      BuildContext context, OrganizerProfile profile) {
    switch (profile.kycStatus) {
      case KycStatus.none:
        context.push(AppRoutes.organizerBecome);
        break;
      case KycStatus.pending:
      case KycStatus.underReview:
        context.push(AppRoutes.organizerKycPending);
        break;
      case KycStatus.rejected:
        context.push(AppRoutes.organizerKycResubmit);
        break;
      case KycStatus.approved:
        if (!profile.isSetupComplete) {
          context.push(AppRoutes.organizerSetupWizard);
        } else {
          context.push(AppRoutes.organizerHub);
        }
        break;
      case KycStatus.suspended:
        context.push(AppRoutes.organizerSuspended);
        break;
    }
  }

  Widget _buildSimItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.getBorder(context)),
          boxShadow: AppColors.getCardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.getTextSecondary(context), size: 20),
          ],
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.getBorder(context)),
          boxShadow: AppColors.getCardShadow(context),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.getTextSecondary(context), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.getTextSecondary(context), size: 18),
          ],
        ),
      ),
    );
  }
}

class _HeaderThemeToggle extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onModeChanged;

  const _HeaderThemeToggle({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = currentMode == ThemeMode.dark;

    return GestureDetector(
      onTap: () {
        onModeChanged(isDark ? ThemeMode.light : ThemeMode.dark);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFD1D5DB),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF2E2E2E) : Colors.transparent,
              ),
              child: Icon(
                Icons.dark_mode_rounded,
                size: 13,
                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !isDark ? Colors.white : Colors.transparent,
              ),
              child: Icon(
                Icons.light_mode_rounded,
                size: 13,
                color: !isDark ? const Color(0xFFF59E0B) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
