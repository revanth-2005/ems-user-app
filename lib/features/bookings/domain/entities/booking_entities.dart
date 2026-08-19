import '../../../home/domain/entities/catalog_entities.dart';

enum BookingStatus {
  REQUESTED,
  ACCEPTED,
  RESCHEDULE_PROPOSED,
  CONFIRMED,
  COMPLETED,
  CANCELLED,
  REJECTED
}

class VendorBooking {
  final String id;
  final String orderId;
  final String organizerProfileId;
  final String? packageId;
  final String? serviceId;
  final String title;
  final DateTime eventDate;
  final String startTime;
  final String endTime;
  final BookingStatus status;
  final DateTime slaDeadline;
  final int agreedPriceInPaise;
  final int depositPaidPaise;
  final int balanceDuePaise;
  final OrganizerSummary organizer;
  final DateTime? proposedDate;
  final String? rescheduleNote;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;

  const VendorBooking({
    required this.id,
    required this.orderId,
    required this.organizerProfileId,
    this.packageId,
    this.serviceId,
    required this.title,
    required this.eventDate,
    this.startTime = '18:00',
    this.endTime = '23:00',
    required this.status,
    required this.slaDeadline,
    required this.agreedPriceInPaise,
    required this.depositPaidPaise,
    required this.balanceDuePaise,
    required this.organizer,
    this.proposedDate,
    this.rescheduleNote,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
  });

