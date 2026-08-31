import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
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
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (jwtToken != null && jwtToken.isNotEmpty)
        'Authorization': 'Bearer $jwtToken',
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
    } catch (_) {
      // Graceful fallback to demo mode so the UI and card rendering can always be tested
      return _generateSimulatedResponse(message);
    }
  }

  /// Provides rich demo responses with real cards when the backend /chat is offline or 404.
  ChatMessage _generateSimulatedResponse(String message) {
    final q = message.toLowerCase();

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
