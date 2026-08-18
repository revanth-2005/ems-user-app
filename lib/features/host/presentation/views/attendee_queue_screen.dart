import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/host_providers.dart';

class AttendeeQueueScreen extends HookConsumerWidget {
  final String eventId;

  const AttendeeQueueScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendeesAsync = ref.watch(attendeesQueueProvider(eventId));

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Attendee Queue Manifest',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: attendeesAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => AppErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(attendeesQueueProvider(eventId)),
        ),
        data: (attendees) {
          if (attendees.isEmpty) {
            return const AppEmptyView(
              icon: Icons.people_outline_rounded,
              title: 'No Registered Attendees',
              subtitle: 'Registered ticket holders will be listed here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: attendees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final att = attendees[index];
              return Container(
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
                        color: att.isCheckedIn
                            ? AppColors.statusCompleted.withValues(alpha: 0.12)
                            : AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        att.isCheckedIn
                            ? Icons.check_circle_rounded
                            : Icons.person_outline_rounded,
                        color: att.isCheckedIn
                            ? AppColors.statusCompleted
                            : AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            att.attendeeName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            att.ticketType,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!att.isCheckedIn)
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(hostRepositoryProvider)
                              .manualCheckIn(eventId, att.id);
                          ref.invalidate(attendeesQueueProvider(eventId));
                          if (context.mounted) {
                            AppSnackbar.show(
                              context,
                              message: 'Manual check-in confirmed!',
                              type: SnackbarType.success,
                            );
                          }
                        },
                        child: Text(
                          'Check In',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else
                      AppStatusBadge(
                        label: 'Admitted',
                        status: BadgeStatus.completed,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
