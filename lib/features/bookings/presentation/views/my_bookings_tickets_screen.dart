import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/common_widgets/app_status_badge.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/booking_entities.dart';
import '../providers/booking_providers.dart';

enum BookingViewTab { BOOKINGS, TICKETS }

class MyBookingsTicketsScreen extends HookConsumerWidget {
  const MyBookingsTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = useState(BookingViewTab.BOOKINGS);
    final bookingsAsync = ref.watch(myBookingsProvider);
    final ticketsAsync = ref.watch(myTicketsProvider);

    final bookingsCount = bookingsAsync.valueOrNull?.length ?? 0;
    final ticketsCount = ticketsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'My Bookings & Passes',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lightCardAlt,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.lightBorder),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _TabPill(
                      label: 'Vendors ($bookingsCount)',
                      isSelected: activeTab.value == BookingViewTab.BOOKINGS,
                      onTap: () => activeTab.value = BookingViewTab.BOOKINGS,
                    ),
                  ),
                  Expanded(
                    child: _TabPill(
                      label: 'Tickets ($ticketsCount)',
                      isSelected: activeTab.value == BookingViewTab.TICKETS,
                      onTap: () => activeTab.value = BookingViewTab.TICKETS,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: activeTab.value == BookingViewTab.BOOKINGS
          ? bookingsAsync.when(
              loading: () => const Center(child: AppLoader()),
              error: (e, _) => AppErrorView(
                message: e.toString(),
                onRetry: () => ref.refresh(myBookingsProvider),
              ),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return const AppEmptyView(
                    icon: Icons.confirmation_number_outlined,
                    title: 'No Vendor Bookings',
                    subtitle: 'Explore curated event packages and book your next celebration.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final b = bookings[index];
                    return _VendorBookingCard(booking: b);
                  },
                );
              },
            )
          : ticketsAsync.when(
              loading: () => const Center(child: AppLoader()),
              error: (e, _) => AppErrorView(
                message: e.toString(),
                onRetry: () => ref.refresh(myTicketsProvider),
              ),
              data: (tickets) {
                if (tickets.isEmpty) {
                  return const AppEmptyView(
                    icon: Icons.qr_code_2_rounded,
                    title: 'No Active Event Passes',
                    subtitle: 'Browse live events and register for workshops or concerts.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final t = tickets[index];
                    return _TicketPassCard(ticket: t);
                  },
                );
              },
            ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          boxShadow: isSelected ? AppColors.cardShadow : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _VendorBookingCard extends ConsumerWidget {
  final VendorBooking booking;

  const _VendorBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Text(
                'ORDER #${booking.orderId}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              AppStatusBadge(
                label: _statusLabel(booking.status),
                status: _badgeStatus(booking.status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            booking.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Organized by ${booking.organizer.businessName}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightCardAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Date',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormatter.formatDate(booking.eventDate),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Deposit Paid',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatPaise(booking.depositPaidPaise),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Reschedule banner
          if (booking.status == BookingStatus.RESCHEDULE_PROPOSED) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.accentAmber.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: AppColors.accentAmber),
                      const SizedBox(width: 6),
                      Text(
                        'Vendor Proposed New Date',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentAmber,
                        ),
                      ),
                    ],
                  ),
                  if (booking.rescheduleNote != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      booking.rescheduleNote!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AppPrimaryButton(
                          text: 'Accept',
                          onPressed: () {
                            ref
                                .read(myBookingsProvider.notifier)
                                .acceptReschedule(booking.id);
                            AppSnackbar.show(
                              context,
                              message: 'New date confirmed!',
                              type: SnackbarType.success,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppSecondaryButton(
                          text: 'Decline & Cancel',
                          onPressed: () {
                            ref
                                .read(myBookingsProvider.notifier)
                                .cancelBooking(booking.id);
                            AppSnackbar.show(
                              context,
                              message: 'Booking cancelled.',
                              type: SnackbarType.info,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(BookingStatus s) {
    switch (s) {
      case BookingStatus.ACCEPTED:
        return 'Confirmed';
      case BookingStatus.REQUESTED:
        return 'Pending Review';
      case BookingStatus.RESCHEDULE_PROPOSED:
        return 'Date Reschedule';
      case BookingStatus.COMPLETED:
        return 'Completed';
      case BookingStatus.CANCELLED:
        return 'Cancelled';
      case BookingStatus.CONFIRMED:
        return 'Confirmed';
      case BookingStatus.REJECTED:
        return 'Declined';
    }
  }

  BadgeStatus _badgeStatus(BookingStatus s) {
    switch (s) {
      case BookingStatus.ACCEPTED:
      case BookingStatus.CONFIRMED:
      case BookingStatus.COMPLETED:
        return BadgeStatus.accepted;
      case BookingStatus.RESCHEDULE_PROPOSED:
      case BookingStatus.REQUESTED:
        return BadgeStatus.requested;
      case BookingStatus.CANCELLED:
      case BookingStatus.REJECTED:
        return BadgeStatus.cancelled;
    }
  }
}

class _TicketPassCard extends StatelessWidget {
  final EventTicketPass ticket;

  const _TicketPassCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
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
              Text(
                ticket.ticketTypeName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              AppStatusBadge(
                label: ticket.isCheckedIn ? 'Checked In' : 'Valid Pass',
                status: ticket.isCheckedIn
                    ? BadgeStatus.completed
                    : BadgeStatus.accepted,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ticket.eventTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            ticket.venueName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: QrImageView(
                data: ticket.qrCodeData,
                version: QrVersions.auto,
                size: 140,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Show this QR code at the entrance',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
