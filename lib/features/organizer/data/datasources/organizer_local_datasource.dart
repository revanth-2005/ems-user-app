import 'dart:math';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../bookings/domain/entities/booking_entities.dart';
import '../../../home/domain/entities/catalog_entities.dart';
import '../../domain/entities/organizer_entities.dart';

class QuotaExceededException implements Exception {
  final String message;
  final int currentActive;
  final int limit;
  QuotaExceededException(this.message, {required this.currentActive, required this.limit});
  @override
  String toString() => message;
}

class OrganizerLocalDataSource {
  OrganizerProfile _profile = OrganizerProfile(
    id: 'org_aurora',
    businessName: 'Aura Event Studios',
    displayName: 'Aura Events & Co.',
    bio: 'Premier luxury wedding, corporate & cultural event curators since 2018.',
    businessType: 'Event Planner & Decor',
    city: 'Mumbai',
    contactEmail: 'contact@auraevents.in',
    contactPhone: '+91 98765 43210',
    categories: const ['Wedding Planners', 'Decorators', 'Catering', 'DJ & Sound'],
    kycStatus: KycStatus.approved,
    isSetupComplete: true,
    businessMode: OperationalMode.BOTH,
    plan: SubscriptionTier.MEDIUM,
    rating: 4.9,
    reviewCount: 42,
    totalBookings: 28,
    activePackagesCount: 3,
    activeServicesCount: 5,
    panGst: '27AABCU9603R1ZM',
    bankAccount: '5020004819281',
    bankIfsc: 'HDFC0000128',
    bankAccountHolder: 'Aura Event Studios LLP',
    submittedAt: DateTime.now().subtract(const Duration(days: 45)),
    trackingReference: 'EMS-KYC-84920',
  );

