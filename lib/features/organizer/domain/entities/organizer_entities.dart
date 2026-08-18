enum SubscriptionPlan { FREE_TRIAL, PRO, ENTERPRISE }

class OrganizerProfile {
  final String id;
  final String businessName;
  final String businessType;
  final String city;
  final SubscriptionPlan plan;
  final bool isKycApproved;
  final double rating;
  final int totalBookings;
  final int activeListings;

  const OrganizerProfile({
    required this.id,
    required this.businessName,
    required this.businessType,
    required this.city,
    this.plan = SubscriptionPlan.PRO,
    this.isKycApproved = true,
    this.rating = 4.9,
    this.totalBookings = 28,
    this.activeListings = 6,
  });

  OrganizerProfile copyWith({
    String? id,
    String? businessName,
    String? businessType,
    String? city,
    SubscriptionPlan? plan,
    bool? isKycApproved,
    double? rating,
    int? totalBookings,
    int? activeListings,
  }) {
    return OrganizerProfile(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      city: city ?? this.city,
      plan: plan ?? this.plan,
      isKycApproved: isKycApproved ?? this.isKycApproved,
      rating: rating ?? this.rating,
      totalBookings: totalBookings ?? this.totalBookings,
      activeListings: activeListings ?? this.activeListings,
    );
  }
}

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
}

class PayoutTransaction {
  final String id;
  final String title;
  final DateTime date;
  final int amountPaise;
  final bool isCredit;

  const PayoutTransaction({
    required this.id,
    required this.title,
    required this.date,
    required this.amountPaise,
    this.isCredit = true,
  });
}

class AvailabilitySlot {
  final DateTime date;
  final bool isBlocked;
  final String? reason;

  const AvailabilitySlot({
    required this.date,
    this.isBlocked = false,
    this.reason,
  });

  AvailabilitySlot copyWith({
    DateTime? date,
    bool? isBlocked,
    String? reason,
  }) {
    return AvailabilitySlot(
      date: date ?? this.date,
      isBlocked: isBlocked ?? this.isBlocked,
      reason: reason ?? this.reason,
    );
  }
}

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
