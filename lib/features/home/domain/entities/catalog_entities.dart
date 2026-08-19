// Immutable entities for the Catalog & Discovery feature.

enum PricingUnit { FIXED, PER_HEAD, PER_HOUR }
enum EventMode { ONLINE, OFFLINE }
enum ApprovalMode { INSTANT, APPROVAL_REQUIRED }

// ── SubCategory ─────────────────────────────────────────────────────────────

class SubCategory {
  final String id;
  final String? categoryId;
  final String name;
  final String? slug;
  final String? iconUrl;
  final bool isActive;
  final int sortOrder;

  const SubCategory({
    required this.id,
    this.categoryId,
    required this.name,
    this.slug,
    this.iconUrl,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id']?.toString() ?? '',
      categoryId: json['categoryId']?.toString(),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      iconUrl: json['iconUrl']?.toString(),
      isActive: json['isActive'] == true || json['is_active'] == true,
      sortOrder: (json['sortOrder'] ?? json['sort_order'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (categoryId != null) 'categoryId': categoryId,
        'name': name,
        if (slug != null) 'slug': slug,
        if (iconUrl != null) 'iconUrl': iconUrl,
        'isActive': isActive,
        'sortOrder': sortOrder,
      };
}

// ── Category ────────────────────────────────────────────────────────────────

class Category {
  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final bool isActive;
  final int sortOrder;
  final List<SubCategory> subCategories;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
    this.isActive = true,
    this.sortOrder = 0,
    this.subCategories = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final subCatsList = json['subCategories'] ?? json['sub_categories'];
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString() ?? json['icon_url']?.toString(),
      isActive: json['isActive'] == true || json['is_active'] == true,
      sortOrder: (json['sortOrder'] ?? json['sort_order'] ?? 0) as int,
      subCategories: subCatsList is List
          ? subCatsList
              .map((e) => SubCategory.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        if (iconUrl != null) 'iconUrl': iconUrl,
        'isActive': isActive,
        'sortOrder': sortOrder,
        'subCategories': subCategories.map((e) => e.toJson()).toList(),
      };
}

// ── Organizer Profile & Summary ─────────────────────────────────────────────

class OrganizerUser {
  final String? id;
  final String name;
  final String? email;
  final String? profilePhoto;

  const OrganizerUser({
    this.id,
    required this.name,
    this.email,
    this.profilePhoto,
  });

  factory OrganizerUser.fromJson(Map<String, dynamic> json) {
    return OrganizerUser(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? 'Organizer',
      email: json['email']?.toString(),
      profilePhoto:
          json['profilePhoto']?.toString() ?? json['profile_photo']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        if (email != null) 'email': email,
        if (profilePhoto != null) 'profilePhoto': profilePhoto,
      };
}

class PortfolioItem {
  final String? id;
  final String mediaUrl;
  final String mediaType;
  final String? caption;

  const PortfolioItem({
    this.id,
    required this.mediaUrl,
    this.mediaType = 'image',
    this.caption,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id']?.toString(),
      mediaUrl: json['mediaUrl']?.toString() ??
          json['media_url']?.toString() ??
          '',
      mediaType: json['mediaType']?.toString() ??
          json['media_type']?.toString() ??
          'image',
      caption: json['caption']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        if (caption != null) 'caption': caption,
      };
}

class OrganizerSummary {
  final String id;
  final String businessName;
  final String? displayName;
  final String? bio;
  final String? city;
  final String kycStatus;
  final double rating;
  final String? avatarUrl;
  final OrganizerUser? user;
  final List<PortfolioItem> portfolioItems;
  final int packageCount;
  final int serviceCount;

  const OrganizerSummary({
    required this.id,
    required this.businessName,
    this.displayName,
    this.bio,
    this.city,
    this.kycStatus = 'APPROVED',
    this.rating = 4.8,
    this.avatarUrl,
    this.user,
    this.portfolioItems = const [],
    this.packageCount = 0,
    this.serviceCount = 0,
  });

  String get effectiveName =>
      displayName?.isNotEmpty == true ? displayName! : businessName;

  String? get effectiveAvatar =>
      avatarUrl ?? user?.profilePhoto;

  factory OrganizerSummary.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'] is Map<String, dynamic>
        ? OrganizerUser.fromJson(json['user'] as Map<String, dynamic>)
        : null;

    final portfolio = json['portfolioItems'] is List
        ? (json['portfolioItems'] as List)
            .map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : const <PortfolioItem>[];

    final pkgs = json['packages'] is List ? (json['packages'] as List) : const [];
    final srvs = json['services'] is List ? (json['services'] as List) : const [];

    String? foundAvatar = json['coverImageUrl']?.toString() ??
        json['cover_image_url']?.toString() ??
        json['avatarUrl']?.toString() ??
        json['avatar_url']?.toString() ??
        userObj?.profilePhoto;

    if ((foundAvatar == null || foundAvatar.isEmpty) && pkgs.isNotEmpty) {
      final firstPkg = pkgs.first;
      if (firstPkg is Map<String, dynamic>) {
        foundAvatar = firstPkg['coverImageUrl']?.toString() ??
            firstPkg['cover_image_url']?.toString();
      }
    }

    if ((foundAvatar == null || foundAvatar.isEmpty) && srvs.isNotEmpty) {
      final firstSrv = srvs.first;
      if (firstSrv is Map<String, dynamic>) {
        foundAvatar = firstSrv['coverImageUrl']?.toString() ??
            firstSrv['cover_image_url']?.toString();
      }
    }

    if ((foundAvatar == null || foundAvatar.isEmpty) && portfolio.isNotEmpty) {
      foundAvatar = portfolio.first.mediaUrl;
    }

    return OrganizerSummary(
      id: json['id']?.toString() ?? '',
      businessName: json['businessName']?.toString() ??
          json['business_name']?.toString() ??
          'Organizer',
      displayName:
          json['displayName']?.toString() ?? json['display_name']?.toString(),
      bio: json['bio']?.toString(),
      city: json['city']?.toString(),
      kycStatus: json['kycStatus']?.toString() ??
          json['kyc_status']?.toString() ??
          'APPROVED',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      avatarUrl: foundAvatar,
      user: userObj,
      portfolioItems: portfolio,
      packageCount: pkgs.length,
      serviceCount: srvs.length,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessName': businessName,
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (city != null) 'city': city,
        'kycStatus': kycStatus,
        'rating': rating,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (user != null) 'user': user!.toJson(),
        'portfolioItems': portfolioItems.map((e) => e.toJson()).toList(),
      };
}

// ── LineItem ────────────────────────────────────────────────────────────────

class LineItem {
  final String? id;
  final String title;
  final String? description;
  final int? quantity;
  final int sortOrder;

  const LineItem({
    this.id,
    required this.title,
    this.description,
    this.quantity,
    this.sortOrder = 0,
  });

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      id: json['id']?.toString(),
      title: json['name']?.toString() ?? json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      quantity: json['quantity'] as int?,
      sortOrder: (json['sortOrder'] ?? json['sort_order'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        if (description != null) 'description': description,
        if (quantity != null) 'quantity': quantity,
        'sortOrder': sortOrder,
      };
}

// ── EventPackage / PackageModel ─────────────────────────────────────────────

class EventPackage {
  final String id;
  final String name;
  final String slug;
  final String? coverImageUrl;
  final List<String> galleryImages;
  final String? description;
  final int priceInPaise;
  final int advanceDepositFlat;
  final int? advanceDepositPct;
  final int? maxGuests;
  final int capacityMin;
  final int capacityMax;
  final Category? category;
  final SubCategory? subCategory;
  final OrganizerSummary organizer;
  final List<LineItem> lineItems;
  final String? cancellationPolicy;
  final String? terms;
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
    this.advanceDepositPct,
    this.maxGuests,
    this.capacityMin = 10,
    this.capacityMax = 500,
    this.category,
    this.subCategory,
    required this.organizer,
    this.lineItems = const [],
    this.cancellationPolicy,
    this.terms,
    this.status = 'ACTIVE',
  });

  /// Price in INR rupees = priceInPaise / 100.0
  double get priceInRupees => priceInPaise / 100.0;

  /// Advance deposit in rupees
  double get advanceDepositInRupees => advanceDepositFlat / 100.0;

  /// Effective list of inclusions / line item titles
  List<String> get inclusions =>
      lineItems.map((e) => e.title).where((t) => t.isNotEmpty).toList();

  /// Effective category name
  String get categoryName => category?.name ?? 'Weddings & Events';

  /// Effective organizer name
  String get organizerName => organizer.effectiveName;

  /// Effective city location
  String? get city => organizer.city;

  /// Maximum guests count
  int get effectiveMaxGuests => maxGuests ?? capacityMax;

  factory EventPackage.fromJson(Map<String, dynamic> json) {
    Category? catObj;
    if (json['category'] is Map<String, dynamic>) {
      catObj = Category.fromJson(json['category'] as Map<String, dynamic>);
    } else if (json['categories'] is List && (json['categories'] as List).isNotEmpty) {
      final first = (json['categories'] as List).first;
      if (first is Map<String, dynamic>) catObj = Category.fromJson(first);
    }

    SubCategory? subCatObj;
    if (json['subCategory'] is Map<String, dynamic>) {
      subCatObj = SubCategory.fromJson(json['subCategory'] as Map<String, dynamic>);
    } else if (json['subCategories'] is List && (json['subCategories'] as List).isNotEmpty) {
      final first = (json['subCategories'] as List).first;
      if (first is Map<String, dynamic>) subCatObj = SubCategory.fromJson(first);
    }

    final orgObj = json['organizerProfile'] is Map<String, dynamic>
        ? OrganizerSummary.fromJson(
            json['organizerProfile'] as Map<String, dynamic>)
        : (json['organizer'] is Map<String, dynamic>
            ? OrganizerSummary.fromJson(
                json['organizer'] as Map<String, dynamic>)
            : const OrganizerSummary(
                id: 'org_default', businessName: 'Verified Organizer'));

    final lineItemsList = (json['lineItems'] as List<dynamic>?)
            ?.map((e) => LineItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final rawPrice = json['priceInPaise'] ?? json['price_in_paise'] ?? 0;
    final parsedPrice = rawPrice is num ? rawPrice.toInt() : (int.tryParse(rawPrice.toString()) ?? 0);

    final rawDeposit = json['advanceDepositFlat'] ?? json['advance_deposit_flat'] ?? 0;
    final parsedDeposit = rawDeposit is num ? rawDeposit.toInt() : (int.tryParse(rawDeposit.toString()) ?? 0);

    final gallery = (json['galleryImages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    final rawCover = json['coverImageUrl']?.toString() ??
        json['cover_image_url']?.toString() ??
        (gallery.isNotEmpty ? gallery.first : null);

    return EventPackage(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      coverImageUrl: rawCover,
      galleryImages: gallery,
      description: json['description']?.toString(),
      priceInPaise: parsedPrice,
      advanceDepositFlat: parsedDeposit,
      advanceDepositPct: json['advanceDepositPct'] as int?,
      maxGuests: json['maxGuests'] as int?,
      capacityMin: json['capacityMin'] ?? json['capacity_min'] ?? 10,
      capacityMax: json['capacityMax'] ?? json['capacity_max'] ?? (json['maxGuests'] ?? 500),
      category: catObj,
      subCategory: subCatObj,
      organizer: orgObj,
      lineItems: lineItemsList,
      cancellationPolicy:
          json['cancellationPolicy']?.toString() ?? json['cancellation_policy']?.toString(),
      terms: json['terms']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}

// ── StandaloneService ───────────────────────────────────────────────────────

class StandaloneService {
  final String id;
  final String name;
  final String? slug;
  final String? description;
  final String? coverImageUrl;
  final int priceInPaise;
  final int advanceDepositFlat;
  final int? advanceDepositPct;
  final int leadTimeDays;
  final PricingUnit pricingUnit;
  final Category? category;
  final SubCategory? subCategory;
  final OrganizerSummary organizer;
  final String? terms;
  final String status;

  const StandaloneService({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.coverImageUrl,
    required this.priceInPaise,
    int? depositRequiredPaise,
    int advanceDepositFlat = 0,
    this.advanceDepositPct,
    this.leadTimeDays = 1,
    this.pricingUnit = PricingUnit.FIXED,
    this.category,
    this.subCategory,
    required this.organizer,
    this.terms,
    this.status = 'ACTIVE',
  }) : advanceDepositFlat = depositRequiredPaise ?? advanceDepositFlat;

  /// Deposit required in paise
  int get depositRequiredPaise => advanceDepositFlat;

  /// Price in INR rupees = priceInPaise / 100.0
  double get priceInRupees => priceInPaise / 100.0;

  /// Category name
  String get categoryName => category?.name ?? 'Service';

  /// Organizer display name
  String get organizerName => organizer.effectiveName;

  /// City location
  String? get city => organizer.city;

  /// Formatted Pricing Unit Label (e.g. "/ hr", "/ plate", "flat")
  String get pricingUnitLabel {
    switch (pricingUnit) {
      case PricingUnit.PER_HOUR:
        return 'per hour';
      case PricingUnit.PER_HEAD:
        return 'per guest';
      case PricingUnit.FIXED:
        return 'flat rate';
    }
  }

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

    final catObj = json['category'] is Map<String, dynamic>
        ? Category.fromJson(json['category'] as Map<String, dynamic>)
        : null;

    final subCatObj = json['subCategory'] is Map<String, dynamic>
        ? SubCategory.fromJson(json['subCategory'] as Map<String, dynamic>)
        : null;

    final orgObj = json['organizerProfile'] is Map<String, dynamic>
        ? OrganizerSummary.fromJson(
            json['organizerProfile'] as Map<String, dynamic>)
        : (json['organizer'] is Map<String, dynamic>
            ? OrganizerSummary.fromJson(
                json['organizer'] as Map<String, dynamic>)
            : const OrganizerSummary(
                id: 'org_srv', businessName: 'Specialist Pro'));

    final rawPrice = json['priceInPaise'] ?? json['price_in_paise'] ?? 0;
    final parsedPrice = rawPrice is num ? rawPrice.toInt() : (int.tryParse(rawPrice.toString()) ?? 0);

    final rawDeposit = json['advanceDepositFlat'] ?? json['advance_deposit_flat'] ?? 0;
    final parsedDeposit = rawDeposit is num ? rawDeposit.toInt() : (int.tryParse(rawDeposit.toString()) ?? 0);

    return StandaloneService(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      coverImageUrl:
          json['coverImageUrl']?.toString() ?? json['cover_image_url']?.toString(),
      priceInPaise: parsedPrice,
      advanceDepositFlat: parsedDeposit,
      advanceDepositPct: json['advanceDepositPct'] as int?,
      leadTimeDays: (json['leadTimeDays'] ?? json['lead_time_days'] ?? 1) as int,
      pricingUnit: parseUnit(json['pricingUnit']?.toString() ?? json['pricing_unit']?.toString()),
      category: catObj,
      subCategory: subCatObj,
      organizer: orgObj,
      terms: json['terms']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}

// ── TicketType ──────────────────────────────────────────────────────────────

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
  double get priceInRupees => priceInPaise / 100.0;

  factory TicketType.fromJson(Map<String, dynamic> json) {
    return TicketType(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'General Admission',
      description: json['description']?.toString(),
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
        if (description != null) 'description': description,
        'priceInPaise': priceInPaise,
        'platformFeePaise': platformFeePaise,
        'quantity': quantity,
        'soldCount': soldCount,
      };
}

// ── PublicEvent ─────────────────────────────────────────────────────────────

class PublicEvent {
  final String id;
  final String title;
  final String? slug;
  final String? description;
  final String? coverImageUrl;
  final String? categoryId;
  final Category? category;
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
    this.category,
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

  double get minPriceInRupees => minPricePaise / 100.0;
  double get maxPriceInRupees => maxPricePaise / 100.0;

  factory PublicEvent.fromJson(Map<String, dynamic> json) {
    final hostObj = json['host'] is Map<String, dynamic> ? json['host'] : null;

    final catObj = json['category'] is Map<String, dynamic>
        ? Category.fromJson(json['category'] as Map<String, dynamic>)
        : null;

    final rawMin = json['minPricePaise'] ?? json['min_price_paise'] ?? 0;
    final rawMax = json['maxPricePaise'] ?? json['max_price_paise'] ?? 0;

    return PublicEvent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      coverImageUrl:
          json['coverImageUrl']?.toString() ?? json['cover_image_url']?.toString(),
      categoryId: json['categoryId']?.toString() ?? json['category_id']?.toString(),
      category: catObj,
      mode: (json['mode']?.toString().toUpperCase() == 'ONLINE')
          ? EventMode.ONLINE
          : EventMode.OFFLINE,
      approvalMode:
          (json['approvalMode']?.toString().toUpperCase() == 'APPROVAL_REQUIRED')
              ? ApprovalMode.APPROVAL_REQUIRED
              : ApprovalMode.INSTANT,
      venueName: json['venueName']?.toString() ?? json['venue_name']?.toString(),
      venueAddress:
          json['venueAddress']?.toString() ?? json['venue_address']?.toString(),
      venueCity: json['venueCity']?.toString() ?? json['venue_city']?.toString(),
      meetingUrl: json['meetingUrl']?.toString() ?? json['meeting_url']?.toString(),
      startDatetime: json['startDatetime'] != null
          ? DateTime.tryParse(json['startDatetime']) ?? DateTime.now()
          : DateTime.now().add(const Duration(days: 3)),
      endDatetime: json['endDatetime'] != null
          ? DateTime.tryParse(json['endDatetime']) ?? DateTime.now()
          : DateTime.now().add(const Duration(days: 3, hours: 4)),
      maxCapacity: json['maxCapacity'] ?? json['max_capacity'] ?? 300,
      minPricePaise: rawMin is num ? rawMin.toInt() : (int.tryParse(rawMin.toString()) ?? 0),
      maxPricePaise: rawMax is num ? rawMax.toInt() : (int.tryParse(rawMax.toString()) ?? 0),
      hostName: hostObj?['name'] ??
          json['hostName']?.toString() ??
          json['host_name']?.toString() ??
          'Host Community',
      ticketTypes: (json['ticketTypes'] as List<dynamic>?)
              ?.map((e) => TicketType.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
