import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../app/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/chat_message_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final ValueChanged<String>? onSuggestedActionTapped;
  final bool showSuggestedActions;

  const ChatBubble({
    super.key,
    required this.message,
    this.onSuggestedActionTapped,
    this.showSuggestedActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final timeStr = DateFormat('hh:mm a').format(message.timestamp);
    final isUser = message.type == ChatMessageType.user;

    if (isUser) {
      return _UserBubble(text: message.text, timeStr: timeStr);
    }
    return _BotBubble(
      message: message,
      timeStr: timeStr,
      isDark: isDark,
      onSuggestedActionTapped: onSuggestedActionTapped,
      showSuggestedActions: showSuggestedActions,
    );
  }
}

// ── User bubble ──────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  final String text;
  final String timeStr;

  const _UserBubble({required this.text, required this.timeStr});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 56, right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeStr,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ── Bot bubble ───────────────────────────────────────────────────────────────

class _BotBubble extends StatelessWidget {
  final ChatMessage message;
  final String timeStr;
  final bool isDark;
  final ValueChanged<String>? onSuggestedActionTapped;
  final bool showSuggestedActions;

  const _BotBubble({
    required this.message,
    required this.timeStr,
    required this.isDark,
    this.onSuggestedActionTapped,
    this.showSuggestedActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF111827);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plain Text
          _buildFormattedText(
            message.text,
            GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: textColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            timeStr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),

          // ── Rich Cards ─────────────────────────────────────────────
          if (message.cards != null && message.cards!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 275,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: message.cards!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) =>
                    _buildCard(ctx, message.cards![i]),
              ),
            ),
          ],

          // ── Suggested Actions ─────────────────────────────────────
          if (showSuggestedActions &&
              message.suggestedActions != null &&
              message.suggestedActions!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: message.suggestedActions!.map((action) {
                return _SuggestedChip(
                  label: action,
                  isDark: isDark,
                  onTap: () => onSuggestedActionTapped?.call(action),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, ChatCard card) {
    switch (card.type) {
      case 'PACKAGE_CARD':
        return _PackageCard(
          data: PackageCardData.fromMap(card.data),
          onActionSelected: onSuggestedActionTapped,
        );
      case 'EVENT_CARD':
        return _EventCard(
          data: EventCardData.fromMap(card.data),
          onActionSelected: onSuggestedActionTapped,
        );
      case 'CART_SUMMARY':
        return _CartSummaryCard(data: CartSummaryData.fromMap(card.data));
      case 'BOOKING_CARD':
        return _BookingCard(
          data: BookingCardData.fromMap(card.data),
          onActionSelected: onSuggestedActionTapped,
        );
      case 'TICKET_CARD':
        return _TicketCard(
          data: TicketCardData.fromMap(card.data),
          onActionSelected: onSuggestedActionTapped,
        );
      case 'EVENT_DRAFT_CARD':
        return _EventDraftCard(
          data: EventDraftCardData.fromMap(card.data),
          onActionSelected: onSuggestedActionTapped,
        );
      case 'ANALYTICS_CARD':
        return _AnalyticsCard(data: AnalyticsCardData.fromMap(card.data));
      case 'ATTENDEE_CARD':
        return _AttendeeCard(data: AttendeeCardData.fromMap(card.data));
      case 'ORGANIZER_CARD':
        return _OrganizerCard(
          data: OrganizerCardData.fromMap(card.data),
          onActionSelected: onSuggestedActionTapped,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFormattedText(String text, TextStyle baseStyle) {
    if (!text.contains('**')) {
      return Text(text, style: baseStyle);
    }
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final isBold = i % 2 == 1;
      spans.add(
        TextSpan(
          text: parts[i],
          style: baseStyle.copyWith(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w400,
          ),
        ),
      );
    }
    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}

// ── Suggested Action Chip ─────────────────────────────────────────────────────

class _SuggestedChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _SuggestedChip(
      {required this.label, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E1E22)
              : const Color(0xFFF3F4F6),
          border: Border.all(
            color: isDark
                ? const Color(0xFF333338)
                : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? const Color(0xFFE5E7EB)
                : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}

// ── PACKAGE_CARD ──────────────────────────────────────────────────────────────

class _PackageCard extends StatelessWidget {
  final PackageCardData data;
  final ValueChanged<String>? onActionSelected;

  const _PackageCard({required this.data, this.onActionSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bg = isDark ? const Color(0xFF1C1C20) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C32) : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.search),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: data.coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: data.coverImageUrl!,
                      height: 100,
                      width: 180,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _imagePlaceholder(100),
                    )
                  : _imagePlaceholder(100),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.organizerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '₹${_fmt(data.priceRupees)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      if (data.city.isNotEmpty) ...[
                        const Spacer(),
                        Icon(Icons.location_on_outlined,
                            size: 11, color: Colors.grey.shade500),
                        Text(
                          data.city,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ],
                    ],
                  ),
                  if (data.depositRequiredRupees != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Advance: ₹${_fmt(data.depositRequiredRupees!)}',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: const Color(0xFFF59E0B),
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(double height) => Container(
        height: height,
        width: 180,
        color: const Color(0xFF1A1A1A),
        child: const Icon(Icons.inventory_2_outlined,
            color: Color(0xFF4A4A4A), size: 36),
      );

  String _fmt(int v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toString();
  }
}

// ── EVENT_CARD ────────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final EventCardData data;
  final ValueChanged<String>? onActionSelected;

  const _EventCard({required this.data, this.onActionSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bg = isDark ? const Color(0xFF1C1C20) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C32) : const Color(0xFFE5E7EB);

    String? formattedDate;
    if (data.startDatetime != null) {
      try {
        final dt = DateTime.parse(data.startDatetime!).toLocal();
        formattedDate = DateFormat('EEE, d MMM y').format(dt);
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () => context.push(AppRoutes.eventsDiscovery),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode badge
            if (data.mode != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data.mode!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              data.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
                height: 1.3,
              ),
            ),
            const Spacer(),
            if (data.venueName != null) ...[
              Row(children: [
                Icon(Icons.location_on_outlined,
                    size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    data.venueName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
            ],
            if (formattedDate != null) ...[
              Row(children: [
                Icon(Icons.calendar_today_outlined,
                    size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Text(
                  formattedDate,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
              ]),
              const SizedBox(height: 6),
            ],
            if (data.ticketStartingPriceRupees != null)
              Text(
                '₹${data.ticketStartingPriceRupees} onwards',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── CART_SUMMARY ──────────────────────────────────────────────────────────────

class _CartSummaryCard extends StatelessWidget {
  final CartSummaryData data;

  const _CartSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bg = isDark ? const Color(0xFF1C1C20) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C32) : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.cart),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_cart_outlined,
                    color: Color(0xFF10B981), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'My Cart',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            _row('Items', '${data.totalItems}', isDark),
            const SizedBox(height: 6),
            _row('Total Value',
                '₹${_fmt(data.totalValueRupees)}', isDark),
            const SizedBox(height: 6),
            _row('Deposit Due',
                '₹${_fmt(data.totalDepositDueRupees)}', isDark,
                highlight: true),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Go to Cart →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, bool isDark,
      {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: Colors.grey.shade500)),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: highlight
                ? const Color(0xFFF59E0B)
                : (isDark ? Colors.white : const Color(0xFF111827)),
          ),
        ),
      ],
    );
  }

  String _fmt(int v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toString();
  }
}

// ── BOOKING_CARD ─────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final BookingCardData data;
  final ValueChanged<String>? onActionSelected;

  const _BookingCard({required this.data, this.onActionSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bg = isDark ? const Color(0xFF1C1C20) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C32) : const Color(0xFFE5E7EB);

    final isConfirmed = data.status.toUpperCase() == 'CONFIRMED';
    final statusColor =
        isConfirmed ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.bookings),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    data.status.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.bookmark_outline_rounded,
                    size: 16, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data.packageName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vendor: ${data.vendorName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
            const Spacer(),
            if (data.balanceDueRupees != null) ...[
              Text(
                'Balance Due: ₹${data.balanceDueRupees}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 6),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(
                      color: isDark
                          ? const Color(0xFF3B3B42)
                          : const Color(0xFFD1D5DB)),
                ),
                onPressed: () => context.push(AppRoutes.bookings),
                child: Text(
                  'View Booking',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── TICKET_CARD ──────────────────────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  final TicketCardData data;
  final ValueChanged<String>? onActionSelected;

  const _TicketCard({required this.data, this.onActionSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bg = isDark ? const Color(0xFF1C1C20) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C32) : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.bookings),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.confirmation_number_outlined,
                    color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 6),
                Text(
                  'Event Ticket',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
                const Spacer(),
                Text(
                  'Qty: ${data.quantity}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              data.eventTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.ticketType,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => context.push(AppRoutes.bookings),
                icon: const Icon(Icons.qr_code_rounded, size: 14),
                label: Text(
                  'Show QR Pass',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Organizer AI Copilot: Event Draft Card ───────────────────────────────────

class _EventDraftCard extends StatelessWidget {
  final EventDraftCardData data;
  final ValueChanged<String>? onActionSelected;

  const _EventDraftCard({required this.data, this.onActionSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.orange.shade400.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Draft Status Pill + Event ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_note_rounded,
                        size: 13, color: Colors.orange.shade900),
                    const SizedBox(width: 4),
                    Text(
                      'DRAFT EVENT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange.shade900,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Text(
                  '#${data.eventId.isNotEmpty ? data.eventId : 'DRAFT'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),

          // City & Venue
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${data.venue}, ${data.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Ticket Tiers breakdown
          if (data.ticketTiers.isNotEmpty) ...[
            Text(
              'TICKET TIERS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: data.ticketTiers.map((tier) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${tier.name} • ₹${tier.price}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
          ],

          // Action Buttons: Publish Now & Edit Details
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final prompt = 'Publish event ${data.eventId}';
                    onActionSelected?.call(prompt);
                  },
                  icon: const Icon(Icons.rocket_launch_rounded, size: 13),
                  label: Text(
                    'Publish Now',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.white : Colors.grey.shade800,
                    side: BorderSide(
                      color:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => context.push(AppRoutes.hostDashboard),
                  child: Text(
                    'Edit Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Organizer AI Copilot: Analytics Card ─────────────────────────────────────

class _AnalyticsCard extends StatelessWidget {
  final AnalyticsCardData data;

  const _AnalyticsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      width: 290,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D23) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2E323D) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_rounded,
                      color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Organizer Analytics',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data.period,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // GMV Highlight
          Text(
            '₹${NumberFormat('#,##,###').format(data.totalGmvRupees)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF10B981),
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'Total GMV Revenue (0% Platform Fee)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),

          // 3-Metric Row
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.confirmation_number_outlined,
                  value: '${data.ticketsSold}',
                  label: 'Tickets Sold',
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.event_available_outlined,
                  value: '${data.activeEventsCount}',
                  label: 'Active Events',
                  isDark: isDark,
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.visibility_outlined,
                  value: '${data.pageviews}',
                  label: 'Pageviews',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payout action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF262A35) : Colors.grey.shade900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () => context.push(AppRoutes.organizerEarnings),
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 14),
              label: Text(
                'View Earnings & Payouts →',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

// ── Organizer AI Copilot: Attendee Card ──────────────────────────────────────

class _AttendeeCard extends StatelessWidget {
  final AttendeeCardData data;

  const _AttendeeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isChecked = data.isCheckedIn;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1F24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isChecked
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attendee Header: Avatar + Name + Check-in Pill
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isChecked
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : Colors.indigo.withValues(alpha: 0.15),
                child: Text(
                  data.name.isNotEmpty ? data.name[0].toUpperCase() : 'A',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: isChecked
                        ? const Color(0xFF10B981)
                        : Colors.indigo,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      data.phone ?? 'Pass: ${data.ticketTier}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Ticket Tier Tag + Status Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data.ticketTier,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.purple.shade800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isChecked
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isChecked
                          ? Icons.check_circle_rounded
                          : Icons.pending_rounded,
                      size: 12,
                      color: isChecked
                          ? const Color(0xFF10B981)
                          : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isChecked ? 'CHECKED IN' : 'NOT CHECKED IN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isChecked
                            ? const Color(0xFF10B981)
                            : Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action Button: QR Verification
          SizedBox(
            width: double.infinity,
            child: isChecked
                ? Center(
                    child: Text(
                      'Verified ${data.checkedInAt ?? 'at Gate'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => context.push(AppRoutes.hostDashboard),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 14),
                    label: Text(
                      'Verify QR Pass',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Organizer Profile Card ───────────────────────────────────────────────────

class _OrganizerCard extends StatelessWidget {
  final OrganizerCardData data;
  final ValueChanged<String>? onActionSelected;

  const _OrganizerCard({required this.data, this.onActionSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E38) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Avatar + Name + City
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: data.logoUrl != null && data.logoUrl!.isNotEmpty
                    ? Image.network(
                        data.logoUrl!,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                      )
                    : _buildAvatarFallback(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.displayName.isNotEmpty
                          ? data.displayName
                          : data.businessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 11, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Text(
                          data.city,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Rating + Verified Tag
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      '${data.rating}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.amber.shade900,
                      ),
                    ),
                    if (data.ratingCount > 0)
                      Text(
                        ' (${data.ratingCount})',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded,
                        size: 11, color: Color(0xFF10B981)),
                    const SizedBox(width: 3),
                    Text(
                      'VERIFIED',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Catalog stats pill
          Text(
            '${data.totalPackages} Packages • ${data.totalServices} Services',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final route = AppRoutes.organizerProfile
                        .replaceAll(':id', data.id);
                    context.push(route);
                  },
                  child: Text(
                    'View Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isDark ? Colors.white : Colors.grey.shade800,
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  onActionSelected
                      ?.call('Find packages by ${data.businessName}');
                },
                child: Text(
                  'Packages',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      width: 44,
      height: 44,
      color: Colors.indigo.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          data.businessName.isNotEmpty
              ? data.businessName[0].toUpperCase()
              : 'V',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.indigo,
          ),
        ),
      ),
    );
  }
}

