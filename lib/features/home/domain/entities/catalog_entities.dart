// Immutable entities for the Catalog & Home feature.

enum PricingUnit { FIXED, PER_HEAD, PER_HOUR }
enum EventMode { ONLINE, OFFLINE }
enum ApprovalMode { INSTANT, APPROVAL_REQUIRED }

class SubCategory {
  final String id;
  final String name;

  const SubCategory({required this.id, required this.name});

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Category {
  final String id;
  final String name;
  final String slug;
  final List<SubCategory> subCategories;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.subCategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      subCategories: (json['subCategories'] as List<dynamic>?)
              ?.map((e) => SubCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'subCategories': subCategories.map((e) => e.toJson()).toList(),
      };
}

class OrganizerSummary {
  final String id;
  final String businessName;
  final String? displayName;
  final String? city;
  final double rating;
  final String? avatarUrl;

  const OrganizerSummary({
    required this.id,
    required this.businessName,
    this.displayName,
    this.city,
    this.rating = 4.8,
    this.avatarUrl,
  });

  factory OrganizerSummary.fromJson(Map<String, dynamic> json) {
    return OrganizerSummary(
      id: json['id'] ?? '',
      businessName: json['businessName'] ?? json['business_name'] ?? 'Organizer',
      displayName: json['displayName'] ?? json['display_name'],
      city: json['city'],
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessName': businessName,
        'displayName': displayName,
        'city': city,
        'rating': rating,
        'avatarUrl': avatarUrl,
      };
}

class LineItem {
  final String title;
  final String? description;
  final int? quantity;

  const LineItem({required this.title, this.description, this.quantity});

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      title: json['title'] ?? '',
      description: json['description'],
      quantity: json['quantity'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'quantity': quantity,
      };
}

class EventPackage {
  final String id;
  final String name;
  final String slug;
  final String? coverImageUrl;
  final List<String> galleryImages;
  final String? description;
  final int priceInPaise;
  final int advanceDepositFlat;
  final int capacityMin;
  final int capacityMax;
  final OrganizerSummary organizer;
  final List<LineItem> lineItems;
  final String? cancellationPolicy;
  final String status;

  const EventPackage({
    required this.id,
    required this.name,
    required this.slug,
    this.coverImageUrl,
    this.galleryImages = const [],
    this.description,
    required this.priceInPaise,
    required this.advanceDepositFlat,
    this.capacityMin = 10,
    this.capacityMax = 500,
    required this.organizer,
    this.lineItems = const [],
    this.cancellationPolicy,
    this.status = 'ACTIVE',
  });

