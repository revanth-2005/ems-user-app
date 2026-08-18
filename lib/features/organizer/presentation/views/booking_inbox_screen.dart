import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../bookings/domain/entities/booking_entities.dart';
import '../providers/organizer_providers.dart';

class BookingInboxScreen extends HookConsumerWidget {
  const BookingInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(bookingInboxProvider);

    void showRescheduleDialog(VendorBooking booking) {
      DateTime selectedDate = booking.eventDate.add(const Duration(days: 1));
      final noteController = TextEditingController();

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.lightSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Propose Reschedule',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a new proposed date for this event.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightCardAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            DateFormatter.formatDate(selectedDate),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      hintText: 'Reason for rescheduling…',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      filled: true,
                      fillColor: AppColors.lightCardAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.lightBorder),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel',
                      style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary)),
                ),
                AppPrimaryButton(
                  text: 'Send Proposal',
                  onPressed: () {
                    ref.read(bookingInboxProvider.notifier).proposeReschedule(
                          booking.id,
                          selectedDate,
                          noteController.text.trim(),
                        );
                    Navigator.pop(ctx);
                    AppSnackbar.show(
                      context,
                      message: 'Reschedule proposal sent to client.',
                      type: SnackbarType.info,
                    );
                  },
                ),
              ],
            );
          },
        ),
      );
    }

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
          'Booking Inbox & SLA',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: inboxAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => AppErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(bookingInboxProvider),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const AppEmptyView(
              icon: Icons.inbox_rounded,
              title: 'No Pending Bookings',
              subtitle: 'New booking requests from clients will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final b = bookings[index];
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.lightBorder),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentRose.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: 12, color: AppColors.accentRose),
                              const SizedBox(width: 4),
                              Text(
                                DateFormatter.formatSlaRemaining(b.slaDeadline),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentRose,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppStatusBadge(
                          label: b.status.name,
                          status: b.status == BookingStatus.ACCEPTED
                              ? BadgeStatus.accepted
                              : BadgeStatus.requested,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      b.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Client: ${b.customerName ?? "Guest"} • ${DateFormatter.formatDate(b.eventDate)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Agreed Price: ${CurrencyFormatter.formatPaise(b.agreedPriceInPaise)} (Deposit: ${CurrencyFormatter.formatPaise(b.depositPaidPaise)})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    if (b.status == BookingStatus.REQUESTED) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppPrimaryButton(
                              text: 'Accept',
                              onPressed: () {
                                ref
                                    .read(bookingInboxProvider.notifier)
                                    .acceptBooking(b.id);
                                AppSnackbar.show(
                                  context,
                                  message: 'Booking accepted!',
                                  type: SnackbarType.success,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppSecondaryButton(
                              text: 'Reschedule',
                              onPressed: () => showRescheduleDialog(b),
                            ),
                          ),
                        ],
                      ),
                    ],
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
