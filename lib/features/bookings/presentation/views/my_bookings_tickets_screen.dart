import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_error_view.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_network_image.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/booking_entities.dart';
import '../providers/booking_providers.dart';
import '../widgets/cancellation_refund_modal.dart';
import '../widgets/entry_qr_dialog.dart';

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
      backgroundColor: AppColors.getBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'My Bookings & Passes',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.getTextPrimary(context),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.getCardAlt(context),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _TabPill(
                      label: 'Bookings ($bookingsCount)',
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
                    title: 'No Bookings',
                    subtitle:
                        'Explore curated event packages and book your next celebration.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(myBookingsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final b = bookings[index];
                      return _VendorBookingCard(booking: b);
                    },
                  ),
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
                    subtitle:
                        'Browse live events and register for workshops or concerts.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(myTicketsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final t = tickets[index];
                      return _TicketPassCard(ticket: t);
                    },
                  ),
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
          color: isSelected ? AppColors.getSurface(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          boxShadow: isSelected ? AppColors.getCardShadow(context) : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.primary : AppColors.getTextSecondary(context),
          ),
        ),
      ),
    );
  }
}

class _VendorBookingCard extends HookConsumerWidget {
  final VendorBooking booking;

  const _VendorBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortOrderId = booking.orderId.length > 8
        ? booking.orderId.substring(0, 8).toUpperCase()
        : booking.orderId.toUpperCase();

    final statusText = _statusLabel(booking.status);
    final isCancelled = booking.status == BookingStatus.CANCELLED ||
        booking.status == BookingStatus.REJECTED;
    final isConfirmed = booking.status == BookingStatus.CONFIRMED ||
        booking.status == BookingStatus.ACCEPTED;
    final isReschedule = booking.status == BookingStatus.RESCHEDULE_PROPOSED;

    final Color statusColor = isCancelled
        ? const Color(0xFFEF4444)
        : (isConfirmed
            ? const Color(0xFF059669)
            : (isReschedule
                ? const Color(0xFFEA580C)
                : const Color(0xFFD97706)));

