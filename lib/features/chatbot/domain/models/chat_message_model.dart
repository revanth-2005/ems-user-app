// Data models matching POST /chat API response specification.
enum ChatMessageType { user, bot }

// ── Rich Card Types ──────────────────────────────────────────────────────────

class ChatCard {
  /// 'PACKAGE_CARD' | 'EVENT_CARD' | 'CART_SUMMARY' | 'BOOKING_CARD' | 'TICKET_CARD'
  final String type;
  final Map<String, dynamic> data;

  const ChatCard({required this.type, required this.data});

  factory ChatCard.fromJson(Map<String, dynamic> json) {
    return ChatCard(
      type: json['type'] as String? ?? '',
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
    );
  }
}

// ── Typed card data helpers ───────────────────────────────────────────────────

class PackageCardData {
  final String id;
  final String name;
  final String organizerName;
  final String city;
  final int priceRupees;
  final int? depositRequiredRupees;
  final String? coverImageUrl;
  final double? rating;
  final int? ratingCount;

  const PackageCardData({
    required this.id,
    required this.name,
    required this.organizerName,
    required this.city,
    required this.priceRupees,
    this.depositRequiredRupees,
    this.coverImageUrl,
    this.rating,
    this.ratingCount,
  });

  factory PackageCardData.fromMap(Map<String, dynamic> data) {
    final price = data['priceInRupees'] ?? data['priceRupees'] ?? data['price'];
    final deposit = data['depositRequiredInRupees'] ??
        data['depositRequiredRupees'] ??
        data['deposit'];

    return PackageCardData(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      organizerName: data['organizerName']?.toString() ??
          data['vendorName']?.toString() ??
          '',
      city: data['city']?.toString() ?? '',
      priceRupees: (price as num?)?.toInt() ?? 0,
      depositRequiredRupees: (deposit as num?)?.toInt(),
      coverImageUrl: data['coverImageUrl']?.toString() ??
          data['imageUrl']?.toString(),
      rating: (data['rating'] as num?)?.toDouble(),
      ratingCount: (data['ratingCount'] as num?)?.toInt(),
    );
  }
}

class EventCardData {
  final String id;
  final String title;
  final String? mode;
  final String? city;
  final String? startDatetime;
  final String? venueName;
  final int? ticketStartingPriceRupees;

  const EventCardData({
    required this.id,
    required this.title,
    this.mode,
    this.city,
    this.startDatetime,
    this.venueName,
    this.ticketStartingPriceRupees,
  });

  factory EventCardData.fromMap(Map<String, dynamic> data) {
    final price = data['startingPriceInRupees'] ??
        data['ticketStartingPriceRupees'] ??
        data['price'];
    final cityVal = data['venueCity']?.toString() ?? data['city']?.toString();

    return EventCardData(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      mode: data['mode']?.toString(),
      city: cityVal,
      startDatetime: data['startDatetime']?.toString() ??
          data['eventDate']?.toString() ??
          data['date']?.toString(),
      venueName: data['venueName']?.toString() ?? cityVal,
      ticketStartingPriceRupees: (price as num?)?.toInt(),
    );
  }
}

class CartSummaryData {
  final int totalItems;
  final int totalValueRupees;
  final int totalDepositDueRupees;

  const CartSummaryData({
    required this.totalItems,
    required this.totalValueRupees,
    required this.totalDepositDueRupees,
  });

  factory CartSummaryData.fromMap(Map<String, dynamic> data) {
    final items = data['itemCount'] ?? data['totalItems'] ?? 0;
    final totalVal =
        data['subtotalRupees'] ?? data['totalValueRupees'] ?? data['subtotal'] ?? 0;
    final depositVal =
        data['depositRupees'] ?? data['totalDepositDueRupees'] ?? data['deposit'] ?? 0;

    return CartSummaryData(
      totalItems: (items as num?)?.toInt() ?? 0,
      totalValueRupees: (totalVal as num?)?.toInt() ?? 0,
      totalDepositDueRupees: (depositVal as num?)?.toInt() ?? 0,
    );
  }
}

class BookingCardData {
  final String? bookingId;
  final String vendorName;
  final String packageName;
  final String status;
  final String? eventDate;
  final int? balanceDueRupees;

  const BookingCardData({
    this.bookingId,
    required this.vendorName,
    required this.packageName,
    required this.status,
    this.eventDate,
    this.balanceDueRupees,
  });

  factory BookingCardData.fromMap(Map<String, dynamic> data) {
    return BookingCardData(
      bookingId: data['bookingId']?.toString() ?? data['id']?.toString(),
      vendorName: data['vendorName']?.toString() ?? '',
      packageName: data['packageName']?.toString() ?? '',
      status: data['status']?.toString() ?? 'REQUESTED',
      eventDate: data['eventDate']?.toString(),
      balanceDueRupees: (data['balanceDueRupees'] as num?)?.toInt(),
    );
  }
}

class TicketCardData {
  final String? ticketId;
  final String eventTitle;
  final String ticketType;
  final int quantity;
  final String status;
  final String? qrData;

  const TicketCardData({
    this.ticketId,
    required this.eventTitle,
    required this.ticketType,
    required this.quantity,
    required this.status,
    this.qrData,
  });

  factory TicketCardData.fromMap(Map<String, dynamic> data) {
    return TicketCardData(
      ticketId: data['ticketId']?.toString() ?? data['id']?.toString(),
      eventTitle: data['eventTitle']?.toString() ?? '',
      ticketType: data['ticketType']?.toString() ?? 'General Pass',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      status: data['status']?.toString() ?? 'CONFIRMED',
      qrData: data['qrData']?.toString() ?? data['ticketNumber']?.toString(),
    );
  }
}

// ── Chat Message ───────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String text;
  final ChatMessageType type;
  final DateTime timestamp;
  final List<ChatCard>? cards;
  final List<String>? suggestedActions;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
    this.cards,
    this.suggestedActions,
  });
}
