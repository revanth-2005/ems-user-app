import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationNotifierProvider);
    final notifier = ref.read(notificationNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
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
          'Notifications',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        actions: [
          if (state.notifications.isNotEmpty && state.unreadCount > 0)
            TextButton.icon(
              onPressed: () => notifier.markAllAsRead(),
              icon: const Icon(Icons.done_all_rounded,
                  size: 16, color: AppColors.primary),
              label: Text(
                'Mark all read',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.fetchNotifications(refresh: true),
        color: AppColors.primary,
        child: state.isLoading && state.notifications.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : state.notifications.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    itemCount: state.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = state.notifications[index];
                      return _buildNotificationCard(
                          context, item, notifier, isDark);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'All caught up!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You will be notified about booking updates, event alerts, and new followers here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.getTextSecondary(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context,
      AppNotificationEntity item, NotificationNotifier notifier, bool isDark) {
    final type = item.data['type']?.toString().toUpperCase() ?? '';
    final iconData = _getIconForType(type);
    final iconColor = _getColorForType(type);

    return InkWell(
      onTap: () {
        if (!item.isRead) {
          notifier.markAsRead(item.id);
        }
        _handleDeepLink(context, item);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead
              ? AppColors.getSurface(context)
              : (isDark
                  ? const Color(0xFF1B1B26)
                  : const Color(0xFFFFF1F2)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.isRead
                ? AppColors.getBorder(context)
                : AppColors.primary.withValues(alpha: 0.35),
            width: item.isRead ? 1 : 1.5,
          ),
          boxShadow: AppColors.getCardShadow(context),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: item.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(context),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormatter.formatRelativeTime(item.createdAt),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextMuted(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'NEW_EVENT':
        return Icons.event_rounded;
      case 'BOOKING_CREATED':
      case 'BOOKING_CONFIRMED':
        return Icons.confirmation_number_rounded;
      case 'EVENT_REGISTRATION':
        return Icons.how_to_reg_rounded;
      case 'REGISTRATION_APPROVED':
        return Icons.verified_rounded;
      case 'NEW_FOLLOWER':
        return Icons.person_add_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'NEW_EVENT':
        return const Color(0xFF3B82F6);
      case 'BOOKING_CREATED':
      case 'BOOKING_CONFIRMED':
      case 'REGISTRATION_APPROVED':
        return AppColors.accentEmerald;
      case 'EVENT_REGISTRATION':
        return const Color(0xFFF59E0B);
      case 'NEW_FOLLOWER':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.primary;
    }
  }

  void _handleDeepLink(BuildContext context, AppNotificationEntity item) {
    final type = item.data['type']?.toString().toUpperCase() ?? '';
    final eventId = item.data['eventId']?.toString();

    if (type == 'NEW_EVENT' && eventId != null && eventId.isNotEmpty) {
      context.push('/detail/event/$eventId');
    } else if (type == 'EVENT_REGISTRATION' && eventId != null && eventId.isNotEmpty) {
      context.push('/host/attendees/$eventId');
    } else if (type == 'REGISTRATION_APPROVED') {
      context.push(AppRoutes.bookings);
    } else if (type == 'BOOKING_CREATED' || type == 'BOOKING_CONFIRMED') {
      context.push(AppRoutes.bookings);
    } else if (type == 'NEW_FOLLOWER') {
      context.push(AppRoutes.profile);
    }
  }
}
