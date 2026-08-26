import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class CustomerProfileScreen extends HookConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final activePortal = user?.activePortal ?? ActivePortal.CUSTOMER;
    final themeMode = ref.watch(themeModeProvider);

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
            expandedHeight: 180,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.getSurface(context),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.getBorder(context), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.getCardAlt(context),
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextPrimary(context),
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
                              color: AppColors.getTextPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 3),
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
                              const SizedBox(width: 10),
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
                  // ── Portal Switcher ──────────────────────────────────────
                  Text(
                    'Workspace Mode',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.getBorder(context)),
                      boxShadow: AppColors.getCardShadow(context),
                    ),
                    child: Column(
                      children: [
                        // _PortalSwitchTile(
                        //   title: 'Customer Experience',
                        //   subtitle: 'Book events, packages, and manage passes',
                        //   icon: Icons.person_rounded,
                        //   isSelected:
                        //       activePortal == ActivePortal.CUSTOMER,
                        //   onTap: () {
                        //     ref
                        //         .read(authStateProvider.notifier)
                        //         .switchPortal(ActivePortal.CUSTOMER);
                        //     context.go(AppRoutes.home);
                        //   },
                        // ),
                        // Divider(height: 1, color: AppColors.getBorder(context)),
                        // _PortalSwitchTile(
                        //   title: 'Organizer & Vendor Hub',
                        //   subtitle:
                        //       'Manage inquiries, catalog, calendar & payouts',
                        //   icon: Icons.business_center_rounded,
                        //   isSelected:
                        //       activePortal == ActivePortal.ORGANIZER,
                        //   onTap: () {
                        //     ref
                        //         .read(authStateProvider.notifier)
                        //         .switchPortal(ActivePortal.ORGANIZER);
                        //     context.go(AppRoutes.organizerDashboard);
                        //   },
                        // ),
                        // Divider(height: 1, color: AppColors.getBorder(context)),
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
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _ActionTile(
                    title: 'Followed Studios & Organizers',
                    icon: Icons.favorite_rounded,
                    onTap: () => context.push(AppRoutes.following),
                  ),
                  const SizedBox(height: 10),

                  _ActionTile(
                    title: 'Business KYC Verification',
                    icon: Icons.verified_user_rounded,
                    onTap: () => context.push(AppRoutes.kycRegistration),
                  ),
                  const SizedBox(height: 10),

                  // _ActionTile(
                  //   title: 'Organizer Subscription Plan',
                  //   icon: Icons.rocket_launch_rounded,
                  //   onTap: () => context.push(AppRoutes.onboardingWizard),
                  // ),
                  // const SizedBox(height: 10),

                  _ActionTile(
                    title: 'Notifications & Alerts',
                    icon: Icons.notifications_rounded,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.getSurface(context),
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (ctx) {
                          return FutureBuilder<String?>(
                            future: NotificationService().getOrFetchToken(),
                            builder: (context, snapshot) {
                              final token = snapshot.data;
                              final isLoading = snapshot.connectionState ==
                                  ConnectionState.waiting;

                              return Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.notifications_active_rounded,
                                            color: AppColors.primary,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Push Notifications',
                                                style: GoogleFonts
                                                    .plusJakartaSans(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color:
                                                      AppColors.getTextPrimary(
                                                          context),
                                                ),
                                              ),
                                              Text(
                                                token != null
                                                    ? 'Firebase FCM Active'
                                                    : (isLoading
                                                        ? 'Fetching Token...'
                                                        : 'FCM Ready'),
                                                style: GoogleFonts
                                                    .plusJakartaSans(
                                                  fontSize: 12,
                                                  color: token != null
                                                      ? const Color(0xFF10B981)
                                                      : AppColors
                                                          .getTextSecondary(
                                                              context),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      'FCM Device Registration Token:',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.getCardAlt(context),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color:
                                                AppColors.getBorder(context)),
                                      ),
                                      child: isLoading
                                          ? const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : SelectableText(
                                              token ??
                                                  'Could not retrieve token. Check internet / Google Play Services.',
                                              style: GoogleFonts.firaCode(
                                                fontSize: 11,
                                                color: AppColors.getTextPrimary(
                                                    context),
                                              ),
                                              maxLines: 4,
                                            ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        if (token != null) ...[
                                          Expanded(
                                            child: AppPrimaryButton(
                                              text: 'Copy Token',
                                              onPressed: () {
                                                Clipboard.setData(
                                                    ClipboardData(text: token));
                                                context.pop();
                                                AppSnackbar.show(
                                                  context,
                                                  message:
                                                      'FCM Device Token copied to clipboard!',
                                                  type: SnackbarType.success,
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                        ],
                                        Expanded(
                                          child: AppSecondaryButton(
                                            text: 'Send Test Alert',
                                            onPressed: () {
                                              NotificationService()
                                                  .showTestNotification();
                                              context.pop();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  // const SizedBox(height: 10),

                  // _ActionTile(
                  //   title: 'Help Center & Support',
                  //   icon: Icons.help_rounded,
                  //   onTap: () {
                  //     AppSnackbar.show(
                  //       context,
                  //       message: 'Support chat is available 24/7.',
                  //       type: SnackbarType.info,
                  //     );
                  //   },
                  // ),

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dark Mode Circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF2E2E2E) : Colors.transparent,
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.dark_mode_rounded,
                size: 15,
                color: isDark
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 4),
            // Light Mode Circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: !isDark ? Colors.white : Colors.transparent,
                boxShadow: !isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.light_mode_rounded,
                size: 15,
                color: !isDark
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
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
    final isDark = AppColors.isDark(context);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB))
              : AppColors.getCardAlt(context),
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: isDark ? const Color(0xFF404040) : const Color(0xFFD1D5DB),
                  width: 1,
                )
              : null,
        ),
        child: Icon(
          icon,
          color: isSelected
              ? AppColors.getTextPrimary(context)
              : AppColors.getTextSecondary(context),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: AppColors.getTextPrimary(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          color: AppColors.getTextSecondary(context),
        ),
      ),
      trailing: isSelected
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF262626)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Active',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            )
          : Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.getTextMuted(context)),
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
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.getBorder(context)),
          boxShadow: AppColors.getCardShadow(context),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.getTextSecondary(context), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.getTextMuted(context)),
          ],
        ),
      ),
    );
  }
}
