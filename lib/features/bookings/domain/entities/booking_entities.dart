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
