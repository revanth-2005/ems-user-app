import '../../../auth/domain/entities/user_entity.dart';

// ── Operational Mode ─────────────────────────────────────────────────────────

enum OperationalMode {
  SINGLE_SERVICE,
  MULTI_SERVICE,
  BOTH;

  String get title {
    switch (this) {
      case OperationalMode.SINGLE_SERVICE:
        return 'Individual Service Provider';
      case OperationalMode.MULTI_SERVICE:
        return 'Event Organizer / Planner';
      case OperationalMode.BOTH:
        return 'Both (Services & Packages)';
    }
  }

  String get description {
    switch (this) {
      case OperationalMode.SINGLE_SERVICE:
        return 'Offers standalone services (DJ, Solo Photographer, Anchor)';
      case OperationalMode.MULTI_SERVICE:
        return 'Offers bundled multi-service event packages';
      case OperationalMode.BOTH:
        return 'Offers both standalone services & bundled packages';
    }
  }
}

// ── Subscription Tiers & Quotas ──────────────────────────────────────────────

enum SubscriptionTier {
  BASIC,
  MEDIUM,
  ADVANCED;

  // Aliases for backward compatibility
  static const FREE_TRIAL = SubscriptionTier.BASIC;
  static const PRO = SubscriptionTier.MEDIUM;
  static const ENTERPRISE = SubscriptionTier.ADVANCED;

  String get label {
    switch (this) {
      case SubscriptionTier.BASIC:
        return 'Basic Plan';
      case SubscriptionTier.MEDIUM:
        return 'Medium Plan';
      case SubscriptionTier.ADVANCED:
        return 'Advanced Plan';
    }
  }

  String get priceLabel {
    switch (this) {
      case SubscriptionTier.BASIC:
        return '₹999 / mo';
      case SubscriptionTier.MEDIUM:
        return '₹2,499 / mo';
      case SubscriptionTier.ADVANCED:
        return '₹4,999 / mo';
    }
  }

  int get maxActivePackages {
    switch (this) {
      case SubscriptionTier.BASIC:
        return 3;
      case SubscriptionTier.MEDIUM:
        return 10;
      case SubscriptionTier.ADVANCED:
        return 999;
    }
  }

  int get maxActiveServices {
    switch (this) {
      case SubscriptionTier.BASIC:
        return 5;
      case SubscriptionTier.MEDIUM:
        return 20;
      case SubscriptionTier.ADVANCED:
        return 999;
    }
  }
}

typedef SubscriptionPlan = SubscriptionTier;

// ── Service Pricing Unit ─────────────────────────────────────────────────────

enum ServicePricingUnit {
  FIXED,
  PER_HEAD,
  PER_HOUR;

  String get label {
    switch (this) {
      case ServicePricingUnit.FIXED:
        return 'Flat Fee (Fixed)';
      case ServicePricingUnit.PER_HEAD:
        return 'Per Guest (Per Head)';
      case ServicePricingUnit.PER_HOUR:
        return 'Hourly Rate';
    }
  }

  String get suffix {
    switch (this) {
      case ServicePricingUnit.FIXED:
        return 'total';
      case ServicePricingUnit.PER_HEAD:
        return '/guest';
      case ServicePricingUnit.PER_HOUR:
        return '/hr';
    }
  }
}

// ── Package Line Items ───────────────────────────────────────────────────────

class PackageLineItem {
  final String id;
  final String title;
  final String description;
  final String? quantity;

  const PackageLineItem({
    required this.id,
    required this.title,
    this.description = '',
    this.quantity,
  });

  factory PackageLineItem.fromJson(Map<String, dynamic> json) {
    return PackageLineItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'quantity': quantity,
      };

  PackageLineItem copyWith({
    String? id,
    String? title,
    String? description,
    String? quantity,
  }) {
    return PackageLineItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
    );
  }
}

// ── Organizer Package Model ──────────────────────────────────────────────────

class OrganizerPackage {
  final String id;
  final String name;
  final String category;
  final String? subcategory;
  final String description;
  final int priceInPaise;
  final int advanceDepositPct; // e.g. 20%
  final int minGuests;
  final int maxGuests;
  final String? coverImageUrl;
  final bool isActive;
  final List<PackageLineItem> lineItems;

