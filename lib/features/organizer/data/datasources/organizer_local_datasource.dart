import '../../../home/domain/entities/catalog_entities.dart';
import '../../../bookings/domain/entities/booking_entities.dart';
import '../../domain/entities/organizer_entities.dart';

class OrganizerLocalDataSource {
  OrganizerProfile _profile = const OrganizerProfile(
    id: 'org_aurora',
    businessName: 'Aurora Royal Planners',
    businessType: 'Full Event Planners & Decor',
    city: 'Mumbai',
    plan: SubscriptionPlan.PRO,
    isKycApproved: true,
    rating: 4.9,
    totalBookings: 28,
    activeListings: 6,
  );

  final List<VendorBooking> _inbox = [
    VendorBooking(
      id: 'bk_org_01',
      orderId: 'ORD_940182',
      organizerProfileId: 'org_aurora',
      packageId: 'pkg_royal_wedding',
      title: 'Royal Heritage Wedding Extravaganza',
      eventDate: DateTime.now().add(const Duration(days: 18)),
      status: BookingStatus.REQUESTED,
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
      customerEmail: 'rohith.kumar@example.com',
    ),
    VendorBooking(
      id: 'bk_org_02',
      orderId: 'ORD_940185',
      organizerProfileId: 'org_aurora',
      serviceId: 'srv_cinematic_photo',
      title: 'Cinematic 4K Candid Photography & Teaser',
      eventDate: DateTime.now().add(const Duration(days: 10)),
      status: BookingStatus.ACCEPTED,
      slaDeadline: DateTime.now().add(const Duration(hours: 22)),
      agreedPriceInPaise: 4500000,
      depositPaidPaise: 1500000,
      balanceDuePaise: 3000000,
      organizer: const OrganizerSummary(
        id: 'org_aurora',
        businessName: 'Aurora Royal Planners',
        city: 'Mumbai',
        rating: 4.9,
      ),
      customerName: 'Ananya Sharma',
      customerPhone: '+919811223344',
    ),
  ];

  final List<CatalogItem> _catalog = [
    const CatalogItem(
      id: 'pkg_royal_wedding',
      name: 'Royal Heritage Wedding Extravaganza',
      type: 'PACKAGE',
      priceInPaise: 85000000,
      isActive: true,
      coverImageUrl:
          'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&auto=format&fit=crop',
    ),
    const CatalogItem(
      id: 'srv_cinematic_photo',
      name: 'Cinematic 4K Candid Photography & Teaser',
      type: 'SERVICE',
      priceInPaise: 4500000,
      isActive: true,
      coverImageUrl:
          'https://images.unsplash.com/photo-1537633552985-df8429e8048b?w=800&auto=format&fit=crop',
    ),
  ];

  OrganizerProfile getProfile() => _profile;

  List<VendorBooking> getInbox() => List.unmodifiable(_inbox);

  bool acceptBooking(String bookingId) {
    final idx = _inbox.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      _inbox[idx] = _inbox[idx].copyWith(status: BookingStatus.ACCEPTED);
      return true;
    }
    return false;
  }

  bool rejectBooking(String bookingId) {
    final idx = _inbox.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      _inbox[idx] = _inbox[idx].copyWith(status: BookingStatus.REJECTED);
      return true;
    }
    return false;
  }

  bool proposeReschedule(String bookingId, DateTime newDate, String note) {
    final idx = _inbox.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      _inbox[idx] = _inbox[idx].copyWith(
        status: BookingStatus.RESCHEDULE_PROPOSED,
        proposedDate: newDate,
        rescheduleNote: note,
      );
      return true;
    }
    return false;
  }

  List<CatalogItem> getCatalog() => List.unmodifiable(_catalog);

  bool toggleItemStatus(String itemId) {
    final idx = _catalog.indexWhere((c) => c.id == itemId);
    if (idx != -1) {
      _catalog[idx] = _catalog[idx].copyWith(isActive: !_catalog[idx].isActive);
      return true;
    }
    return false;
  }

  PayoutLedger getPayoutLedger() {
    return PayoutLedger(
      totalEarningsPaise: 48500000,
      pendingPayoutPaise: 15000000,
      availableBalancePaise: 33500000,
      transactions: [
        PayoutTransaction(
          id: 'tx_01',
          title: 'Advance Release: ORD_940182',
          date: DateTime.now().subtract(const Duration(days: 2)),
          amountPaise: 15000000,
          isCredit: true,
        ),
        PayoutTransaction(
          id: 'tx_02',
          title: 'Bank Transfer (HDFC ***4812)',
          date: DateTime.now().subtract(const Duration(days: 5)),
          amountPaise: 25000000,
          isCredit: false,
        ),
      ],
    );
  }

  bool submitKyc(String name, String pan, String bank, String ifsc) {
    _profile = _profile.copyWith(isKycApproved: true, businessName: name);
    return true;
  }
}