  final List<OrganizerPackage> _packages = [
    OrganizerPackage(
      id: 'pkg_royal_wedding',
      name: 'Royal Heritage Wedding Extravaganza',
      category: 'Wedding Planners',
      subcategory: 'Full-Service Luxury',
      description: 'End-to-end luxury wedding planning including bridal stage decor, 200 PAX royal feast buffet, candid 4K photography crew, and sound/DJ setup.',
      priceInPaise: 85000000, // ₹8,50,000
      advanceDepositPct: 20,
      minGuests: 150,
      maxGuests: 600,
      isActive: true,
      coverImageUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&auto=format&fit=crop',
      lineItems: const [
        PackageLineItem(id: 'li_1', title: 'Grand Floral Mandap & Entry Arch', description: 'Fresh exotic orchids & roses'),
        PackageLineItem(id: 'li_2', title: 'Royal Feast Buffet (Catering)', description: '30+ items multi-cuisine menu for 250 PAX', quantity: '250 PAX'),
        PackageLineItem(id: 'li_3', title: 'Cinematic 4K Photography & Drone', description: '3 photographers, 2 cinematographers, drone coverage'),
        PackageLineItem(id: 'li_4', title: 'Sound & Concert Lighting with DJ', description: 'Line array JBL setup, smoke & cold pyro effects', quantity: '6 Hours'),
      ],
    ),
    OrganizerPackage(
      id: 'pkg_corp_summit',
      name: 'Corporate Leadership Gala & Tech Stage',
      category: 'Corporate Events',
      subcategory: 'Stage & AV Production',
      description: 'Modern corporate summit setup with P3 LED video wall, digital podium, multi-channel lapel audio, and high-tea executive banquet.',
      priceInPaise: 32000000, // ₹3,20,000
      advanceDepositPct: 25,
      minGuests: 50,
      maxGuests: 300,
      isActive: true,
      coverImageUrl: 'https://images.unsplash.com/photo-1511578314322-379afb476865?w=800&auto=format&fit=crop',
      lineItems: const [
        PackageLineItem(id: 'li_c1', title: 'P3 Ultra HD Curved LED Video Wall', description: '24ft x 10ft with seamless switcher and media server'),
        PackageLineItem(id: 'li_c2', title: 'Stage Sound & Wireless Microphones', description: 'Sennheiser digital lapels & podium goose-neck mics'),
        PackageLineItem(id: 'li_c3', title: 'Executive High-Tea & Canape Service', description: 'Artisan sandwiches, petit fours & barista station', quantity: '150 PAX'),
      ],
    ),
    OrganizerPackage(
      id: 'pkg_cocktail_night',
      name: 'Sangeet & Cocktail Glow Night',
      category: 'Decorators',
      subcategory: 'Theme & Entertainment',
      description: 'Futuristic neon party decor with ambient kinetic tube lighting, interactive bar counters, and celebrity Bollywood DJ performance.',
      priceInPaise: 24000000, // ₹2,40,000
      advanceDepositPct: 30,
      minGuests: 100,
      maxGuests: 400,
      isActive: true,
      coverImageUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&auto=format&fit=crop',
      lineItems: const [
        PackageLineItem(id: 'li_s1', title: 'Interactive RGB Kinetic Light Ceiling', description: 'Programmable synchronized DMX tubes'),
        PackageLineItem(id: 'li_s2', title: 'Bollywood Celebrity DJ & Live Percussion', description: '5-hour high energy party set', quantity: '5 Hours'),
      ],
    ),
    OrganizerPackage(
      id: 'pkg_intimate_haldi',
      name: 'Marigold Bohemian Haldi & Mehendi Setup',
      category: 'Decorators',
      subcategory: 'Intimate Functions',
      description: 'Vibrant marigold photobooth, seating lounges, floral jewelry corner, and traditional folk music performers.',
      priceInPaise: 11000000, // ₹1,10,000
      advanceDepositPct: 20,
      minGuests: 30,
      maxGuests: 120,
      isActive: false, // Inactive / Draft package
      coverImageUrl: 'https://images.unsplash.com/photo-1583939003579-730e3918a45a?w=800&auto=format&fit=crop',
      lineItems: const [
        PackageLineItem(id: 'li_h1', title: 'Genda Phool Floral Backdrop & Urli', description: 'Brass urli with rose petals and marigold curtains'),
        PackageLineItem(id: 'li_h2', title: 'Low Floor Diwan Seating with Bolsters', description: 'Color-blocked boho cushions and canopies'),
      ],
    ),
  ];