  VendorBooking copyWith({
    String? id,
    String? orderId,
    String? organizerProfileId,
    String? packageId,
    String? serviceId,
    String? title,
    DateTime? eventDate,
    String? startTime,
    String? endTime,
    BookingStatus? status,
    DateTime? slaDeadline,
    int? agreedPriceInPaise,
    int? depositPaidPaise,
    int? balanceDuePaise,
    OrganizerSummary? organizer,
    DateTime? proposedDate,
    String? rescheduleNote,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) {
    return VendorBooking(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      organizerProfileId: organizerProfileId ?? this.organizerProfileId,
      packageId: packageId ?? this.packageId,
      serviceId: serviceId ?? this.serviceId,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      slaDeadline: slaDeadline ?? this.slaDeadline,
      agreedPriceInPaise: agreedPriceInPaise ?? this.agreedPriceInPaise,
      depositPaidPaise: depositPaidPaise ?? this.depositPaidPaise,
      balanceDuePaise: balanceDuePaise ?? this.balanceDuePaise,
      organizer: organizer ?? this.organizer,
      proposedDate: proposedDate ?? this.proposedDate,
      rescheduleNote: rescheduleNote ?? this.rescheduleNote,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
    );
  }

  factory VendorBooking.fromJson(Map<String, dynamic> json) {
    BookingStatus parseStatus(String? val) {
      if (val == null) return BookingStatus.REQUESTED;
      for (final s in BookingStatus.values) {
        if (s.name.toUpperCase() == val.toUpperCase()) return s;
      }
      return BookingStatus.REQUESTED;
    }

    return VendorBooking(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString() ?? 'ORD',
      organizerProfileId: json['organizerProfileId']?.toString() ?? json['organizer_profile_id']?.toString() ?? 'org',
      packageId: json['packageId']?.toString() ?? json['package_id']?.toString(),
      serviceId: json['serviceId']?.toString() ?? json['service_id']?.toString(),
      title: json['title'] ?? json['itemName'] ?? json['name'] ?? 'Vendor Service',
      eventDate: json['eventDate'] != null ? DateTime.tryParse(json['eventDate'].toString()) ?? DateTime.now() : DateTime.now(),
      startTime: json['startTime'] ?? '18:00',
      endTime: json['endTime'] ?? '23:00',
      status: parseStatus(json['status']?.toString()),
      slaDeadline: json['slaDeadline'] != null ? DateTime.tryParse(json['slaDeadline'].toString()) ?? DateTime.now().add(const Duration(hours: 24)) : DateTime.now().add(const Duration(hours: 24)),
      agreedPriceInPaise: (json['agreedPriceInPaise'] ?? json['priceInPaise'] ?? json['price_in_paise'] ?? 0) as int,
      depositPaidPaise: (json['depositPaidPaise'] ?? json['depositRequiredPaise'] ?? json['deposit_paid_paise'] ?? 0) as int,
      balanceDuePaise: (json['balanceDuePaise'] ?? json['balance_due_paise'] ?? 0) as int,
      organizer: json['organizer'] != null
          ? OrganizerSummary.fromJson(json['organizer'] as Map<String, dynamic>)
          : const OrganizerSummary(id: 'org_1', businessName: 'Premier Vendor'),
      proposedDate: json['proposedDate'] != null ? DateTime.tryParse(json['proposedDate'].toString()) : null,
      rescheduleNote: json['rescheduleNote'],
      customerName: json['customerName'] ?? json['customer_name'],
      customerPhone: json['customerPhone'] ?? json['customer_phone'],
      customerEmail: json['customerEmail'] ?? json['customer_email'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'organizerProfileId': organizerProfileId,
        'packageId': packageId,
        'serviceId': serviceId,
        'title': title,
        'eventDate': eventDate.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'status': status.name,
        'slaDeadline': slaDeadline.toIso8601String(),
        'agreedPriceInPaise': agreedPriceInPaise,
        'depositPaidPaise': depositPaidPaise,
        'balanceDuePaise': balanceDuePaise,
        'organizer': organizer.toJson(),
      };
}

class EventTicketPass {
  final String id;
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final String venueName;
  final String ticketTypeName;
  final int pricePaidPaise;
  final String qrCodeData;
  final String attendeeName;
  final bool isCheckedIn;

  const EventTicketPass({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.venueName,
    required this.ticketTypeName,
    required this.pricePaidPaise,
    required this.qrCodeData,
    required this.attendeeName,
    this.isCheckedIn = false,
  });

  factory EventTicketPass.fromJson(Map<String, dynamic> json) {
    return EventTicketPass(
      id: json['id']?.toString() ?? '',
      eventId: json['eventId']?.toString() ?? json['event_id']?.toString() ?? '',
      eventTitle: json['eventTitle'] ?? json['event_title'] ?? json['title'] ?? 'Event Pass',
      eventDate: json['eventDate'] != null ? DateTime.tryParse(json['eventDate'].toString()) ?? DateTime.now() : DateTime.now(),
      venueName: json['venueName'] ?? json['venue_name'] ?? json['venue'] ?? 'City Arena',
      ticketTypeName: json['ticketTypeName'] ?? json['ticket_type'] ?? 'General Access',
      pricePaidPaise: (json['pricePaidPaise'] ?? json['price_paid_paise'] ?? json['priceInPaise'] ?? 0) as int,
      qrCodeData: json['qrCodeData'] ?? json['qrCode'] ?? json['qr_code'] ?? 'EMS-PASS-${json['id']}',
      attendeeName: json['attendeeName'] ?? json['attendee_name'] ?? 'Attendee',
      isCheckedIn: json['isCheckedIn'] ?? json['is_checked_in'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'eventId': eventId,
        'eventTitle': eventTitle,
        'eventDate': eventDate.toIso8601String(),
        'venueName': venueName,
        'ticketTypeName': ticketTypeName,
        'pricePaidPaise': pricePaidPaise,
        'qrCodeData': qrCodeData,
        'attendeeName': attendeeName,
        'isCheckedIn': isCheckedIn,
      };
}

class CartItem {
  final String id;
  final String? packageId;
  final String? serviceId;
  final DateTime eventDate;
  final String startTime;
  final String endTime;
  final int quantity;
  final int priceInPaise;
  final int depositRequiredPaise;
  final int balanceDuePaise;
  final String itemName;
  final String? coverImageUrl;
  final OrganizerSummary organizer;

  const CartItem({
    required this.id,
    this.packageId,
    this.serviceId,
    required this.eventDate,
    this.startTime = '18:00',
    this.endTime = '23:00',
    this.quantity = 1,
    required this.priceInPaise,
    required this.depositRequiredPaise,
    required this.balanceDuePaise,
    required this.itemName,
    this.coverImageUrl,
    required this.organizer,
  });

  CartItem copyWith({
    String? id,
    String? packageId,
    String? serviceId,
    DateTime? eventDate,
    String? startTime,
    String? endTime,
    int? quantity,
    int? priceInPaise,
    int? depositRequiredPaise,
    int? balanceDuePaise,
    String? itemName,
    String? coverImageUrl,
    OrganizerSummary? organizer,
  }) {
    return CartItem(
      id: id ?? this.id,
      packageId: packageId ?? this.packageId,
      serviceId: serviceId ?? this.serviceId,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      quantity: quantity ?? this.quantity,
      priceInPaise: priceInPaise ?? this.priceInPaise,
      depositRequiredPaise: depositRequiredPaise ?? this.depositRequiredPaise,
      balanceDuePaise: balanceDuePaise ?? this.balanceDuePaise,
      itemName: itemName ?? this.itemName,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      organizer: organizer ?? this.organizer,
    );
  }
}

class CartState {
  final List<CartItem> items;
  final String? appliedCoupon;
  final int discountPaise;

  const CartState({
    this.items = const [],
    this.appliedCoupon,
    this.discountPaise = 0,
  });

  int get subtotalPaise =>
      items.fold(0, (sum, i) => sum + (i.priceInPaise * i.quantity));

  int get totalDepositPaise =>
      items.fold(0, (sum, i) => sum + (i.depositRequiredPaise * i.quantity));

  int get totalBalanceDuePaise =>
      items.fold(0, (sum, i) => sum + (i.balanceDuePaise * i.quantity));

  int get finalPayablePaise =>
      (totalDepositPaise - discountPaise).clamp(0, double.maxFinite.toInt());

  CartState copyWith({
    List<CartItem>? items,
    String? appliedCoupon,
    int? discountPaise,
  }) {
    return CartState(
      items: items ?? this.items,
      appliedCoupon: appliedCoupon ?? this.appliedCoupon,
      discountPaise: discountPaise ?? this.discountPaise,
    );
  }
}
