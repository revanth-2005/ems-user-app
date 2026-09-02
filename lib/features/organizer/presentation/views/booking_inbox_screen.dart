import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../bookings/domain/entities/booking_entities.dart';
import '../providers/organizer_providers.dart';

class BookingInboxScreen extends HookConsumerWidget {
  const BookingInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = useState(0); // 0: Pending, 1: Confirmed, 2: Completed
    final inboxAsync = ref.watch(bookingInboxProvider);

    void showRejectReasonModal(VendorBooking booking) {
      final reasons = [
        'Date unavailable / already booked offline',
        'Event venue is outside operational service area',
        'Required custom equipment / artist unavailable',
        'Capacity requirements exceed staffing limit',
      ];
      int selectedIdx = 0;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Decline Booking Request',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.red.shade900,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    'Select a reason for declining. The client deposit will be auto-refunded immediately.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...reasons.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final reason = entry.value;
                    final isSel = selectedIdx == idx;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedIdx = idx),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSel
                              ? Colors.red.shade50
                              : AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSel
                                ? Colors.red.shade300
                                : AppColors.getBorder(context),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSel
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 18,
                              color: isSel ? Colors.red : Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                reason,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight:
                                      isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel
                                      ? Colors.red.shade900
                                      : AppColors.getTextPrimary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      final chosenReason = reasons[selectedIdx];
                      ref
                          .read(bookingInboxProvider.notifier)
                          .rejectBooking(booking.id, reason: chosenReason);
                      Navigator.pop(ctx);
                      AppSnackbar.show(
                        context,
                        message: 'Booking declined. Reason sent to client.',
                        type: SnackbarType.info,
                      );
                    },
                    child: const Text('Confirm Decline & Refund Client'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getBg(context),
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
          'Booking Inquiries & SLA',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: inboxAsync.when(
        loading: () => const Center(child: AppLoader()),
        error: (e, _) => AppErrorView(message: e.toString()),
        data: (allBookings) {
          final pending = allBookings
              .where((b) => b.status == BookingStatus.REQUESTED)
              .toList();
          final confirmed = allBookings
              .where((b) => b.status == BookingStatus.ACCEPTED)
              .toList();
          final completed = allBookings
              .where((b) =>
                  b.status == BookingStatus.COMPLETED ||
                  b.status == BookingStatus.REJECTED)
              .toList();

          final currentList = selectedTab.value == 0
              ? pending
              : selectedTab.value == 1
                  ? confirmed
                  : completed;

          return Column(
            children: [
              // ── 24h SLA Notice Banner ────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        color: Colors.amber.shade900, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '24-Hour SLA Response Engine',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          Text(
                            'Respond to incoming inquiries within 24 hours to maintain high placement ranking and prevent auto-expiry.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.amber.shade900.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Segmented Navigation Tabs ─────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTab(
                        'Requests (${pending.length})', 0, selectedTab, pending.isNotEmpty),
                    _buildTab('Confirmed (${confirmed.length})', 1, selectedTab),
                    _buildTab('History (${completed.length})', 2, selectedTab),
                  ],
                ),
              ),

              // ── Booking List ──────────────────────────────────────────────
              Expanded(
                child: currentList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              selectedTab.value == 0
                                  ? 'No pending inquiries at the moment.'
                                  : selectedTab.value == 1
                                      ? 'No confirmed upcoming bookings yet.'
                                      : 'No past booking history found.',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: currentList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final booking = currentList[index];
                          return _buildBookingCard(
                            context: context,
                            booking: booking,
                            onAccept: () {
                              ref
                                  .read(bookingInboxProvider.notifier)
                                  .acceptBooking(booking.id);
                              AppSnackbar.show(
                                context,
                                message:
                                    'Booking accepted! Slot blocked in your availability calendar.',
                                type: SnackbarType.success,
                              );
                            },
                            onReject: () => showRejectReasonModal(booking),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(
      String label, int index, ValueNotifier<int> selectedTab, [bool hasBadge = false]) {
    final isSelected = selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => selectedTab.value = index,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4)
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.primary : Colors.grey.shade700,
                  ),
                ),
                if (hasBadge && !isSelected) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard({
    required BuildContext context,
    required VendorBooking booking,
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    final isPending = booking.status == BookingStatus.REQUESTED;
    final isAccepted = booking.status == BookingStatus.ACCEPTED;

    // SLA Remaining calculate
    final now = DateTime.now();
    final remainingDiff = booking.slaDeadline.difference(now);
    final hoursLeft = remainingDiff.inHours.clamp(0, 24);
    final minutesLeft = (remainingDiff.inMinutes % 60).clamp(0, 59);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending
              ? Colors.amber.shade300
              : AppColors.getBorder(context),
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: AppColors.getCardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPending
                      ? Colors.amber.shade100
                      : isAccepted
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPending
                      ? 'PENDING REVIEW'
                      : isAccepted
                          ? 'CONFIRMED'
                          : booking.status.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isPending
                        ? Colors.amber.shade900
                        : isAccepted
                            ? Colors.green.shade800
                            : Colors.grey.shade700,
                  ),
                ),
              ),
              if (isPending)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_sharp, size: 12, color: Colors.red.shade800),
                      const SizedBox(width: 4),
                      Text(
                        '⏰ ${hoursLeft}h ${minutesLeft}m left',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            booking.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Client: ${booking.customerName}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 10),

          // Details Matrix
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCardDetail('Event Date',
                    DateFormatter.formatDate(booking.eventDate)),
                _buildCardDetail('Total Amount',
                    CurrencyFormatter.formatPaise(booking.agreedPriceInPaise)),
                _buildCardDetail('Deposit Paid',
                    CurrencyFormatter.formatPaise(booking.depositPaidPaise)),
              ],
            ),
          ),

          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade800,
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onReject,
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onAccept,
                    child: const Text('Accept Booking'),
                  ),
                ),
              ],
            ),
          ],

          if (isAccepted) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.phone_outlined, size: 16),
                    label: Text(booking.customerPhone ?? 'Call Client'),
                    onPressed: () {
                      AppSnackbar.show(
                        context,
                        message: 'Calling ${booking.customerPhone}…',
                        type: SnackbarType.info,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Client Chat'),
                    onPressed: () {
                      AppSnackbar.show(
                        context,
                        message: 'Direct chat opening…',
                        type: SnackbarType.info,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardDetail(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