  final List<OrganizerService> _services = [
    const OrganizerService(
      id: 'srv_dj_set',
      name: 'Club & Bollywood DJ 4-Hour Live Set',
      category: 'DJ & Sound',
      description: 'Professional club DJ with extensive Bollywood, Punjabi, and House music library. Includes controller and live remixing.',
      priceInPaise: 3500000, // ₹35,000
      pricingUnit: ServicePricingUnit.PER_HOUR,
      advanceDepositPct: 25,
      leadTimeDays: 2,
      isActive: true,
      coverImageUrl: 'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800&auto=format&fit=crop',
    ),
    const OrganizerService(
      id: 'srv_candid_photo',
      name: 'Candid Wedding Photography & Highlights Reel',
      category: 'Photography',
      description: 'Award-winning candid photographer capturing intimate moments in high-dynamic-range RAW. Delivered with a 3-minute 4K highlight teaser.',
      priceInPaise: 5500000, // ₹55,000
      pricingUnit: ServicePricingUnit.FIXED,
      advanceDepositPct: 20,
      leadTimeDays: 4,
      isActive: true,
      coverImageUrl: 'https://images.unsplash.com/photo-1537633552985-df8429e8048b?w=800&auto=format&fit=crop',
    ),
    const OrganizerService(
      id: 'srv_gourmet_buffet',
      name: 'Royal Nawabi Gourmet Dining Buffet',
      category: 'Catering',
      description: 'Live counters featuring Lucknowi Dum Biryani, Galouti Kebabs, Wood-fired Pizza, and artisanal dessert boutique.',
      priceInPaise: 145000, // ₹1,450 per head
      pricingUnit: ServicePricingUnit.PER_HEAD,
      advanceDepositPct: 30,
      leadTimeDays: 5,
      isActive: true,
      coverImageUrl: 'https://images.unsplash.com/photo-1555244162-803834f70033?w=800&auto=format&fit=crop',
    ),
    const OrganizerService(
      id: 'srv_cold_pyro',
      name: 'Indoor Cold Pyro & Low-Fog Cloud Entry',
      category: 'Effects & Staging',
      description: 'Smoke-free, sparkless dry ice cloud effect with 6 cold pyro spark fountains for couple entry or celebration cake cutting.',
      priceInPaise: 2200000, // ₹22,000
      pricingUnit: ServicePricingUnit.FIXED,
      advanceDepositPct: 20,
      leadTimeDays: 1,
      isActive: true,
      coverImageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&auto=format&fit=crop',
    ),
    const OrganizerService(
      id: 'srv_anchor_emcee',
      name: 'Celebrity Multilingual Anchor / Emcee',
      category: 'Anchor & Emcee',
      description: 'Bilingual host (English/Hindi) experienced in entertaining crowd games, sangeet choreographies, and formal awards hosting.',
      priceInPaise: 3000000, // ₹30,000
      pricingUnit: ServicePricingUnit.FIXED,
      advanceDepositPct: 25,
      leadTimeDays: 3,
      isActive: true,
      coverImageUrl: 'https://images.unsplash.com/photo-1475721027785-f74eccf877e2?w=800&auto=format&fit=crop',
    ),
    const OrganizerService(
      id: 'srv_drone_shoot',
      name: 'Aerial FPV Drone 4K Cinematography',
      category: 'Photography',
      description: 'High-speed FPV and cinematic drone pilot capturing breathtaking panoramic venue and procession shots.',
      priceInPaise: 2800000, // ₹28,000
      pricingUnit: ServicePricingUnit.FIXED,
      advanceDepositPct: 20,
      leadTimeDays: 2,
      isActive: false, // Inactive
      coverImageUrl: 'https://images.unsplash.com/photo-1508614589041-895b88991e3e?w=800&auto=format&fit=crop',
    ),
  ];

  final List<PortfolioMediaItem> _portfolio = [
    PortfolioMediaItem(
      id: 'pf_1',
      mediaUrl: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800&auto=format&fit=crop',
      caption: 'Palace wedding mandap with 50,000 fresh marigolds and brass lamps.',
      sortOrder: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    PortfolioMediaItem(
      id: 'pf_2',
      mediaUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=800&auto=format&fit=crop',
      caption: 'Neon Sangeet concert stage with custom laser choreography.',
      sortOrder: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    PortfolioMediaItem(
      id: 'pf_3',
      mediaUrl: 'https://images.unsplash.com/photo-1511578314322-379afb476865?w=800&auto=format&fit=crop',
      caption: 'Annual Global Fintech Summit setup for 800 international delegates.',
      sortOrder: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
    ),
    PortfolioMediaItem(
      id: 'pf_4',
      mediaUrl: 'https://images.unsplash.com/photo-1555244162-803834f70033?w=800&auto=format&fit=crop',
      caption: 'Live artisan culinary stations at Sunset Bay Resort.',
      sortOrder: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 42)),
    ),
  ];