  const OrganizerPackage({
    required this.id,
    required this.name,
    required this.category,
    this.subcategory,
    required this.description,
    required this.priceInPaise,
    this.advanceDepositPct = 20,
    this.minGuests = 50,
    this.maxGuests = 500,
    this.coverImageUrl,
    this.isActive = true,
    this.lineItems = const [],
  });

  factory OrganizerPackage.fromJson(Map<String, dynamic> json) {
    return OrganizerPackage(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? 'Custom Package',
      category: json['category'] ?? 'Event Package',
      subcategory: json['subcategory'],
      description: json['description'] ?? '',
      priceInPaise: (json['priceInPaise'] ?? json['price_in_paise'] ?? json['price'] ?? 0) as int,
      advanceDepositPct: (json['advanceDepositPct'] ?? json['advance_deposit_pct'] ?? 20) as int,
      minGuests: (json['minGuests'] ?? json['min_guests'] ?? 50) as int,
      maxGuests: (json['maxGuests'] ?? json['max_guests'] ?? 500) as int,
      coverImageUrl: json['coverImageUrl'] ?? json['cover_image_url'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      lineItems: (json['lineItems'] as List<dynamic>?)
              ?.map((e) => PackageLineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'subcategory': subcategory,
        'description': description,
        'priceInPaise': priceInPaise,
        'advanceDepositPct': advanceDepositPct,
        'minGuests': minGuests,
        'maxGuests': maxGuests,
        'coverImageUrl': coverImageUrl,
        'isActive': isActive,
        'lineItems': lineItems.map((e) => e.toJson()).toList(),
      };

  OrganizerPackage copyWith({
    String? id,
    String? name,
    String? category,
    String? subcategory,
    String? description,
    int? priceInPaise,
    int? advanceDepositPct,
    int? minGuests,
    int? maxGuests,
    String? coverImageUrl,
    bool? isActive,
    List<PackageLineItem>? lineItems,
  }) {
    return OrganizerPackage(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      description: description ?? this.description,
      priceInPaise: priceInPaise ?? this.priceInPaise,
      advanceDepositPct: advanceDepositPct ?? this.advanceDepositPct,
      minGuests: minGuests ?? this.minGuests,
      maxGuests: maxGuests ?? this.maxGuests,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isActive: isActive ?? this.isActive,
      lineItems: lineItems ?? this.lineItems,
    );
  }
}

// ── Organizer Standalone Service Model ───────────────────────────────────────

class OrganizerService {
  final String id;
  final String name;
  final String category;
  final String description;
  final int priceInPaise;
  final ServicePricingUnit pricingUnit;
  final int advanceDepositPct;
  final int leadTimeDays;
  final String? coverImageUrl;
  final bool isActive;

  const OrganizerService({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.priceInPaise,
    this.pricingUnit = ServicePricingUnit.FIXED,
    this.advanceDepositPct = 20,
    this.leadTimeDays = 3,
    this.coverImageUrl,
    this.isActive = true,
  });

  factory OrganizerService.fromJson(Map<String, dynamic> json) {
    ServicePricingUnit parseUnit(String? val) {
      if (val == null) return ServicePricingUnit.FIXED;
      for (final u in ServicePricingUnit.values) {
        if (u.name.toUpperCase() == val.toUpperCase()) return u;
      }
      return ServicePricingUnit.FIXED;
    }

    return OrganizerService(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? 'Standalone Service',
      category: json['category'] ?? 'Service',
      description: json['description'] ?? '',
      priceInPaise: (json['priceInPaise'] ?? json['price_in_paise'] ?? json['price'] ?? 0) as int,
      pricingUnit: parseUnit(json['pricingUnit']?.toString() ?? json['pricing_unit']?.toString()),
      advanceDepositPct: (json['advanceDepositPct'] ?? json['advance_deposit_pct'] ?? 20) as int,
      leadTimeDays: (json['leadTimeDays'] ?? json['lead_time_days'] ?? 3) as int,
      coverImageUrl: json['coverImageUrl'] ?? json['cover_image_url'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'description': description,
        'priceInPaise': priceInPaise,
        'pricingUnit': pricingUnit.name,
        'advanceDepositPct': advanceDepositPct,
        'leadTimeDays': leadTimeDays,
        'coverImageUrl': coverImageUrl,
        'isActive': isActive,
      };

  OrganizerService copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    int? priceInPaise,
    ServicePricingUnit? pricingUnit,
    int? advanceDepositPct,
    int? leadTimeDays,
    String? coverImageUrl,
    bool? isActive,
  }) {
    return OrganizerService(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      priceInPaise: priceInPaise ?? this.priceInPaise,
      pricingUnit: pricingUnit ?? this.pricingUnit,
      advanceDepositPct: advanceDepositPct ?? this.advanceDepositPct,
      leadTimeDays: leadTimeDays ?? this.leadTimeDays,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}

// ── Portfolio Media Item ────────────────────────────────────────────────────

class PortfolioMediaItem {
  final String id;
  final String mediaUrl;
  final String caption;
  final int sortOrder;
  final bool isVideo;
  final DateTime? createdAt;

  const PortfolioMediaItem({
    required this.id,
    required this.mediaUrl,
    required this.caption,
    this.sortOrder = 0,
    this.isVideo = false,
    this.createdAt,
  });

  factory PortfolioMediaItem.fromJson(Map<String, dynamic> json) {
    return PortfolioMediaItem(
      id: json['id']?.toString() ?? '',
      mediaUrl: json['mediaUrl'] ?? json['media_url'] ?? '',
      caption: json['caption'] ?? '',
      sortOrder: (json['sortOrder'] ?? json['sort_order'] ?? 0) as int,
      isVideo: json['isVideo'] ?? json['is_video'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaUrl': mediaUrl,
        'caption': caption,
        'sortOrder': sortOrder,
        'isVideo': isVideo,
        'createdAt': createdAt?.toIso8601String(),
      };
}

// ── Complete Organizer Profile Entity ────────────────────────────────────────

class OrganizerProfile {
  final String id;
  final String businessName;
  final String displayName;
  final String bio;
  final String businessType;
  final String city;
  final String contactEmail;
  final String contactPhone;
  final List<String> categories;
  final KycStatus kycStatus;
  final String? rejectionReason;
  final bool isSetupComplete;
  final OperationalMode businessMode;
  final SubscriptionTier plan;
  final double rating;
  final int reviewCount;
  final int totalBookings;
  final int activePackagesCount;
  final int activeServicesCount;
  final String? panGst;
  final String? bankAccount;
  final String? bankIfsc;
  final String? bankAccountHolder;
  final DateTime? submittedAt;
  final String? trackingReference;

  const OrganizerProfile({
    required this.id,
    required this.businessName,
    this.displayName = '',
    this.bio = '',
    required this.businessType,
    required this.city,
    this.contactEmail = '',
    this.contactPhone = '',
    this.categories = const [],
    this.kycStatus = KycStatus.approved,
    this.rejectionReason,
    this.isSetupComplete = true,
    this.businessMode = OperationalMode.BOTH,
    this.plan = SubscriptionTier.MEDIUM,
    this.rating = 4.9,
    this.reviewCount = 42,
    this.totalBookings = 28,
    this.activePackagesCount = 3,
    this.activeServicesCount = 5,
    this.panGst,
    this.bankAccount,
    this.bankIfsc,
    this.bankAccountHolder,
    this.submittedAt,
    this.trackingReference,
  });

  static const empty = OrganizerProfile(
    id: '',
    businessName: '',
    businessType: '',
    city: '',
    kycStatus: KycStatus.none,
    isSetupComplete: false,
  );

  bool get isKycApproved => kycStatus == KycStatus.approved;
  int get activeListings => activePackagesCount + activeServicesCount;
  int get maxActivePackages => plan.maxActivePackages;
  int get maxActiveServices => plan.maxActiveServices;

  factory OrganizerProfile.fromJson(Map<String, dynamic> json) {
    SubscriptionTier parsePlan(String? val) {
      if (val == null) return SubscriptionTier.MEDIUM;
      for (final p in SubscriptionTier.values) {
        if (p.name.toUpperCase() == val.toUpperCase()) return p;
      }
      return SubscriptionTier.MEDIUM;
    }

    OperationalMode parseMode(String? val) {
      if (val == null) return OperationalMode.BOTH;
      for (final m in OperationalMode.values) {
        if (m.name.toUpperCase() == val.toUpperCase()) return m;
      }
      return OperationalMode.BOTH;
    }

    KycStatus parseKyc(dynamic val) {
      if (val == null) return KycStatus.approved;
      final str = val.toString().toUpperCase();
      if (str == 'PENDING' || str == 'UNDER_REVIEW') return KycStatus.pending;
      if (str == 'REJECTED') return KycStatus.rejected;
      if (str == 'APPROVED') return KycStatus.approved;
      if (str == 'SUSPENDED') return KycStatus.suspended;
      if (str == 'NONE') return KycStatus.none;
      return KycStatus.approved;
    }

    return OrganizerProfile(
      id: json['id']?.toString() ?? '',
      businessName: json['businessName'] ?? json['business_name'] ?? json['name'] ?? 'Organizer Studio',
      displayName: json['displayName'] ?? json['display_name'] ?? '',
      bio: json['bio'] ?? '',
      businessType: json['businessType'] ?? json['business_type'] ?? 'Event Planner',
      city: json['city'] ?? 'Coimbatore',
      contactEmail: json['contactEmail'] ?? json['contact_email'] ?? '',
      contactPhone: json['contactPhone'] ?? json['contact_phone'] ?? '',
      categories: (json['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      kycStatus: parseKyc(json['kycStatus'] ?? json['kyc_status']),
      rejectionReason: json['rejectionReason'] ?? json['rejection_reason'],
      isSetupComplete: json['isSetupComplete'] ?? json['is_setup_complete'] ?? true,
      businessMode: parseMode(json['businessMode']?.toString() ?? json['business_mode']?.toString()),
      plan: parsePlan(json['plan']?.toString() ?? json['subscriptionTier']?.toString()),
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      reviewCount: (json['reviewCount'] ?? json['review_count'] ?? 42) as int,
      totalBookings: (json['totalBookings'] ?? json['total_bookings'] ?? 0) as int,
      activePackagesCount: (json['activePackagesCount'] ?? json['active_packages_count'] ?? 3) as int,
      activeServicesCount: (json['activeServicesCount'] ?? json['active_services_count'] ?? 5) as int,
      panGst: json['panGst'] ?? json['pan_gst'],
      bankAccount: json['bankAccount'] ?? json['bank_account'],
      bankIfsc: json['bankIfsc'] ?? json['bank_ifsc'],
      bankAccountHolder: json['bankAccountHolder'] ?? json['bank_account_holder'],
      submittedAt: json['submittedAt'] != null ? DateTime.tryParse(json['submittedAt'].toString()) : null,
      trackingReference: json['trackingReference'] ?? json['tracking_reference'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessName': businessName,
        'displayName': displayName,
        'bio': bio,
        'businessType': businessType,
        'city': city,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'categories': categories,
        'kycStatus': kycStatus.name,
        'rejectionReason': rejectionReason,
        'isSetupComplete': isSetupComplete,
        'businessMode': businessMode.name,
        'plan': plan.name,
        'rating': rating,
        'reviewCount': reviewCount,
        'totalBookings': totalBookings,
        'activePackagesCount': activePackagesCount,
        'activeServicesCount': activeServicesCount,
        'panGst': panGst,
        'bankAccount': bankAccount,
        'bankIfsc': bankIfsc,
        'bankAccountHolder': bankAccountHolder,
        'submittedAt': submittedAt?.toIso8601String(),
        'trackingReference': trackingReference,
      };

  OrganizerProfile copyWith({
    String? id,
    String? businessName,
    String? displayName,
    String? bio,
    String? businessType,
    String? city,
    String? contactEmail,
    String? contactPhone,
    List<String>? categories,
    KycStatus? kycStatus,
    String? rejectionReason,
    bool? isSetupComplete,
    OperationalMode? businessMode,
    SubscriptionTier? plan,
    double? rating,
    int? reviewCount,
    int? totalBookings,
    int? activePackagesCount,
    int? activeServicesCount,
    String? panGst,
    String? bankAccount,
    String? bankIfsc,
    String? bankAccountHolder,
    DateTime? submittedAt,
    String? trackingReference,
  }) {
    return OrganizerProfile(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      businessType: businessType ?? this.businessType,
      city: city ?? this.city,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      categories: categories ?? this.categories,
      kycStatus: kycStatus ?? this.kycStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
      businessMode: businessMode ?? this.businessMode,
      plan: plan ?? this.plan,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      totalBookings: totalBookings ?? this.totalBookings,
      activePackagesCount: activePackagesCount ?? this.activePackagesCount,
      activeServicesCount: activeServicesCount ?? this.activeServicesCount,
      panGst: panGst ?? this.panGst,
      bankAccount: bankAccount ?? this.bankAccount,
      bankIfsc: bankIfsc ?? this.bankIfsc,
      bankAccountHolder: bankAccountHolder ?? this.bankAccountHolder,
      submittedAt: submittedAt ?? this.submittedAt,
      trackingReference: trackingReference ?? this.trackingReference,
    );
  }
}

// ── Payout & Ledger Models ───────────────────────────────────────────────────

class PayoutLedger {
  final int totalEarningsPaise;
  final int pendingPayoutPaise;
  final int availableBalancePaise;
  final List<PayoutTransaction> transactions;

  const PayoutLedger({
    required this.totalEarningsPaise,
    required this.pendingPayoutPaise,
    required this.availableBalancePaise,
    this.transactions = const [],
  });

  factory PayoutLedger.fromJson(Map<String, dynamic> json) {
    return PayoutLedger(
      totalEarningsPaise: (json['totalEarningsPaise'] ?? json['total_earnings_paise'] ?? 0) as int,
      pendingPayoutPaise: (json['pendingPayoutPaise'] ?? json['pending_payout_paise'] ?? 0) as int,
      availableBalancePaise: (json['availableBalancePaise'] ?? json['available_balance_paise'] ?? 0) as int,
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => PayoutTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class PayoutTransaction {
  final String id;
  final String title;
  final DateTime date;
  final int amountPaise;
  final bool isCredit;
  final String? transferId;

  const PayoutTransaction({
    required this.id,
    required this.title,
    required this.date,
    required this.amountPaise,
    this.isCredit = true,
    this.transferId,
  });

  factory PayoutTransaction.fromJson(Map<String, dynamic> json) {
    return PayoutTransaction(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Payout Settlement',
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
      amountPaise: (json['amountPaise'] ?? json['amount_paise'] ?? 0) as int,
      isCredit: json['isCredit'] ?? json['is_credit'] ?? true,
      transferId: json['transferId'] ?? json['transfer_id'] ?? json['utr'],
    );
  }
}

// ── Availability Models ──────────────────────────────────────────────────────

class AvailabilitySlot {
  final DateTime date;
  final bool isBlocked;
  final bool isConfirmedBooking;
  final String? reason;
  final String? bookingTitle;

  const AvailabilitySlot({
    required this.date,
    this.isBlocked = false,
    this.isConfirmedBooking = false,
    this.reason,
    this.bookingTitle,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
      isBlocked: json['isBlocked'] ?? json['is_blocked'] ?? false,
      isConfirmedBooking: json['isConfirmedBooking'] ?? json['is_confirmed_booking'] ?? false,
      reason: json['reason'],
      bookingTitle: json['bookingTitle'] ?? json['booking_title'],
    );
  }

  AvailabilitySlot copyWith({
    DateTime? date,
    bool? isBlocked,
    bool? isConfirmedBooking,
    String? reason,
    String? bookingTitle,
  }) {
    return AvailabilitySlot(
      date: date ?? this.date,
      isBlocked: isBlocked ?? this.isBlocked,
      isConfirmedBooking: isConfirmedBooking ?? this.isConfirmedBooking,
      reason: reason ?? this.reason,
      bookingTitle: bookingTitle ?? this.bookingTitle,
    );
  }
}

// ── Legacy Catalog Item Model (Backwards Compatibility) ──────────────────────

class CatalogItem {
  final String id;
  final String name;
  final String type; // PACKAGE or SERVICE
  final int priceInPaise;
  final bool isActive;
  final String? coverImageUrl;

  const CatalogItem({
    required this.id,
    required this.name,
    required this.type,
    required this.priceInPaise,
    this.isActive = true,
    this.coverImageUrl,
  });

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? 'Item',
      type: json['type'] ?? 'PACKAGE',
      priceInPaise: (json['priceInPaise'] ?? json['price_in_paise'] ?? 0) as int,
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      coverImageUrl: json['coverImageUrl'] ?? json['cover_image_url'],
    );
  }

  CatalogItem copyWith({
    String? id,
    String? name,
    String? type,
    int? priceInPaise,
    bool? isActive,
    String? coverImageUrl,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      priceInPaise: priceInPaise ?? this.priceInPaise,
      isActive: isActive ?? this.isActive,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    );
  }
}
