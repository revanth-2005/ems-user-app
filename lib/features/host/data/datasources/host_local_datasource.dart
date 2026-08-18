import '../../../home/domain/entities/catalog_entities.dart';
import '../../domain/entities/host_entities.dart';

class HostLocalDataSource {
  final List<HostEventItem> _events = [
    HostEventItem(
      id: 'evt_tech_fest_2026',
      title: 'Sunburn Arena: Neon Horizons',
      eventDate: DateTime.now().add(const Duration(days: 5, hours: 18)),
      venue: 'Mahalaxmi Racecourse Arena, Mumbai',
      totalRegistrations: 1420,
      checkedInCount: 680,
      totalCapacity: 2000,
      revenueInPaise: 709858000,
      isLive: true,
      coverImageUrl:
          'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=800&auto=format&fit=crop',
      ticketTiers: const [
        TicketType(
          id: 'tkt_vip_01',
          name: 'VIP Elevated Deck + 2 Drinks',
          priceInPaise: 499900,
          description: 'Access to premium elevated viewing deck.',
          quantity: 45,
        ),
        TicketType(
          id: 'tkt_ga_01',
          name: 'General Admission (Phase 2)',
          priceInPaise: 199900,
          description: 'Standard arena floor access.',
          quantity: 120,
        ),
      ],
    ),
    HostEventItem(
      id: 'evt_design_summit',
      title: 'Apex Global Design & AI Summit',
      eventDate: DateTime.now().add(const Duration(days: 20)),
      venue: 'Jio World Convention Centre, BKC',
      totalRegistrations: 450,
      checkedInCount: 0,
      totalCapacity: 500,
      revenueInPaise: 225000000,
      isLive: true,
      coverImageUrl:
          'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&auto=format&fit=crop',
      ticketTiers: const [
        TicketType(
          id: 'tkt_summit_01',
          name: 'All-Access Pass',
          priceInPaise: 500000,
          description: 'Access to mainstage and workshop rooms.',
          quantity: 50,
        ),
      ],
    ),
  ];

  final Map<String, List<AttendeeRecord>> _attendees = {
    'evt_tech_fest_2026': [
      const AttendeeRecord(
        id: 'att_01',
        attendeeName: 'Rohith Kumar',
        attendeeEmail: 'rohith.kumar@example.com',
        ticketType: 'VIP Elevated Deck + 2 Drinks',
        qrCode: 'ES-PASS-2026-SUNBURN-ROHITH-001',
        isCheckedIn: false,
      ),
      AttendeeRecord(
        id: 'att_02',
        attendeeName: 'Priya Mehta',
        attendeeEmail: 'priya.m@example.com',
        ticketType: 'General Admission (Phase 2)',
        qrCode: 'ES-PASS-2026-SUNBURN-PRIYA-002',
        isCheckedIn: true,
        checkedInAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ],
  };

  List<HostEventItem> getEvents() => List.unmodifiable(_events);

  HostEventItem createEvent(HostEventItem event) {
    _events.insert(0, event);
    _attendees[event.id] = [];
    return event;
  }

  List<AttendeeRecord> getAttendees(String eventId) {
    return List.unmodifiable(_attendees[eventId] ?? []);
  }

  QrCheckInResult scanQrCode(String eventId, String qrData) {
    final list = _attendees[eventId] ?? [];
    final idx = list.indexWhere((a) => a.qrCode == qrData);
    if (idx == -1) {
      return const QrCheckInResult(
        status: CheckInResultStatus.INVALID,
        message: 'QR Code not found in attendee manifest.',
      );
    }

    final attendee = list[idx];
    if (attendee.isCheckedIn) {
      return QrCheckInResult(
        status: CheckInResultStatus.ALREADY_CHECKED_IN,
        attendee: attendee,
        message: 'Ticket was already scanned at ${attendee.checkedInAt}',
      );
    }

    final updated = attendee.copyWith(
      isCheckedIn: true,
      checkedInAt: DateTime.now(),
    );
    list[idx] = updated;

    // Update checkedInCount
    final eventIdx = _events.indexWhere((e) => e.id == eventId);
    if (eventIdx != -1) {
      _events[eventIdx] = _events[eventIdx].copyWith(
        checkedInCount: _events[eventIdx].checkedInCount + 1,
      );
    }

    return QrCheckInResult(
      status: CheckInResultStatus.VALID,
      attendee: updated,
      message: 'Verified Pass: ${updated.attendeeName}',
    );
  }

  bool manualCheckIn(String eventId, String attendeeId) {
    final list = _attendees[eventId] ?? [];
    final idx = list.indexWhere((a) => a.id == attendeeId);
    if (idx != -1 && !list[idx].isCheckedIn) {
      list[idx] = list[idx].copyWith(
        isCheckedIn: true,
        checkedInAt: DateTime.now(),
      );
      return true;
    }
    return false;
  }
}
