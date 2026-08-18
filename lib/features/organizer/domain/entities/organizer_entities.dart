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

  factory OrganizerProfile.fromJson(Map<String, dynamic> json) {
    SubscriptionPlan parsePlan(String? val) {
      if (val == null) return SubscriptionPlan.PRO;
      for (final p in SubscriptionPlan.values) {
        if (p.name.toUpperCase() == val.toUpperCase()) return p;
      }
      return SubscriptionPlan.PRO;
    }

    return OrganizerProfile(
      id: json['id']?.toString() ?? '',
      businessName: json['businessName'] ?? json['business_name'] ?? json['name'] ?? 'Organizer Studio',
      businessType: json['businessType'] ?? json['business_type'] ?? 'Event Planner',
      city: json['city'] ?? 'Coimbatore',
      plan: parsePlan(json['plan']?.toString()),
      isKycApproved: json['isKycApproved'] ?? json['is_kyc_approved'] ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.9,
      totalBookings: (json['totalBookings'] ?? json['total_bookings'] ?? 0) as int,
      activeListings: (json['activeListings'] ?? json['active_listings'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessName': businessName,
        'businessType': businessType,
        'city': city,
        'plan': plan.name,
        'isKycApproved': isKycApproved,
        'rating': rating,
        'totalBookings': totalBookings,
        'activeListings': activeListings,
      };

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

  const PayoutTransaction({
    required this.id,
    required this.title,
    required this.date,
    required this.amountPaise,
    this.isCredit = true,
  });

  factory PayoutTransaction.fromJson(Map<String, dynamic> json) {
    return PayoutTransaction(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Payout Settlement',
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
      amountPaise: (json['amountPaise'] ?? json['amount_paise'] ?? 0) as int,
      isCredit: json['isCredit'] ?? json['is_credit'] ?? true,
    );
  }
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

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
      isBlocked: json['isBlocked'] ?? json['is_blocked'] ?? false,
      reason: json['reason'],
    );
  }

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