  factory EventPackage.fromJson(Map<String, dynamic> json) {
    return EventPackage(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      coverImageUrl: json['coverImageUrl'] ?? json['cover_image_url'],
      galleryImages: (json['galleryImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      description: json['description'],
      priceInPaise: json['priceInPaise'] ?? json['price_in_paise'] ?? 0,
      advanceDepositFlat:
          json['advanceDepositFlat'] ?? json['advance_deposit_flat'] ?? 0,
      capacityMin: json['capacityMin'] ?? json['capacity_min'] ?? 10,
      capacityMax: json['capacityMax'] ?? json['capacity_max'] ?? 500,
      organizer: json['organizer'] != null
          ? OrganizerSummary.fromJson(json['organizer'])
          : const OrganizerSummary(
              id: 'org_default', businessName: 'Premier Studios'),
      lineItems: (json['lineItems'] as List<dynamic>?)
              ?.map((e) => LineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      cancellationPolicy:
          json['cancellationPolicy'] ?? json['cancellation_policy'],
      status: json['status'] ?? 'ACTIVE',
    );
  }
}

class StandaloneService {
  final String id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final int priceInPaise;
  final int depositRequiredPaise;
  final PricingUnit pricingUnit;
  final OrganizerSummary organizer;
  final String status;

  const StandaloneService({
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
    required this.priceInPaise,
    required this.depositRequiredPaise,
    this.pricingUnit = PricingUnit.FIXED,
    required this.organizer,
    this.status = 'ACTIVE',
  });

  factory StandaloneService.fromJson(Map<String, dynamic> json) {
    PricingUnit parseUnit(String? unit) {
      switch (unit?.toUpperCase()) {
        case 'PER_HEAD':
          return PricingUnit.PER_HEAD;
        case 'PER_HOUR':
          return PricingUnit.PER_HOUR;
        default:
          return PricingUnit.FIXED;
      }
    }

    return StandaloneService(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      coverImageUrl: json['coverImageUrl'] ?? json['cover_image_url'],
      priceInPaise: json['priceInPaise'] ?? json['price_in_paise'] ?? 0,
      depositRequiredPaise: json['depositRequiredPaise'] ??
          json['deposit_required_paise'] ??
          ((json['priceInPaise'] ?? 0) ~/ 4),
      pricingUnit: parseUnit(json['pricingUnit'] ?? json['pricing_unit']),
      organizer: json['organizer'] != null
          ? OrganizerSummary.fromJson(json['organizer'])
          : const OrganizerSummary(
              id: 'org_srv', businessName: 'Specialist Pro'),
      status: json['status'] ?? 'ACTIVE',
    );
  }
}

class TicketType {
  final String id;
  final String name;
  final String? description;
  final int priceInPaise;
  final int platformFeePaise;
  final int quantity;
  final int soldCount;

  const TicketType({
    required this.id,
    required this.name,
    this.description,
    required this.priceInPaise,
    this.platformFeePaise = 0,
    required this.quantity,
    this.soldCount = 0,
  });

  bool get isFree => priceInPaise == 0;

  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      id: json['id'] ?? '',
      name: json['name'] ?? 'General Admission',
      description: json['description'],
      priceInPaise: json['priceInPaise'] ?? json['price_in_paise'] ?? 0,
      platformFeePaise:
          json['platformFeePaise'] ?? json['platform_fee_paise'] ?? 0,
      quantity: json['quantity'] ?? 100,
      soldCount: json['soldCount'] ?? json['sold_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'priceInPaise': priceInPaise,
        'platformFeePaise': platformFeePaise,
        'quantity': quantity,
      };
}

class PublicEvent {
  final String id;
  final String title;
  final String? slug;
  final String? description;
  final String? coverImageUrl;
  final String? categoryId;
  final EventMode mode;
  final ApprovalMode approvalMode;
  final String? venueName;
  final String? venueAddress;
  final String? venueCity;
  final String? meetingUrl;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final int maxCapacity;
  final int minPricePaise;
  final int maxPricePaise;
  final String hostName;
  final List<TicketType> ticketTypes;

  const PublicEvent({
    required this.id,
    required this.title,
    this.slug,
    this.description,
    this.coverImageUrl,
    this.categoryId,
    this.mode = EventMode.OFFLINE,
    this.approvalMode = ApprovalMode.INSTANT,
    this.venueName,
    this.venueAddress,
    this.venueCity,
    this.meetingUrl,
    required this.startDatetime,
    required this.endDatetime,
    this.maxCapacity = 300,
    this.minPricePaise = 0,
    this.maxPricePaise = 0,
    this.hostName = 'Host Community',
    this.ticketTypes = const [],
  });

  factory PublicEvent.fromJson(Map<String, dynamic> json) {
    return PublicEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'],
      description: json['description'],
      coverImageUrl: json['coverImageUrl'] ?? json['cover_image_url'],
      categoryId: json['categoryId'] ?? json['category_id'],
      mode: (json['mode']?.toString().toUpperCase() == 'ONLINE')
          ? EventMode.ONLINE
          : EventMode.OFFLINE,
      approvalMode:
          (json['approvalMode']?.toString().toUpperCase() == 'APPROVAL_REQUIRED')
              ? ApprovalMode.APPROVAL_REQUIRED
              : ApprovalMode.INSTANT,
      venueName: json['venueName'] ?? json['venue_name'],
      venueAddress: json['venueAddress'] ?? json['venue_address'],
      venueCity: json['venueCity'] ?? json['venue_city'],
      meetingUrl: json['meetingUrl'] ?? json['meeting_url'],
      startDatetime: json['startDatetime'] != null
          ? DateTime.tryParse(json['startDatetime']) ?? DateTime.now()
          : DateTime.now().add(const Duration(days: 3)),
      endDatetime: json['endDatetime'] != null
          ? DateTime.tryParse(json['endDatetime']) ?? DateTime.now()
          : DateTime.now().add(const Duration(days: 3, hours: 4)),
      maxCapacity: json['maxCapacity'] ?? json['max_capacity'] ?? 300,
      minPricePaise: json['minPricePaise'] ?? json['min_price_paise'] ?? 0,
      maxPricePaise: json['maxPricePaise'] ?? json['max_price_paise'] ?? 0,
      hostName: json['hostName'] ?? json['host_name'] ?? 'Host Community',
      ticketTypes: (json['ticketTypes'] as List<dynamic>?)
              ?.map((e) => TicketType.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
