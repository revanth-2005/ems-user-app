import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/common_widgets/app_button.dart';
import '../../../../core/common_widgets/app_loader.dart';
import '../../../../core/common_widgets/app_network_image.dart';
import '../../../../core/common_widgets/app_snackbar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../bookings/domain/entities/booking_entities.dart';
import '../../../bookings/presentation/providers/booking_providers.dart';
import '../../../bookings/presentation/widgets/entry_qr_dialog.dart';
import '../../domain/entities/catalog_entities.dart';
import '../providers/catalog_providers.dart';
import '../widgets/ticket_selection_bottom_sheet.dart';

class EventDetailScreen extends HookConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  Future<void> _openMap(String address) async {
    final query = Uri.encodeComponent(address);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _addToCalendar(PublicEvent event) async {
    final startTimeStr = '${event.startDatetime.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.').first}Z';
    final endTime = event.endDatetime ?? event.startDatetime.add(const Duration(hours: 3));
    final endTimeStr = '${endTime.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.').first}Z';

    final calUrl = Uri.parse(
      'https://calendar.google.com/calendar/render?action=TEMPLATE'
      '&text=${Uri.encodeComponent(event.title)}'
      '&dates=$startTimeStr/$endTimeStr'
      '&details=${Uri.encodeComponent(event.description ?? "Event on EMS")}'
      '&location=${Uri.encodeComponent(event.venueAddress ?? event.venueName ?? "Online")}',
    );

    if (await canLaunchUrl(calUrl)) {
      await launchUrl(calUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));

    return Scaffold(
      backgroundColor: AppColors.getBg(context),
      body: eventAsync.when(
        loading: () => const Center(child: AppLoader(message: 'Loading event details…')),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(
                'Failed to load event',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              AppPrimaryButton(
                text: 'Retry',
                onPressed: () => ref.refresh(eventDetailProvider(eventId)),
              ),
            ],
          ),
        ),
        data: (event) {
          if (event == null) {
            return Center(
              child: Text(
                'Event not found',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.getTextPrimary(context),
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // ── Hero App Bar ─────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.getSurface(context),
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context).withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: AppColors.getCardShadow(context),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: AppColors.getTextPrimary(context)),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context).withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: AppColors.getCardShadow(context),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.share_rounded,
                          size: 18, color: AppColors.getTextPrimary(context)),
                      onPressed: () {
                        AppSnackbar.show(
                          context,
                          message: 'Link copied to clipboard!',
                          type: SnackbarType.success,
                        );
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        url: event.coverImageUrl,
                        categoryHint: event.category?.name ?? 'Event',
                        titleHint: event.title,
                        fit: BoxFit.cover,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.85),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 20,
                        right: 20,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: event.isOnline
                                    ? const Color(0xFF3B82F6)
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    event.isOnline ? Icons.wifi_rounded : Icons.location_on_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    event.isOnline ? 'VIRTUAL EVENT' : 'IN-PERSON',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (event.category != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  event.category!.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Main Details Content ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        event.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.getTextPrimary(context),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Host Info Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.getCardAlt(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hosted by',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.getTextSecondary(context),
                                    ),
                                  ),
                                  Text(
                                    event.hostName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF059669)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified Host',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Date & Time Box with Add to Calendar
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.getBorder(context)),
                          boxShadow: AppColors.getCardShadow(context),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormatter.formatEventDate(event.startDatetime),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.getTextPrimary(context),
                                        ),
                                      ),
                                      Text(
                                        '${DateFormatter.formatEventTime(event.startDatetime)} IST',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppColors.getTextSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.add_rounded, size: 14),
                                  label: Text(
                                    'Calendar',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: AppColors.primary,
                                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _addToCalendar(event),
                                ),
                              ],
                            ),

                            const Divider(height: 24),

                            // Venue / Location Row
                            Row(
                              children: [
                                Icon(
                                  event.isOnline ? Icons.laptop_mac_rounded : Icons.location_on_rounded,
                                  color: event.isOnline ? const Color(0xFF2563EB) : AppColors.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.isOnline ? 'Online Virtual Event' : (event.venueName ?? 'Venue Location'),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.getTextPrimary(context),
                                        ),
                                      ),
                                      Text(
                                        event.isOnline
                                            ? 'Meeting link shared on pass upon booking'
                                            : (event.venueAddress ?? event.venueCity ?? 'Location details provided on pass'),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          color: AppColors.getTextSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!event.isOnline && (event.venueAddress != null || event.venueName != null)) ...[
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.map_rounded, size: 14),
                                    label: Text(
                                      'Map',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: AppColors.primary,
                                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _openMap(event.venueAddress ?? event.venueName!),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // About Description
                      if (event.description != null && event.description!.isNotEmpty) ...[
                        Text(
                          'About this Event',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          event.description!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.getTextSecondary(context),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Ticket Tiers Section
                      if (event.ticketTypes.isNotEmpty) ...[
                        Text(
                          'Available Ticket Passes',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.getTextPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...event.ticketTypes.map((tier) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.getSurface(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.getBorder(context)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tier.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.getTextPrimary(context),
                                        ),
                                      ),
                                      if (tier.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          tier.description!,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: AppColors.getTextSecondary(context),
                                          ),
                                        ),
                                      ],
                                      if (tier.remainingCount != null && tier.remainingCount! > 0) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          '⚡ ${tier.remainingCount} passes available',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF059669),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      tier.isFree
                                          ? 'FREE'
                                          : CurrencyFormatter.formatPaise(tier.priceInPaise),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: tier.isFree ? const Color(0xFF10B981) : AppColors.primary,
                                      ),
                                    ),
                                    if (!tier.isFree)
                                      Text(
                                        '+ taxes',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          color: AppColors.getTextMuted(context),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: eventAsync.valueOrNull == null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                border: Border(top: BorderSide(color: AppColors.getBorder(context))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Consumer(
                  builder: (context, ref, _) {
                    final event = eventAsync.valueOrNull!;
                    final myTickets = ref.watch(myTicketsProvider).valueOrNull ?? [];
                    final userPass = myTickets.firstWhere(
                      (t) => t.eventId == event.id || t.eventTitle.toLowerCase() == event.title.toLowerCase(),
                      orElse: () => EventTicketPass(
                        id: '',
                        registrationId: '',
                        createdAt: DateTime.now(),
                      ),
                    );

                    final hasPass = (userPass.id.isNotEmpty) || event.hasUserRegistered;

                    if (hasPass) {
                      return AppPrimaryButton(
                        text: 'View My Pass & Entry QR Code',
                        backgroundColor: const Color(0xFF10B981),
                        onPressed: () {
                          final passToView = userPass.id.isNotEmpty
                              ? userPass
                              : EventTicketPass.fromJson({
                                  'registrationId': event.userRegistration?.id ?? 'reg_${event.id}',
                                  'quantity': event.userRegistration?.quantity ?? 1,
                                  'status': event.userRegistration?.status ?? 'CONFIRMED',
                                  'event': event.toJson(),
                                  'qrCodeData': event.userRegistration?.qrCodeToken ?? event.userRegistration?.id ?? event.id,
                                  'qrCodeToken': event.userRegistration?.qrCodeToken,
                                  'accessLink': event.userRegistration?.accessLink ?? event.meetingUrl,
                                });

                          EntryQrDialog.show(context, passToView);
                        },
                      );
                    }

                    return AppPrimaryButton(
                      text: 'Select Tickets — ${event.effectivePriceLabel}',
                      onPressed: () {
                        TicketSelectionBottomSheet.show(context, event);
                      },
                    );
                  },
                ),
              ),
            ),
    );
  }
}