  final List<VendorBooking> _inbox = [
    VendorBooking(
      id: 'bk_org_01',
      orderId: 'ORD_940182',
      organizerProfileId: 'org_aurora',
      packageId: 'pkg_royal_wedding',
      title: 'Royal Heritage Wedding Extravaganza',
      eventDate: DateTime.now().add(const Duration(days: 18)),
      status: BookingStatus.REQUESTED,
      slaDeadline: DateTime.now().add(const Duration(hours: 14, minutes: 22)),
      agreedPriceInPaise: 85000000,
      depositPaidPaise: 17000000,
      balanceDuePaise: 68000000,
      organizer: const OrganizerSummary(
        id: 'org_aurora',
        businessName: 'Aura Event Studios',
        city: 'Mumbai',
        rating: 4.9,
      ),
      customerName: 'Rohith & Preeti Wedding',
      customerPhone: '+91 98765 43210',
      customerEmail: 'rohith.kumar@example.com',
    ),
    VendorBooking(
      id: 'bk_org_02',
      orderId: 'ORD_940185',
      organizerProfileId: 'org_aurora',
      serviceId: 'srv_dj_set',
      title: 'Club & Bollywood DJ 4-Hour Live Set',
      eventDate: DateTime.now().add(const Duration(days: 6)),
      status: BookingStatus.REQUESTED,
      slaDeadline: DateTime.now().add(const Duration(hours: 8, minutes: 45)),
      agreedPriceInPaise: 3500000,
      depositPaidPaise: 875000,
      balanceDuePaise: 2625000,
      organizer: const OrganizerSummary(
        id: 'org_aurora',
        businessName: 'Aura Event Studios',
        city: 'Mumbai',
        rating: 4.9,
      ),
      customerName: 'Aman Singhal (Sangeet)',
      customerPhone: '+91 98112 23344',
      customerEmail: 'aman.singhal@example.com',
    ),
    VendorBooking(
      id: 'bk_org_03',
      orderId: 'ORD_940188',
      organizerProfileId: 'org_aurora',
      packageId: 'pkg_corp_summit',
      title: 'Corporate Leadership Gala & Tech Stage',
      eventDate: DateTime.now().add(const Duration(days: 28)),
      status: BookingStatus.REQUESTED,
      slaDeadline: DateTime.now().add(const Duration(hours: 21, minutes: 10)),
      agreedPriceInPaise: 32000000,
      depositPaidPaise: 8000000,
      balanceDuePaise: 24000000,
      organizer: const OrganizerSummary(
        id: 'org_aurora',
        businessName: 'Aura Event Studios',
        city: 'Mumbai',
        rating: 4.9,
      ),
      customerName: 'Zylker Technologies Annual Meet',
      customerPhone: '+91 99887 76655',
      customerEmail: 'events@zylker.io',
    ),
    VendorBooking(
      id: 'bk_org_04',
      orderId: 'ORD_939921',
      organizerProfileId: 'org_aurora',
      serviceId: 'srv_candid_photo',
      title: 'Candid Wedding Photography & Highlights Reel',
      eventDate: DateTime.now().add(const Duration(days: 12)),
      status: BookingStatus.ACCEPTED,
      slaDeadline: DateTime.now().subtract(const Duration(hours: 3)),
      agreedPriceInPaise: 5500000,
      depositPaidPaise: 1100000,
      balanceDuePaise: 4400000,
      organizer: const OrganizerSummary(
        id: 'org_aurora',
        businessName: 'Aura Event Studios',
        city: 'Mumbai',
        rating: 4.9,
      ),
      customerName: 'Pooja Hegde & Sameer',
      customerPhone: '+91 97654 32190',
      customerEmail: 'pooja.hegde@example.com',
    ),
    VendorBooking(
      id: 'bk_org_05',
      orderId: 'ORD_938104',
      organizerProfileId: 'org_aurora',
      packageId: 'pkg_cocktail_night',
      title: 'Sangeet & Cocktail Glow Night',
      eventDate: DateTime.now().subtract(const Duration(days: 5)),
      status: BookingStatus.COMPLETED,
      slaDeadline: DateTime.now().subtract(const Duration(days: 6)),
      agreedPriceInPaise: 24000000,
      depositPaidPaise: 7200000,
      balanceDuePaise: 0,
      organizer: const OrganizerSummary(
        id: 'org_aurora',
        businessName: 'Aura Event Studios',
        city: 'Mumbai',
        rating: 4.9,
      ),
      customerName: 'Vikram & Sneha Reception',
      customerPhone: '+91 98234 56789',
      customerEmail: 'vikram.m@example.com',
    ),
  ];