    final dayStr = booking.eventDate.day.toString();
    final monthStr =
        DateFormat('MMM').format(booking.eventDate).toUpperCase();
    final weekdayStr = DateFormat('EEEE').format(booking.eventDate);
    final timeStr =
        booking.startTime.isNotEmpty ? booking.startTime : '18:00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Main Horizontal Perforated Ticket Card ───────────────────────────
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE5E9EE), // Premium Lightly Grey Ticket Stub
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Left Section: Main Order & Vendor Details ─────────────
                  Expanded(
                    flex: 12,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Order ID & Status Micro-Pill (Overflow-Proof)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '#$shortOrderId',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF475569),
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 3.5),
                                    Text(
                                      statusText,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            booking.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                              height: 1.2,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Organized by ${booking.organizer.businessName}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // 24h SLA Countdown
                          if (booking.status == BookingStatus.REQUESTED) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  size: 12,
                                  color: Color(0xFFB45309),
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    '24h SLA: ${DateFormatter.formatSlaRemaining(booking.slaDeadline)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFB45309),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 8),
                          // Location / Venue on Bottom Left
                          Text(
                            booking.organizer.city ?? 'On-Site Service',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            booking.organizer.businessName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Middle Vertical Perforation Divider with Notches ──────
                  SizedBox(
                    width: 18,
                    height: 135,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Center(
                          child: SizedBox(
                            width: 1.5,
                            height: 105,
                            child: _VerticalDashedDivider(
                              color: const Color(0xFF94A3B8),
                              width: 1.5,
                              dashHeight: 5,
                              dashSpace: 4,
                            ),
                          ),
                        ),
                        // Top cutout notch
                        Positioned(
                          top: -9,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.getBg(context),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        // Bottom cutout notch
                        Positioned(
                          bottom: -9,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: AppColors.getBg(context),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Right Section: Price Badge + Big Date + Time + Action ──
                  Expanded(
                    flex: 7,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top-Right Price Pill Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              CurrencyFormatter.formatPaise(
                                  booking.depositPaidPaise),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Big Date Block
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dayStr,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                  height: 1.0,
                                ),
                              ),
                              Text(
                                monthStr,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF475569),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Day of Week & Time + Receipt Icon
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      weekdayStr,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF475569),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      timeStr,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showCancelBookingDialog(
                                    context, ref, booking),
                                child: const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 16,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Action Buttons & Reschedule Banners Below Card ────────────────────
        if (booking.status == BookingStatus.CONFIRMED ||
            booking.status == BookingStatus.ACCEPTED ||
            booking.status == BookingStatus.REQUESTED) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.cancel_outlined,
                  size: 14, color: AppColors.accentRose),
              label: Text(
                'Cancel Booking',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentRose,
                ),
              ),
              onPressed: () {
                _showCancelBookingDialog(context, ref, booking);
              },
            ),
          ),
        ],

        if (booking.status == BookingStatus.RESCHEDULE_PROPOSED) ...[
          const SizedBox(height: 8),
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
                      color: AppColors.getTextSecondary(context),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: AppPrimaryButton(
                        text: 'Accept',
                        height: 38,
                        fontSize: 12,
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
                        height: 38,
                        fontSize: 12,
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
    );
  }

  void _showCancelBookingDialog(
      BuildContext context, WidgetRef ref, VendorBooking booking) {
    CancellationRefundModal.show(
      context: context,
      targetId: booking.id,
      targetType: RefundTargetType.BOOKING,
      fallbackTitle: booking.title,
      fallbackPaidPaise: booking.depositPaidPaise,
      fallbackDate: booking.eventDate,
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
}


class _TicketPassCard extends StatelessWidget {
  final EventTicketPass ticket;

  const _TicketPassCard({required this.ticket});

  Future<void> _launchMeetingUrl(BuildContext context, String urlStr) async {
    final url = Uri.tryParse(urlStr);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          message: 'Could not launch meeting link: $urlStr',
          type: SnackbarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = ticket.status.toUpperCase() == 'CANCELLED';
    final isVip = ticket.ticketTypeName.toUpperCase().contains('VIP');
    final isEarly = ticket.ticketTypeName.toUpperCase().contains('EARLY');
    final isFree = ticket.ticketTypeName.toUpperCase().contains('FREE');

    final Color badgeBgColor = isCancelled
        ? const Color(0xFFFEE2E2)
        : (ticket.isPending
            ? const Color(0xFFFEF3C7)
            : (isVip || isEarly
                ? const Color(0xFFFBBF24)
                : const Color(0xFFD1FAE5)));

    final Color badgeTextColor = isCancelled
        ? const Color(0xFFB91C1C)
        : (ticket.isPending
            ? const Color(0xFFB45309)
            : (isVip || isEarly
                ? const Color(0xFF78350F)
                : const Color(0xFF065F46)));

    final IconData badgeIcon = isCancelled
        ? Icons.cancel_outlined
        : (ticket.isPending
            ? Icons.hourglass_top_rounded
            : (isVip ? Icons.star_rounded : Icons.check_circle_outline_rounded));

    final String badgeText = isCancelled
        ? 'CANCELLED'
        : (ticket.isPending
            ? 'PENDING'
            : (isVip
                ? 'VIP PASS'
                : (isEarly
                    ? 'EARLY BIRD'
                    : (isFree ? 'FREE PASS' : 'CONFIRMED'))));

    final shortRegId = ticket.registrationId.length > 8
        ? ticket.registrationId.substring(0, 8).toUpperCase()
        : ticket.registrationId.toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Main Perforated Ticket Card ───────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F6),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Section: Thumbnail + Event Header + Info Matrix ───────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Thumbnail & Title Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 70,
                                height: 70,
                                child: ticket.coverImageUrl != null &&
                                        ticket.coverImageUrl!.isNotEmpty
                                    ? AppNetworkImage(
                                        url: ticket.coverImageUrl!,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: const Color(0xFFE2E8F0),
                                        child: const Icon(
                                          Icons.event_available_rounded,
                                          color: Color(0xFF64748B),
                                          size: 32,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ticket.eventTitle,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F172A),
                                      height: 1.22,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ticket.venueCity ??
                                        (ticket.venueName.isNotEmpty
                                            ? ticket.venueName
                                            : 'Event Venue'),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 2-Column Info Grid
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _TicketInfoCell(
                                    label: 'Standort / Venue',
                                    value: ticket.venueName.isNotEmpty
                                        ? ticket.venueName
                                        : 'Main Arena',
                                  ),
                                  const SizedBox(height: 10),
                                  _TicketInfoCell(
                                    label: 'Uhrzeit / Time',
                                    value:
                                        '${DateFormatter.formatEventTime(ticket.eventDate)} IST',
                                  ),
                                  const SizedBox(height: 10),
                                  _TicketInfoCell(
                                    label: 'Email / Attendee',
                                    value: ticket.attendeeName.isNotEmpty
                                        ? ticket.attendeeName
                                        : 'Guest Attendee',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Right Column
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _TicketInfoCell(
                                    label: 'Datum / Date',
                                    value: DateFormatter.formatEventDate(
                                        ticket.eventDate),
                                  ),
                                  const SizedBox(height: 10),
                                  _TicketInfoCell(
                                    label: 'Person / Pass',
                                    value: '${ticket.quantity}x Pass',
                                  ),
                                  const SizedBox(height: 10),
                                  _TicketInfoCell(
                                    label: 'Typ / Tier',
                                    value: ticket.ticketTypeName,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Middle Perforation Divider with Notches ───────────────────
                  SizedBox(
                    height: 24,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: _DashedDivider(
                            color: Color(0xFFCBD5E1),
                            height: 1.5,
                            dashWidth: 6,
                            dashSpace: 5,
                          ),
                        ),
                        // Left cutout notch
                        Positioned(
                          left: -12,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.getBg(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Right cutout notch
                        Positioned(
                          right: -12,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.getBg(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Bottom Stub: QR Code + Attendee Name + Vertical Badge ────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 16, 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Crisp High-Contrast QR Code
                        GestureDetector(
                          onTap: () => EntryQrDialog.show(context, ticket),
                          child: Container(
                            width: 86,
                            height: 86,
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ticket.isPending
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.hourglass_top_rounded,
                                        color: Color(0xFFD97706),
                                        size: 28,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'REVIEW',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFFD97706),
                                        ),
                                      ),
                                    ],
                                  )
                                : isCancelled
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.cancel_outlined,
                                            color: Color(0xFFEF4444),
                                            size: 28,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'CANCELLED',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 8.5,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFFEF4444),
                                            ),
                                          ),
                                        ],
                                      )
                                    : QrImageView(
                                        data: ticket.qrCodeData,
                                        version: QrVersions.auto,
                                        size: 76,
                                        padding: EdgeInsets.zero,
                                        eyeStyle: const QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: Color(0xFF0F172A),
                                        ),
                                        dataModuleStyle:
                                            const QrDataModuleStyle(
                                          dataModuleShape:
                                              QrDataModuleShape.square,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Center: Attendee Name + Pass ID
                        Expanded(
                          child: GestureDetector(
                            onTap: () => EntryQrDialog.show(context, ticket),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  ticket.attendeeName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                    height: 1.15,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pass #$shortRegId',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      ticket.isConfirmed
                                          ? Icons.verified_rounded
                                          : (ticket.isPending
                                              ? Icons.schedule_rounded
                                              : Icons.info_outline_rounded),
                                      size: 13,
                                      color: ticket.isConfirmed
                                          ? const Color(0xFF059669)
                                          : (ticket.isPending
                                              ? const Color(0xFFD97706)
                                              : const Color(0xFFEF4444)),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      ticket.isConfirmed
                                          ? 'Verified Entry'
                                          : (ticket.isPending
                                              ? 'Approval Pending'
                                              : 'Pass Inactive'),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: ticket.isConfirmed
                                          ? const Color(0xFF059669)
                                          : (ticket.isPending
                                              ? const Color(0xFFD97706)
                                              : const Color(0xFFEF4444)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Right: Vertical Gold/Amber VIP Badge
                        RotatedBox(
                          quarterTurns: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: badgeBgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(badgeIcon,
                                    size: 10, color: badgeTextColor),
                                const SizedBox(width: 4),
                                Text(
                                  badgeText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: badgeTextColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Action Buttons Below Ticket ───────────────────────────────────────
        const SizedBox(height: 10),
        if (isCancelled) ...[
          InkWell(
            onTap: () => CancellationRefundModal.show(
              context: context,
              targetId: ticket.registrationId,
              targetType: RefundTargetType.REGISTRATION,
              fallbackTitle: ticket.eventTitle,
              fallbackPaidPaise: ticket.totalAmountPaise,
              fallbackDate: ticket.eventDate,
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    size: 14,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PASS CANCELLED • VIEW REFUND',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFEF4444),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Color(0xFFEF4444),
                  ),
                ],
              ),
            ),
          ),
        ] else if (ticket.isPending) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Registration under host review. Pass QR generated upon approval.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextPrimary(context),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => CancellationRefundModal.show(
                    context: context,
                    targetId: ticket.registrationId,
                    targetType: RefundTargetType.REGISTRATION,
                    fallbackTitle: ticket.eventTitle,
                    fallbackPaidPaise: ticket.totalAmountPaise,
                    fallbackDate: ticket.eventDate,
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Row(
            children: [
              if (ticket.isOnline &&
                  ticket.accessLink != null &&
                  ticket.accessLink!.isNotEmpty) ...[
                Expanded(
                  child: AppPrimaryButton(
                    text: 'Join Live Stream',
                    icon: Icons.video_call_rounded,
                    height: 40,
                    fontSize: 12.5,
                    backgroundColor: const Color(0xFF2563EB),
                    onPressed: () =>
                        _launchMeetingUrl(context, ticket.accessLink!),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: AppPrimaryButton(
                  text: 'Show Full QR Pass',
                  icon: Icons.qr_code_2_rounded,
                  height: 40,
                  fontSize: 12.5,
                  onPressed: () => EntryQrDialog.show(context, ticket),
                ),
              ),
              if (!ticket.isCheckedIn) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Cancel Pass',
                  icon: const Icon(Icons.cancel_outlined,
                      size: 18, color: Color(0xFFEF4444)),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFEF4444).withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(8),
                  ),
                  onPressed: () => CancellationRefundModal.show(
                    context: context,
                    targetId: ticket.registrationId,
                    targetType: RefundTargetType.REGISTRATION,
                    fallbackTitle: ticket.eventTitle,
                    fallbackPaidPaise: ticket.totalAmountPaise,
                    fallbackDate: ticket.eventDate,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _TicketInfoCell extends StatelessWidget {
  final String label;
  final String value;

  const _TicketInfoCell({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;
  final double height;
  final double dashWidth;
  final double dashSpace;

  const _DashedDivider({
    this.color = const Color(0xFFCBD5E1),
    this.height = 1.5,
    this.dashWidth = 6,
    this.dashSpace = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: color,
          strokeWidth: height,
          dashLength: dashWidth,
          dashSpace: dashSpace,
          direction: Axis.horizontal,
        ),
      ),
    );
  }
}

class _VerticalDashedDivider extends StatelessWidget {
  final Color color;
  final double width;
  final double dashHeight;
  final double dashSpace;

  const _VerticalDashedDivider({
    this.color = const Color(0xFFCBD5E1),
    this.width = 1.5,
    this.dashHeight = 5,
    this.dashSpace = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: double.infinity,
      child: CustomPaint(
        painter: _DashedLinePainter(
          color: color,
          strokeWidth: width,
          dashLength: dashHeight,
          dashSpace: dashSpace,
          direction: Axis.vertical,
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double dashSpace;
  final Axis direction;

  _DashedLinePainter({
    this.color = const Color(0xFFCBD5E1),
    this.strokeWidth = 1.5,
    this.dashLength = 5,
    this.dashSpace = 4,
    this.direction = Axis.vertical,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (direction == Axis.vertical) {
      double startY = 0;
      final x = size.width / 2;
      while (startY < size.height) {
        canvas.drawLine(
          Offset(x, startY),
          Offset(x, (startY + dashLength).clamp(0, size.height)),
          paint,
        );
        startY += dashLength + dashSpace;
      }
    } else {
      double startX = 0;
      final y = size.height / 2;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset((startX + dashLength).clamp(0, size.width), y),
          paint,
        );
        startX += dashLength + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.dashSpace != dashSpace ||
      oldDelegate.direction != direction;
}



