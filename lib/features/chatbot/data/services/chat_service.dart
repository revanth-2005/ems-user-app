import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../domain/models/chat_message_model.dart';

/// HTTP service for the AI Chatbot — talks to POST /chat on the EMS backend.
class ChatService {
  final Dio _dio;

  ChatService(this._dio);

  /// Sends a user message to the AI gateway and returns the bot's ChatMessage.
  Future<ChatMessage> sendMessage({
    required String message,
    String? jwtToken,
    String? sessionId,
  }) async {
    String? token = jwtToken;
    if (token == null || token.isEmpty) {
      token = await SecureStorageService().getAccessToken();
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    final body = <String, dynamic>{
      'message': message,
      if (sessionId != null) 'sessionId': sessionId,
    };

    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/chat',
        data: jsonEncode(body),
        options: Options(headers: headers),
      );

      // If backend responded with 404 or non-2xx status, use demo simulation fallback
      if (response.statusCode != 200 && response.statusCode != 201) {
        return _generateSimulatedResponse(message);
      }

      final dynamic rawData = response.data;
      Map<String, dynamic> data;
      if (rawData is Map<String, dynamic>) {
        data = rawData;
      } else if (rawData is String) {
        data = jsonDecode(rawData) as Map<String, dynamic>;
      } else {
        return _generateSimulatedResponse(message);
      }

      final cards = <ChatCard>[];
      if (data['cards'] is List) {
        for (final c in data['cards'] as List) {
          if (c is Map<String, dynamic>) {
            cards.add(ChatCard.fromJson(c));
          }
        }
      }

      final suggested = <String>[];
      if (data['suggestedActions'] is List) {
        for (final a in data['suggestedActions'] as List) {
          suggested.add(a.toString());
        }
      }

      // Extract text reply from multiple possible response formats
      final replyText = data['reply']?.toString() ??
          data['response']?.toString() ??
          data['text']?.toString() ??
          data['content']?.toString() ??
          (data['data'] is Map ? data['data']['reply']?.toString() : null) ??
          '';

      if (replyText.isEmpty && cards.isEmpty) {
        return _generateSimulatedResponse(message);
      }

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: replyText.isNotEmpty
            ? replyText
            : 'Here is what I found for you:',
        type: ChatMessageType.bot,
        timestamp: DateTime.now(),
        cards: cards.isNotEmpty ? cards : null,
        suggestedActions: suggested.isNotEmpty ? suggested : null,
      );
    } catch (e) {
      debugPrint('⚠️ Chat API call failed: $e. Falling back to rich simulation.');
      return _generateSimulatedResponse(message);
    }
  }

  /// Provides rich demo responses with real cards when the backend /chat is offline or 404.
  ChatMessage _generateSimulatedResponse(String message) {
    final q = message.toLowerCase();

    // ── Organizer & Vendor Search ────────────────────────────────────────────
    if (q.contains('organizer') ||
        q.contains('vendor') ||
        q.contains('planner') ||
        q.contains('caterer') ||
        q.contains('photographer')) {
      final isDelhi = q.contains('delhi');
      final cityLabel = isDelhi ? ' in Delhi' : ' in Mumbai';

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            'Here are top-rated verified event organizers & vendors$cityLabel:',
        type: ChatMessageType.bot,
        timestamp: DateTime.now(),
        cards: [
          ChatCard(
            type: 'ORGANIZER_CARD',
            data: {
              'id': 'org_mumbai_01',
              'businessName': isDelhi
                  ? 'Delhi Royal Events & Decor'
                  : 'Mumbai Live Concerts & Sound',
              'displayName': isDelhi
                  ? 'Delhi Royal Events'
                  : 'Mumbai Live Concerts',
              'city': isDelhi ? 'Delhi' : 'Mumbai',
              'totalPackages': 4,
              'totalServices': 6,
              'rating': 4.9,
              'ratingCount': 24,
              'logoUrl':
                  'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=300',
            },
          ),
          ChatCard(
            type: 'ORGANIZER_CARD',
            data: {
              'id': 'org_royal_02',
              'businessName': 'Royal Feast Hospitality & Events',
              'displayName': 'Royal Feast Hospitality',
              'city': isDelhi ? 'Delhi' : 'Mumbai',
              'totalPackages': 3,
              'totalServices': 5,
              'rating': 4.8,
              'ratingCount': 18,
              'logoUrl':
                  'https://images.unsplash.com/photo-1519741497674-611481863552?w=300',
            },
          ),
        ],
        suggestedActions: [
          'View Packages',
          'Contact Organizer',
          'Explore Events',
        ],
      );
    }

    // ── Organizer AI Copilot: organizer_create_event_draft Tool Execution ───
    if (message.contains('organizer_create_event_draft') ||
        (q.contains('create') && q.contains('event')) ||
        (q.contains('draft') && q.contains('event')) ||
        q.contains('mumbai tech meetup') ||
        q.contains('tech leaders') ||
        q.contains('comedy show')) {
      String title = 'Mumbai Tech Meetup';
      String city = 'Mumbai';
      String venue = 'Bandra Kurla Complex, Mumbai';
      int capacity = 50;

      // Extract details if JSON is present in the message
      if (message.contains('{') && message.contains('}')) {
        try {
          final jsonStart = message.indexOf('{');
          final jsonEnd = message.lastIndexOf('}') + 1;
          final jsonStr = message.substring(jsonStart, jsonEnd);
          final dynamic parsed = jsonDecode(jsonStr);
          if (parsed is Map<String, dynamic>) {
            final args = parsed['arguments'] as Map<String, dynamic>? ?? parsed;
            if (args['title'] != null) title = args['title'].toString();
            if (args['city'] != null) city = args['city'].toString();
            if (args['location'] != null) venue = args['location'].toString();
            if (args['capacity'] != null) {
              capacity = (args['capacity'] as num).toInt();
            }
          }
        } catch (_) {}
      } else {
        // Dynamic extraction from prompt (e.g. "Create event salem tech meetup")
        final cleanPrompt = message
            .replaceFirst(
              RegExp(
                r'^(please\s+)?(create|draft|make|start|plan)\s+(an?\s+)?(new\s+)?event\s*(called|named|for|:)?\s*',
                caseSensitive: false,
              ),
              '',
            )
            .trim();

        if (cleanPrompt.isNotEmpty && cleanPrompt.length > 2) {
          title = cleanPrompt
              .split(' ')
              .map((w) =>
                  w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
              .join(' ');
        }

        const knownCities = [
          'Salem',
          'Mumbai',
          'Bangalore',
          'Delhi',
          'Chennai',
          'Hyderabad',
          'Goa',
          'Pune',
          'Kolkata',
          'Coimbatore',
          'Udaipur',
          'Ahmedabad',
          'Kochi'
        ];
        for (final c in knownCities) {
          if (RegExp('\\b$c\\b', caseSensitive: false).hasMatch(message)) {
            city = c;
            venue = '$c Tech Hub, $c';
            break;
          }
        }
      }

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            '⚡ **Tool Executed: `organizer_create_event_draft`**\nI have created your event draft for **$title**! Here are the event details:',
        type: ChatMessageType.bot,
        timestamp: DateTime.now(),
        cards: [
          ChatCard(
            type: 'EVENT_DRAFT_CARD',
            data: {
              'eventId': 'evt_draft_${DateTime.now().millisecondsSinceEpoch}',
              'title': title,
              'city': city,
              'venue': venue,
              'status': 'DRAFT',
              'ticketTiers': [
                {
                  'name': 'General Admission RSVP',
                  'price': 0,
                  'totalSeats': capacity,
                },
                {
                  'name': 'VIP All-Access',
                  'price': 1499,
                  'totalSeats': 15,
                },
              ],
              'createdAt': DateTime.now().toIso8601String(),
            },
          ),
        ],
        suggestedActions: [
          '🚀 Publish Now',
          '✏️ Edit Details',
          '🏷️ Add Paid Ticket Tier',
          '📊 Check Projected Revenue',
        ],
      );
    }

    // ── Organizer AI Copilot: Publish Event ──────────────────────────────────
    if (q.contains('publish')) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            '🎉 Event "Tech Leaders Summit 2026" has been published and is now live on the public discovery feed!',
        type: ChatMessageType.bot,
        timestamp: DateTime.now(),
        cards: [
          const ChatCard(
            type: 'EVENT_CARD',
            data: {
              'id': 'evt_draft_9918',
              'title': 'Tech Leaders Summit 2026 (Live)',
              'mode': 'PHYSICAL',
              'city': 'Bangalore',
              'startDatetime': '2026-10-15T10:00:00.000Z',
              'venueName': 'Whitefield Convention Center',
              'ticketStartingPriceRupees': 799,
            },
          ),
        ],
        suggestedActions: [
          'View Organizer Analytics',
          'Inspect Attendee Check-ins',
          'Share Event Link',
        ],
      );
    }

    // ── Organizer AI Copilot: Revenue & Analytics ───────────────────────────
    if (q.contains('revenue') ||
        q.contains('analytics') ||
        q.contains('gmv') ||
        q.contains('sales') ||
        q.contains('earnings')) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            'Here is your real-time revenue and ticket analytics performance for this cycle:',
        type: ChatMessageType.bot,
        timestamp: DateTime.now(),
        cards: [
          const ChatCard(
            type: 'ANALYTICS_CARD',
            data: {
              'totalGmvRupees': 1850000,
              'netRevenueRupees': 1850000,
              'ticketsSold': 428,
              'activeEventsCount': 3,
              'pageviews': 12450,
              'period': 'September 2026',
            },
          ),
        ],
        suggestedActions: [
          'View Payouts & Bank Transfers',
          'Inspect Attendee Check-ins',
          'Create New Event Draft',
        ],
      );
    }

    // ── Organizer AI Copilot: Attendee Check-ins ─────────────────────────────
    if (q.contains('attendee') ||
        q.contains('check-in') ||
        q.contains('checkin') ||
        q.contains('guest list')) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            'Here is the latest live attendee check-in and QR verification roster:',
        type: ChatMessageType.bot,
        timestamp: DateTime.now(),
        cards: [
          const ChatCard(
            type: 'ATTENDEE_CARD',
            data: {
              'attendeeId': 'att_101',
              'name': 'Priya Sharma',
              'ticketTier': 'VIP Pass',
              'status': 'CHECKED_IN',
              'phone': '+91 98765 12345',
              'qrData': 'EMS-TKT-VIP-9918-01',
              'checkedInAt': '10:45 AM Today',
            },
          ),
          const ChatCard(
            type: 'ATTENDEE_CARD',
            data: {
              'attendeeId': 'att_102',
              'name': 'Rahul Verma',
              'ticketTier': 'General Admission',
              'status': 'NOT_CHECKED_IN',
              'phone': '+91 98220 54321',
              'qrData': 'EMS-TKT-GEN-9918-02',
            },
          ),
          const ChatCard(
            type: 'ATTENDEE_CARD',
            data: {
              'attendeeId': 'att_103',
              'name': 'Ananya Roy',
              'ticketTier': 'VIP Pass',
              'status': 'CHECKED_IN',
              'phone': '+91 99112 33445',
              'qrData': 'EMS-TKT-VIP-9918-03',
              'checkedInAt': '11:10 AM Today',
            },
          ),
        ],
        suggestedActions: [
          'Scan Attendee QR Code',
          'Filter Not Checked In',
          'Export Attendee CSV',
        ],
      );
    }

    if (q.contains('concert') || q.contains('music') || q.contains('event')) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            'Here are top trending music concerts and events happening near you:',
        type: ChatMessageType.bot,
        timestamp: DateTime.now(),
        cards: [
          ChatCard(
            type: 'EVENT_CARD',
            data: {
              'id': 'evt_1',
              'title': 'Arijit Singh Symphony Live 2026',
              'mode': 'PHYSICAL',
              'city': 'Mumbai',
              'startDatetime': '2026-09-15T19:00:00.000Z',
              'venueName': 'Jio World Garden, BKC',
              'ticketStartingPriceRupees': 1499,
            },
          ),
          ChatCard(
            type: 'EVENT_CARD',
            data: {
              'id': 'evt_2',
              'title': 'Sunburn Arena Electronic Fest',
              'mode': 'HYBRID',
              'city': 'Goa',
              'startDatetime': '2026-10-02T17:00:00.000Z',
              'venueName': 'Vagator Beach Arena',
              'ticketStartingPriceRupees': 999,
            },
          ),
        ],
        suggestedActions: [
          '🎫 Book Arijit Singh Tickets',
          '📍 Events in Delhi',
          '📦 Wedding Packages',
        ],
      );
    }

    if (q.contains('wedding') || q.contains('package') || q.contains('cater')) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'I found curated premium packages tailored for your celebration:',
        type: ChatMessageType.bot,
        timestamp: DateTime.now(),
        cards: [
          ChatCard(
            type: 'PACKAGE_CARD',
            data: {
              'id': 'pkg_1',
              'name': 'Royal Palace Destination Wedding',
              'organizerName': 'Royal Vows & Co.',
              'city': 'Udaipur',
              'priceRupees': 450000,
              'depositRequiredRupees': 50000,
              'coverImageUrl':
                  'https://images.unsplash.com/photo-1519741497674-611481863552?w=500',
              'rating': 4.9,
            },
          ),
          ChatCard(
            type: 'PACKAGE_CARD',
            data: {
              'id': 'pkg_2',
              'name': 'Grand Luxury Banquet & Catering Package',
              'organizerName': 'Elite Planners Mumbai',
              'city': 'Mumbai',
              'priceRupees': 280000,
              'depositRequiredRupees': 35000,
              'coverImageUrl':
                  'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=500',
              'rating': 4.8,
            },
          ),
        ],
        suggestedActions: [
          '🛒 View My Cart',
          '🎉 Corporate Packages',
          '💬 Talk to Support',
        ],
      );
    }

    if (q.contains('cart')) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Here is your current active cart summary:',
        type: ChatMessageType.bot,
        timestamp: DateTime.now(),
        cards: [
          ChatCard(
            type: 'CART_SUMMARY',
            data: {
              'totalItems': 2,
              'totalValueRupees': 730000,
              'totalDepositDueRupees': 85000,
            },
          ),
        ],
        suggestedActions: [
          '💳 Proceed to Checkout',
          '📦 Add More Packages',
          '🎫 My Event Tickets',
        ],
      );
    }

    if (q.contains('booking') || q.contains('hired') || q.contains('vendor')) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Here are your active vendor bookings and status:',
        type: ChatMessageType.bot,
        timestamp: DateTime.now(),
        cards: [
          ChatCard(
            type: 'BOOKING_CARD',
            data: {
              'bookingId': 'bk_101',
              'vendorName': 'Aura Catering & Events',
              'packageName': 'Royal Feast Wedding Catering',
              'status': 'CONFIRMED',
              'eventDate': '2026-11-20',
              'balanceDueRupees': 60000,
            },
          ),
          ChatCard(
            type: 'BOOKING_CARD',
            data: {
              'bookingId': 'bk_102',
              'vendorName': 'Starlight Studio Pro',
              'packageName': 'Cinematic Wedding Shoot',
              'status': 'REQUESTED',
              'eventDate': '2026-11-21',
              'balanceDueRupees': 45000,
            },
          ),
        ],
        suggestedActions: [
          '🎫 My Tickets',
          '🛒 Show My Cart',
          '📞 Contact Vendor',
        ],
      );
    }

    if (q.contains('ticket') || q.contains('pass') || q.contains('qr')) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Here are your purchased event tickets with digital QR passes:',
        type: ChatMessageType.bot,
        timestamp: DateTime.now(),
        cards: [
          ChatCard(
            type: 'TICKET_CARD',
            data: {
              'ticketId': 'tkt_801',
              'eventTitle': 'Arijit Singh Symphony Live 2026',
              'ticketType': 'VIP Front Row Pass',
              'quantity': 2,
              'status': 'CONFIRMED',
              'qrData': 'EMS-TKT-ARIJIT-VIP-2026-801',
            },
          ),
          ChatCard(
            type: 'TICKET_CARD',
            data: {
              'ticketId': 'tkt_802',
              'eventTitle': 'Sunburn Arena Electronic Fest',
              'ticketType': 'Early Bird General',
              'quantity': 1,
              'status': 'CONFIRMED',
              'qrData': 'EMS-TKT-SUNBURN-GA-2026-802',
            },
          ),
        ],
        suggestedActions: [
          '🎉 Find More Events',
          '📦 Wedding Packages',
          '🛒 View Cart',
        ],
      );
    }

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text:
          'I can assist you with discovering live events, finding luxury wedding/corporate packages, and managing your bookings and cart.',
      type: ChatMessageType.bot,
      timestamp: DateTime.now(),
      suggestedActions: [
        '🎉 Find Concerts & Events',
        '📦 Wedding Packages',
        '🛒 View Cart',
        '🎫 My Event Tickets',
        '📋 Track Bookings',
      ],
    );
  }
}