  final Map<String, String> _blockedDates = {
    // YYYY-MM-DD -> Reason
  };

  OrganizerProfile getProfile() => _profile;

  void updateProfile(OrganizerProfile profile) {
    _profile = profile;
  }

  void setKycStatus(KycStatus status, {String? reason, bool? isSetupComplete}) {
    _profile = _profile.copyWith(
      kycStatus: status,
      rejectionReason: reason,
      isSetupComplete: isSetupComplete ??
          (status == KycStatus.approved ? _profile.isSetupComplete : false),
    );
  }

  OrganizerProfile submitKyc({
    required String businessName,
    String displayName = '',
    String bio = '',
    String city = 'Mumbai',
    String contactEmail = '',
    String contactPhone = '',
    List<String> categories = const ['Wedding Planners'],
    required String panGst,
    required String bankAccount,
    required String ifsc,
    String accountHolder = '',
  }) {
    final tracking = 'EMS-KYC-${10000 + Random().nextInt(89999)}';
    _profile = _profile.copyWith(
      businessName: businessName,
      displayName: displayName,
      bio: bio,
      city: city,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      categories: categories,
      panGst: panGst,
      bankAccount: bankAccount,
      bankIfsc: ifsc,
      bankAccountHolder: accountHolder,
      kycStatus: KycStatus.pending,
      submittedAt: DateTime.now(),
      trackingReference: tracking,
      rejectionReason: null,
    );
    return _profile;
  }

  OrganizerProfile resubmitKyc({
    required String businessName,
    required String panGst,
    required String bankAccount,
    required String ifsc,
    required String accountHolder,
  }) {
    _profile = _profile.copyWith(
      businessName: businessName,
      panGst: panGst,
      bankAccount: bankAccount,
      bankIfsc: ifsc,
      bankAccountHolder: accountHolder,
      kycStatus: KycStatus.pending,
      submittedAt: DateTime.now(),
      rejectionReason: null,
    );
    return _profile;
  }

  OrganizerProfile setOperationalMode(OperationalMode mode) {
    _profile = _profile.copyWith(businessMode: mode);
    return _profile;
  }

  OrganizerProfile selectSubscriptionTier(SubscriptionTier tier) {
    _profile = _profile.copyWith(
      plan: tier,
      isSetupComplete: true,
      kycStatus: KycStatus.approved,
    );
    return _profile;
  }

  // ── Packages Management ───────────────────────────────────────────────────

  List<OrganizerPackage> getPackages() => List.unmodifiable(_packages);

  OrganizerPackage createPackage(OrganizerPackage pkg) {
    _packages.add(pkg);
    _syncActiveCounts();
    return pkg;
  }

  OrganizerPackage updatePackage(OrganizerPackage pkg) {
    final idx = _packages.indexWhere((p) => p.id == pkg.id);
    if (idx != -1) {
      _packages[idx] = pkg;
      _syncActiveCounts();
      return pkg;
    }
    return pkg;
  }

  bool togglePackageStatus(String id) {
    final idx = _packages.indexWhere((p) => p.id == id);
    if (idx == -1) return false;

    final target = _packages[idx];
    if (!target.isActive) {
      // Activating: verify quota limit
      final currentActive = _packages.where((p) => p.isActive).length;
      if (currentActive >= _profile.maxActivePackages) {
        throw QuotaExceededException(
          'Plan limit reached (${_profile.maxActivePackages} active packages allowed on ${_profile.plan.label}). Upgrade your plan or deactivate another package.',
          currentActive: currentActive,
          limit: _profile.maxActivePackages,
        );
      }
    }

    _packages[idx] = target.copyWith(isActive: !target.isActive);
    _syncActiveCounts();
    return true;
  }

