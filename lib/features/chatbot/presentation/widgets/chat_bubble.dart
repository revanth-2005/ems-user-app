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

  const ChatBubble({
    super.key,
    required this.message,
    this.onSuggestedActionTapped,
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

  const _BotBubble({
    required this.message,
    required this.timeStr,
    required this.isDark,
    this.onSuggestedActionTapped,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleBg = isDark ? const Color(0xFF161618) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF28282C) : const Color(0xFFE5E7EB);
    final textColor =
        isDark ? Colors.white : const Color(0xFF111827);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 12, right: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.32),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text bubble
                Container(
                  decoration: BoxDecoration(
                    color: bubbleBg,
                    border: Border.all(color: borderColor, width: 1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.22 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 13),
                  child: Text(
                    message.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, color: Colors.grey.shade500),
                ),

                // ── Rich Cards ─────────────────────────────────────────────
                if (message.cards != null && message.cards!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 230,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: message.cards!.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 10),
                      itemBuilder: (ctx, i) =>
                          _buildCard(ctx, message.cards![i]),
                    ),
                  ),
                ],

                // ── Suggested Actions ─────────────────────────────────────
                if (message.suggestedActions != null &&
                    message.suggestedActions!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: message.suggestedActions!.map((action) {
                      return _SuggestedChip(
                        label: action,
                        isDark: isDark,
                        onTap: () =>
                            onSuggestedActionTapped?.call(action),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
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
      default:
        return const SizedBox.shrink();
    }
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

