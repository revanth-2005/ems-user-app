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

class OrganizerCardData {
  final String id;
  final String businessName;
  final String displayName;
  final String city;
  final int totalPackages;
  final int totalServices;
  final double rating;
  final int ratingCount;
  final String? logoUrl;

  const OrganizerCardData({
    required this.id,
    required this.businessName,
    required this.displayName,
    required this.city,
    required this.totalPackages,
    required this.totalServices,
    required this.rating,
    required this.ratingCount,
    this.logoUrl,
  });

  factory OrganizerCardData.fromMap(Map<String, dynamic> data) {
    return OrganizerCardData(
      id: data['id']?.toString() ?? '',
      businessName: data['businessName']?.toString() ?? '',
      displayName: data['displayName']?.toString() ??
          data['businessName']?.toString() ??
          '',
      city: data['city']?.toString() ?? '',
      totalPackages: (data['totalPackages'] as num?)?.toInt() ?? 0,
      totalServices: (data['totalServices'] as num?)?.toInt() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 4.9,
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      logoUrl: data['logoUrl']?.toString(),
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

// ── Organizer Copilot Card Types ─────────────────────────────────────────────

class TicketTierData {
  final String name;
  final int price;
  final int totalSeats;

  const TicketTierData({
    required this.name,
    required this.price,
    required this.totalSeats,
  });

  factory TicketTierData.fromMap(Map<String, dynamic> data) {
    return TicketTierData(
      name: data['name']?.toString() ?? 'Standard Pass',
      price: (data['price'] as num?)?.toInt() ?? 0,
      totalSeats: (data['totalSeats'] as num?)?.toInt() ?? 0,
    );
  }
}

class EventDraftCardData {
  final String eventId;
  final String title;
  final String city;
  final String venue;
  final String status;
  final List<TicketTierData> ticketTiers;
  final String? createdAt;

  const EventDraftCardData({
    required this.eventId,
    required this.title,
    required this.city,
    required this.venue,
    this.status = 'DRAFT',
    this.ticketTiers = const [],
    this.createdAt,
  });

  factory EventDraftCardData.fromMap(Map<String, dynamic> data) {
    final rawTiers = data['ticketTiers'] as List? ?? [];
    return EventDraftCardData(
      eventId: data['eventId']?.toString() ?? data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      venue: data['venue']?.toString() ?? data['location']?.toString() ?? '',
      status: data['status']?.toString() ?? 'DRAFT',
      ticketTiers: rawTiers
          .whereType<Map<String, dynamic>>()
          .map(TicketTierData.fromMap)
          .toList(),
      createdAt: data['createdAt']?.toString(),
    );
  }
}

class AnalyticsCardData {
  final int totalGmvRupees;
  final int netRevenueRupees;
  final int ticketsSold;
  final int activeEventsCount;
  final int pageviews;
  final String period;

  const AnalyticsCardData({
    required this.totalGmvRupees,
    required this.netRevenueRupees,
    required this.ticketsSold,
    required this.activeEventsCount,
    this.pageviews = 0,
    this.period = 'This Month',
  });

  factory AnalyticsCardData.fromMap(Map<String, dynamic> data) {
    final gmv = data['totalGmvRupees'] ?? data['gmv'] ?? data['totalGmv'] ?? 0;
    final net = data['netRevenueRupees'] ??
        data['netRevenue'] ??
        data['netEarnings'] ??
        0;
    final tickets =
        data['ticketsSold'] ?? data['totalTicketsSold'] ?? data['tickets'] ?? 0;
    final events =
        data['activeEventsCount'] ?? data['activeEvents'] ?? data['events'] ?? 0;
    final views = data['pageviews'] ?? data['views'] ?? 0;
    final per = data['period']?.toString() ?? 'This Month';

    return AnalyticsCardData(
      totalGmvRupees: (gmv as num).toInt(),
      netRevenueRupees: (net as num).toInt(),
      ticketsSold: (tickets as num).toInt(),
      activeEventsCount: (events as num).toInt(),
      pageviews: (views as num).toInt(),
      period: per,
    );
  }
}

class AttendeeCardData {
  final String attendeeId;
  final String name;
  final String ticketTier;
  final String status; // 'CHECKED_IN' or 'NOT_CHECKED_IN'
  final String? qrData;
  final String? phone;
  final String? checkedInAt;

  const AttendeeCardData({
    required this.attendeeId,
    required this.name,
    required this.ticketTier,
    required this.status,
    this.qrData,
    this.phone,
    this.checkedInAt,
  });

  bool get isCheckedIn => status == 'CHECKED_IN';

  factory AttendeeCardData.fromMap(Map<String, dynamic> data) {
    return AttendeeCardData(
      attendeeId: data['attendeeId']?.toString() ?? data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      ticketTier: data['ticketTier']?.toString() ?? 'VIP Pass',
      status: data['status']?.toString() ?? 'NOT_CHECKED_IN',
      qrData: data['qrData']?.toString() ?? data['qrCode']?.toString(),
      phone: data['phone']?.toString(),
      checkedInAt: data['checkedInAt']?.toString(),
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