  // ── Services Management ───────────────────────────────────────────────────

  List<OrganizerService> getServices() => List.unmodifiable(_services);

  OrganizerService createService(OrganizerService srv) {
    _services.add(srv);
    _syncActiveCounts();
    return srv;
  }

  OrganizerService updateService(OrganizerService srv) {
    final idx = _services.indexWhere((s) => s.id == srv.id);
    if (idx != -1) {
      _services[idx] = srv;
      _syncActiveCounts();
      return srv;
    }
    return srv;
  }

  bool toggleServiceStatus(String id) {
    final idx = _services.indexWhere((s) => s.id == id);
    if (idx == -1) return false;

    final target = _services[idx];
    if (!target.isActive) {
      // Activating: verify quota limit
      final currentActive = _services.where((s) => s.isActive).length;
      if (currentActive >= _profile.maxActiveServices) {
        throw QuotaExceededException(
          'Plan limit reached (${_profile.maxActiveServices} active services allowed on ${_profile.plan.label}). Upgrade your plan or deactivate another service.',
          currentActive: currentActive,
          limit: _profile.maxActiveServices,
        );
      }
    }

    _services[idx] = target.copyWith(isActive: !target.isActive);
    _syncActiveCounts();
    return true;
  }

  void _syncActiveCounts() {
    _profile = _profile.copyWith(
      activePackagesCount: _packages.where((p) => p.isActive).length,
      activeServicesCount: _services.where((s) => s.isActive).length,
    );
  }

  // ── Portfolio Management ──────────────────────────────────────────────────

  List<PortfolioMediaItem> getPortfolio() => List.unmodifiable(_portfolio);

  PortfolioMediaItem addPortfolioMedia(PortfolioMediaItem item) {
    _portfolio.insert(0, item);
    return item;
  }

  bool deletePortfolioMedia(String id) {
    final lenBefore = _portfolio.length;
    _portfolio.removeWhere((p) => p.id == id);
    return _portfolio.length < lenBefore;
  }

  // ── Bookings & SLA ────────────────────────────────────────────────────────

  List<VendorBooking> getInbox() => List.unmodifiable(_inbox);

