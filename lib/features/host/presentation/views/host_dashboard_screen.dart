import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_router.dart';
import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_network_image.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/host_entities.dart';
import '../providers/host_providers.dart';

class HostDashboardScreen extends HookConsumerWidget {
  const HostDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(hostedEventsProvider);
    final filterTag = useState<String>('ALL');

    return Scaffold(
      backgroundColor: AppColors.getBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Host & Ticketing Studio',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            Text(
              'Manage your events, ticket tiers & entry scanning',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.getTextSecondary(context),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Create Event',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        onPressed: () => context.push(AppRoutes.hostCreateEvent),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => AppErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(hostedEventsProvider),
        ),
        data: (events) {
          // Dashboard Summary Calculations
          final totalEvents = events.length;
          final totalRegistrations =
              events.fold<int>(0, (sum, e) => sum + e.totalRegistrations);
          final totalRevenuePaise =
              events.fold<int>(0, (sum, e) => sum + e.revenueInPaise);
          final pendingApprovals =
              events.fold<int>(0, (sum, e) => sum + e.pendingApprovalsCount);

          // Filter events
          final filteredEvents = switch (filterTag.value) {
            'PUBLISHED' => events.where((e) => e.isPublished || e.isLive).toList(),
            'DRAFTS' => events.where((e) => e.isDraft).toList(),
            'COMPLETED' => events.where((e) => e.isCompleted).toList(),
            _ => events,
          };

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(hostedEventsProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 4-Card Summary Analytics Grid ─────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          title: 'Hosted Events',
                          value: '$totalEvents',
                          subtitle: 'Active & drafts',
                          icon: Icons.festival_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'Total Passes',
                          value: '$totalRegistrations',
                          subtitle: 'Registered attendees',
                          icon: Icons.confirmation_number_outlined,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          title: 'Ticket Revenue',
                          value: CurrencyFormatter.formatPaise(totalRevenuePaise),
                          subtitle: 'Gross ticket sales',
                          icon: Icons.currency_rupee_rounded,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'Pending Approvals',
                          value: '$pendingApprovals',
                          subtitle: pendingApprovals > 0 ? 'Requires action' : 'Queue clear',
                          icon: Icons.hourglass_top_rounded,
                          color: pendingApprovals > 0
                              ? const Color(0xFFF59E0B)
                              : AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Create Event Promo Banner ─────────────────────────────
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.hostCreateEvent),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Launch 5-Step Event Studio',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Create physical or virtual Google Meet events',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Filter Tabs & Heading ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Hosted Events',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.getTextPrimary(context),
                        ),
                      ),
                      Text(
                        '${filteredEvents.length} Total',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All Events',
                          isSelected: filterTag.value == 'ALL',
                          onTap: () => filterTag.value = 'ALL',
                        ),
                        _FilterChip(
                          label: 'Published',
                          isSelected: filterTag.value == 'PUBLISHED',
                          onTap: () => filterTag.value = 'PUBLISHED',
                        ),
                        _FilterChip(
                          label: 'Drafts',
                          isSelected: filterTag.value == 'DRAFTS',
                          onTap: () => filterTag.value = 'DRAFTS',
                        ),
                        _FilterChip(
                          label: 'Completed',
                          isSelected: filterTag.value == 'COMPLETED',
                          onTap: () => filterTag.value = 'COMPLETED',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Hosted Event Cards List ───────────────────────────────
                  if (filteredEvents.isEmpty)
                    const AppEmptyView(
                      icon: Icons.event_busy_rounded,
                      title: 'No Events in this Filter',
                      subtitle: 'Create a new event using the 5-Step Studio to get started.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = filteredEvents[index];
                        return _HostEventCard(event: item);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Metric Card Sub-Widget ────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: AppColors.getCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: AppColors.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Chip Sub-Widget ────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.getBorder(context),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.getTextPrimary(context),
          ),
        ),
      ),
    );
  }
}

// ── Host Event Card ───────────────────────────────────────────────────────────

class _HostEventCard extends HookConsumerWidget {
  final HostEventItem event;

  const _HostEventCard({required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('EEE, d MMM yyyy • hh:mm a');

    return GestureDetector(
      onTap: () => context.push('/host/manage/${event.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.getBorder(context)),
          boxShadow: AppColors.getCardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Thumbnail & Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 16 / 8.5,
                    child: AppNetworkImage(
                      url: event.coverImageUrl,
                      categoryHint: event.category?.name ?? 'Event',
                      titleHint: event.title,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      _StatusBadge(status: event.status),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: event.isOnline
                              ? const Color(0xFF3B82F6)
                              : Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              event.isOnline ? Icons.videocam_rounded : Icons.location_on_rounded,
                              color: Colors.white,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.isOnline ? 'VIRTUAL' : 'IN-PERSON',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (event.pendingApprovalsCount > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${event.pendingApprovalsCount} PENDING',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.getTextPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.getTextSecondary(context)),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(event.startDatetime),
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.getTextSecondary(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Icon(
                        event.isOnline ? Icons.videocam_rounded : Icons.location_on_rounded,
                        size: 14,
                        color: AppColors.getTextSecondary(context),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.isOnline ? (event.meetingUrl ?? 'Google Meet Stream') : event.venue,
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.getTextSecondary(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Metrics Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.getCardAlt(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Passes: ${event.totalRegistrations}/${event.maxCapacity}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        Text(
                          'Revenue: ${CurrencyFormatter.formatPaise(event.revenueInPaise)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(color: AppColors.getBorder(context)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.settings_outlined, size: 16),
                          label: Text(
                            'Manage Hub',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () => context.push('/host/manage/${event.id}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(color: AppColors.getBorder(context)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                          label: Text(
                            'Scanner',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          onPressed: () => context.push('/host/scanner/${event.id}'),
                        ),
                      ),
                      if (event.isDraft) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              'Publish',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                            onPressed: () async {
                              await ref.read(hostedEventsProvider.notifier).publishEvent(event.id);
                              if (context.mounted) {
                                AppSnackbar.show(context, message: 'Event published live!', type: SnackbarType.success);
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        bg = const Color(0xFF10B981);
        fg = Colors.white;
        label = 'PUBLISHED';
        break;
      case 'LIVE':
        bg = const Color(0xFF3B82F6);
        fg = Colors.white;
        label = 'LIVE NOW';
        break;
      case 'COMPLETED':
        bg = const Color(0xFF8B5CF6);
        fg = Colors.white;
        label = 'COMPLETED';
        break;
      case 'PENDING_APPROVAL':
        bg = const Color(0xFFF59E0B);
        fg = Colors.white;
        label = 'UNDER REVIEW';
        break;
      default:
        bg = Colors.grey.shade700;
        fg = Colors.white;
        label = 'DRAFT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}
