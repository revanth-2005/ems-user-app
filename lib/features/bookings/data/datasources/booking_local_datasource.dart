import '../../../home/domain/entities/catalog_entities.dart';
import '../../domain/entities/booking_entities.dart';

class BookingLocalDataSource {
  final List<VendorBooking> _mockBookings = [
    VendorBooking(
      id: 'bk_901',
      orderId: 'ORD_940182',
      organizerProfileId: 'org_aurora',
      packageId: 'pkg_royal_wedding',
      title: 'Royal Heritage Wedding Extravaganza',
      eventDate: DateTime.now().add(const Duration(days: 18)),
      status: BookingStatus.ACCEPTED,
      slaDeadline: DateTime.now().add(const Duration(hours: 14)),
      agreedPriceInPaise: 85000000,
      depositPaidPaise: 15000000,
      balanceDuePaise: 70000000,
      organizer: const OrganizerSummary(
        id: 'org_aurora',
        businessName: 'Aurora Royal Planners',
        city: 'Mumbai',
        rating: 4.9,
      ),
      customerName: 'Rohith Kumar',
      customerPhone: '+919876543210',
    ),
    VendorBooking(
      id: 'bk_902',
      orderId: 'ORD_940183',
      organizerProfileId: 'org_sonic',
      serviceId: 'srv_laser_light_show',
      title: 'Club Grade Moving Beam & Laser FX',
      eventDate: DateTime.now().add(const Duration(days: 25)),
      status: BookingStatus.RESCHEDULE_PROPOSED,
      proposedDate: DateTime.now().add(const Duration(days: 26)),
      rescheduleNote:
          'Our chief laser programmer has a scheduling conflict. Proposing the next evening.',
      slaDeadline: DateTime.now().add(const Duration(hours: 8)),
      agreedPriceInPaise: 2500000,
      depositPaidPaise: 800000,
      balanceDuePaise: 1700000,
      organizer: const OrganizerSummary(
        id: 'org_sonic',
        businessName: 'Sonic Boom Entertainment',
        city: 'Mumbai',
        rating: 4.92,
      ),
      customerName: 'Rohith Kumar',
    ),
  ];

  final List<EventTicketPass> _mockTickets = [
    EventTicketPass(
      id: 'tkt_pass_001',
      eventId: 'evt_tech_fest_2026',
      eventTitle: 'Sunburn Arena: Neon Horizons',
      eventDate: DateTime.now().add(const Duration(days: 5, hours: 18)),
      venueName: 'Mahalaxmi Racecourse Arena, Mumbai',
      ticketTypeName: 'VIP Elevated Deck + 2 Drinks',
      pricePaidPaise: 499900,
      qrCodeData: 'ES-PASS-2026-SUNBURN-ROHITH-001',
      attendeeName: 'Rohith Kumar',
      isCheckedIn: false,
    ),
  ];

  List<VendorBooking> getMyBookings() => List.unmodifiable(_mockBookings);

  List<EventTicketPass> getMyTickets() => List.unmodifiable(_mockTickets);

  bool acceptReschedule(String bookingId) {
    final idx = _mockBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final old = _mockBookings[idx];
      _mockBookings[idx] = old.copyWith(
        eventDate: old.proposedDate ?? old.eventDate,
        status: BookingStatus.ACCEPTED,
        rescheduleNote: null,
      );
      return true;
    }
    return false;
  }

  bool cancelBooking(String bookingId) {
    final idx = _mockBookings.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final old = _mockBookings[idx];
      _mockBookings[idx] = old.copyWith(status: BookingStatus.CANCELLED);
      return true;
    }
    return false;
  }
}
