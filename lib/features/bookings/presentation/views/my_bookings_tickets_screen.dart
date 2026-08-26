import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppColors.getCardDecoration(
        context,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ORDER #$shortOrderId',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.getTextMuted(context),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: _statusLabel(booking.status),
                status: _badgeStatus(booking.status),
                showBackground: false,
              ),
            ],
          ),
          const SizedBox(height: 10),
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
            'Organized by ${booking.organizer.businessName}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 12),

          // ── 24h SLA Countdown for REQUESTED bookings ─────────────────────
          if (booking.status == BookingStatus.REQUESTED) ...[
            Row(
              children: [
                const Icon(Icons.timer_rounded,
                    size: 15, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '24h SLA Guarantee: 18h 35m remaining',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.getTextPrimary(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.isDark(context)
                  ? Colors.black.withValues(alpha: 0.3)
                  : AppColors.getCardAlt(context),
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
                        color: AppColors.getTextMuted(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormatter.formatDate(booking.eventDate),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.getTextPrimary(context),
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
                        color: AppColors.getTextMuted(context),
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

          // Cancel button for active bookings
          if (booking.status == BookingStatus.CONFIRMED ||
              booking.status == BookingStatus.ACCEPTED ||
              booking.status == BookingStatus.REQUESTED) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.cancel_outlined,
                    size: 14, color: AppColors.accentRose),
                label: Text(
                  'Cancel Booking',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppColors.getCardDecoration(
        context,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Tier & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ticket.ticketTypeName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Builder(
                builder: (context) {
                  final isCancelled = ticket.status.toUpperCase() == 'CANCELLED';
                  final Color badgeBg = isCancelled
                      ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                      : (ticket.isCheckedIn
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                          : (ticket.isConfirmed
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.12)));
                  final Color badgeColor = isCancelled
                      ? const Color(0xFFEF4444)
                      : (ticket.isCheckedIn
                          ? const Color(0xFF2563EB)
                          : (ticket.isConfirmed
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706)));
                  final IconData badgeIcon = isCancelled
                      ? Icons.cancel_outlined
                      : (ticket.isCheckedIn
                          ? Icons.verified_user_rounded
                          : (ticket.isConfirmed
                              ? Icons.check_circle_rounded
                              : Icons.hourglass_top_rounded));
                  final String badgeText = isCancelled
                      ? 'CANCELLED'
                      : (ticket.isCheckedIn
                          ? 'CHECKED IN'
                          : (ticket.isConfirmed ? 'CONFIRMED PASS' : 'PENDING REVIEW'));

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          badgeIcon,
                          size: 13,
                          color: badgeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badgeText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Event Title
          Text(
            ticket.eventTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),

          // Date & Time Row
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                DateFormatter.formatEventDate(ticket.eventDate),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '${DateFormatter.formatEventTime(ticket.eventDate)} IST',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Venue / Mode Row
          Row(
            children: [
              Icon(
                ticket.isOnline ? Icons.laptop_mac_rounded : Icons.location_on_rounded,
                size: 14,
                color: ticket.isOnline ? const Color(0xFF3B82F6) : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ticket.venueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.getTextSecondary(context),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.getBorder(context)),
          const SizedBox(height: 14),

          // Action Buttons
          if (ticket.status.toUpperCase() == 'CANCELLED') ...[
            InkWell(
              onTap: () => CancellationRefundModal.show(
                context: context,
                targetId: ticket.registrationId,
                targetType: RefundTargetType.REGISTRATION,
                fallbackTitle: ticket.eventTitle,
                fallbackPaidPaise: ticket.totalAmountPaise,
                fallbackDate: ticket.eventDate,
              ),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      size: 14,
                      color: Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'PASS CANCELLED • VIEW REFUND',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFEF4444),
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 9,
                      color: Color(0xFFEF4444),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (ticket.isPending) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFD97706)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your registration is under host review. Pass QR code will be generated once approved.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.cancel_outlined, size: 14, color: Color(0xFFEF4444)),
                label: Text(
                  'Cancel Registration',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444),
                  ),
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
            ),
          ] else ...[
            Row(
              children: [
                if (ticket.isOnline && ticket.accessLink != null && ticket.accessLink!.isNotEmpty) ...[
                  Expanded(
                    child: AppPrimaryButton(
                      text: 'Join Meeting',
                      icon: Icons.video_call_rounded,
                      backgroundColor: const Color(0xFF2563EB),
                      onPressed: () => _launchMeetingUrl(context, ticket.accessLink!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                    label: Text(
                      'QR',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => EntryQrDialog.show(context, ticket),
                  ),
                ] else ...[
                  Expanded(
                    child: AppPrimaryButton(
                      text: 'Show Entry QR Code',
                      icon: Icons.qr_code_2_rounded,
                      height: 42,
                      fontSize: 13.5,
                      onPressed: () => EntryQrDialog.show(context, ticket),
                    ),
                  ),
                ],
                if (!ticket.isCheckedIn) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Cancel Ticket & Refund',
                    icon: const Icon(Icons.cancel_outlined, size: 20, color: Color(0xFFEF4444)),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.all(10),
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
      ),
    );
  }
}