  bool acceptBooking(String bookingId) {
    final idx = _inbox.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      final booking = _inbox[idx];
      _inbox[idx] = booking.copyWith(status: BookingStatus.ACCEPTED);
      // Auto-block the confirmed event date in calendar
      final dateStr = booking.eventDate.toIso8601String().split('T')[0];
      _blockedDates[dateStr] = 'Confirmed Event: ${booking.title}';
      return true;
    }
    return false;
  }

  bool rejectBooking(String bookingId, {String? reason}) {
    final idx = _inbox.indexWhere((b) => b.id == bookingId);
    if (idx != -1) {
      _inbox[idx] = _inbox[idx].copyWith(
        status: BookingStatus.REJECTED,
        rescheduleNote: reason ?? 'Organizer unavailable on selected date',
      );
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

  // ── Availability Calendar ─────────────────────────────────────────────────

  List<AvailabilitySlot> getAvailability(DateTime month) {
    final slots = <AvailabilitySlot>[];
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final dateStr = date.toIso8601String().split('T')[0];

      // Check if there is an accepted booking on this date
      final acceptedBooking = _inbox.firstWhere(
        (b) =>
            b.status == BookingStatus.ACCEPTED &&
            b.eventDate.year == date.year &&
            b.eventDate.month == date.month &&
            b.eventDate.day == date.day,
        orElse: () => _emptyBooking(),
      );

      final hasBooking = acceptedBooking.id.isNotEmpty;
      final isManuallyBlocked = _blockedDates.containsKey(dateStr) && !hasBooking;

      slots.add(
        AvailabilitySlot(
          date: date,
          isBlocked: hasBooking || isManuallyBlocked,
          isConfirmedBooking: hasBooking,
          reason: hasBooking
              ? 'Confirmed Event: ${acceptedBooking.title}'
              : _blockedDates[dateStr],
          bookingTitle: hasBooking ? acceptedBooking.title : null,
        ),
      );
    }
    return slots;
  }

  VendorBooking _emptyBooking() {
    return VendorBooking(
      id: '',
      orderId: '',
      organizerProfileId: '',
      title: '',
      eventDate: DateTime(2000),
      status: BookingStatus.CANCELLED,
      slaDeadline: DateTime(2000),
      agreedPriceInPaise: 0,
      depositPaidPaise: 0,
      balanceDuePaise: 0,
      organizer: const OrganizerSummary(id: '', businessName: '', city: ''),
      customerName: '',
    );
  }

  bool toggleDateBlocked(DateTime date, {String? reason}) {
    final dateStr = date.toIso8601String().split('T')[0];
    if (_blockedDates.containsKey(dateStr)) {
      _blockedDates.remove(dateStr);
    } else {
      _blockedDates[dateStr] = reason ?? 'Manually blocked by organizer';
    }
    return true;
  }

  // ── Payout Ledger ─────────────────────────────────────────────────────────

  PayoutLedger getPayoutLedger() {
    return PayoutLedger(
      totalEarningsPaise: 185000000, // ₹1,85,000 (This Month)
      pendingPayoutPaise: 38000000,   // ₹38,000 in escrow
      availableBalancePaise: 147000000, // ₹1,47,000 available
      transactions: [
        PayoutTransaction(
          id: 'tx_01',
          title: 'Advance Release: Rohith Wedding (ORD_940182)',
          date: DateTime.now().subtract(const Duration(days: 2)),
          amountPaise: 17000000,
          isCredit: true,
          transferId: 'rzp_tr_941029104',
        ),
        PayoutTransaction(
          id: 'tx_02',
          title: 'Direct Bank Settlement (HDFC ***4812)',
          date: DateTime.now().subtract(const Duration(days: 5)),
          amountPaise: 85000000,
          isCredit: false,
          transferId: 'rzp_payout_819203910',
        ),
        PayoutTransaction(
          id: 'tx_03',
          title: 'Full Settlement: Vikram Reception (ORD_938104)',
          date: DateTime.now().subtract(const Duration(days: 9)),
          amountPaise: 24000000,
          isCredit: true,
          transferId: 'rzp_tr_831092841',
        ),
        PayoutTransaction(
          id: 'tx_04',
          title: 'Advance Release: Pooja Hegde Shoot (ORD_939921)',
          date: DateTime.now().subtract(const Duration(days: 14)),
          amountPaise: 11000000,
          isCredit: true,
          transferId: 'rzp_tr_771920194',
        ),
      ],
    );
  }

  // ── Backward-compatible CatalogItem List ───────────────────────────────────

  List<CatalogItem> getCatalog() {
    final list = <CatalogItem>[];
    for (final p in _packages) {
      list.add(
        CatalogItem(
          id: p.id,
          name: p.name,
          type: 'PACKAGE',
          priceInPaise: p.priceInPaise,
          isActive: p.isActive,
          coverImageUrl: p.coverImageUrl,
        ),
      );
    }
    for (final s in _services) {
      list.add(
        CatalogItem(
          id: s.id,
          name: s.name,
          type: 'SERVICE',
          priceInPaise: s.priceInPaise,
          isActive: s.isActive,
          coverImageUrl: s.coverImageUrl,
        ),
      );
    }
    return list;
  }

  bool toggleItemStatus(String itemId) {
    if (_packages.any((p) => p.id == itemId)) {
      return togglePackageStatus(itemId);
    }
    if (_services.any((s) => s.id == itemId)) {
      return toggleServiceStatus(itemId);
    }
    return false;
  }
}
