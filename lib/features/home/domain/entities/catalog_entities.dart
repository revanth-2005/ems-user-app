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
  final int sortOrder;

  const PortfolioItem({
    this.id,
    required this.mediaUrl,
    this.mediaType = 'image',
    this.caption,
    this.sortOrder = 0,
  });

  bool get isVideo {
    if (mediaType.toLowerCase() == 'video') return true;
    final clean = mediaUrl.toLowerCase().split('?').first;
    return clean.endsWith('.mp4') ||
        clean.endsWith('.mov') ||
        clean.endsWith('.webm') ||
        clean.endsWith('.mkv') ||
        clean.endsWith('.m3u8');
  }

  bool get isImage => !isVideo;

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
      sortOrder: (json['sortOrder'] ?? json['sort_order'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        if (caption != null) 'caption': caption,
        'sortOrder': sortOrder,
      };
}

class OrganizerSummary {
  final String id;
  final String businessName;
  final String? displayName;
  final String? bio;
  final String? city;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String kycStatus;
  final double rating;
  final int reviewCount;
  final String? avatarUrl;
  final OrganizerUser? user;
  final List<PortfolioItem> portfolioItems;
  final int packageCount;
  final int serviceCount;
  final bool isFollowed;
  final int followerCount;
  final int bookingCount;
  final double? distanceKm;
  final int? priorityScore;

  const OrganizerSummary({
    required this.id,
    required this.businessName,
    this.displayName,
    this.bio,
    this.city,
    this.address,
    this.latitude,
    this.longitude,
    this.kycStatus = 'APPROVED',
    this.rating = 4.8,
    this.reviewCount = 0,
    this.avatarUrl,
    this.user,
    this.portfolioItems = const [],
    this.packageCount = 0,
    this.serviceCount = 0,
    this.isFollowed = false,
    this.followerCount = 0,
    this.bookingCount = 0,
    this.distanceKm,
    this.priorityScore,
  });

  String get effectiveName =>
      displayName?.isNotEmpty == true ? displayName! : businessName;

  String? get effectiveAvatar =>
      avatarUrl ?? user?.profilePhoto;

  OrganizerSummary copyWith({
    String? id,
    String? businessName,
    String? displayName,
    String? bio,
    String? city,
    String? address,
    double? latitude,
    double? longitude,
    String? kycStatus,
    double? rating,
    int? reviewCount,
    String? avatarUrl,
    OrganizerUser? user,
    List<PortfolioItem>? portfolioItems,
    int? packageCount,
    int? serviceCount,
    bool? isFollowed,
    int? followerCount,
    int? bookingCount,
    double? distanceKm,
    int? priorityScore,
  }) {
    return OrganizerSummary(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      kycStatus: kycStatus ?? this.kycStatus,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      user: user ?? this.user,
      portfolioItems: portfolioItems ?? this.portfolioItems,
      packageCount: packageCount ?? this.packageCount,
      serviceCount: serviceCount ?? this.serviceCount,
      isFollowed: isFollowed ?? this.isFollowed,
      followerCount: followerCount ?? this.followerCount,
      bookingCount: bookingCount ?? this.bookingCount,
      distanceKm: distanceKm ?? this.distanceKm,
      priorityScore: priorityScore ?? this.priorityScore,
    );
  }

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
        json['profilePhoto']?.toString() ??
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

    final rawRating = json['avgRating'] ?? json['rating'];

    return OrganizerSummary(
      id: json['id']?.toString() ?? '',
      businessName: json['businessName']?.toString() ??
          json['business_name']?.toString() ??
          'Organizer',
      displayName:
          json['displayName']?.toString() ?? json['display_name']?.toString(),
      bio: json['bio']?.toString(),
      city: json['city']?.toString(),
      address: json['address']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ??
          (json['lat'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble() ??
          (json['lng'] as num?)?.toDouble(),
      kycStatus: json['kycStatus']?.toString() ??
          json['kyc_status']?.toString() ??
          'APPROVED',
      rating: (rawRating as num?)?.toDouble() ?? 4.8,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      avatarUrl: foundAvatar,
      user: userObj,
      portfolioItems: portfolio,
      packageCount: pkgs.length,
      serviceCount: srvs.length,
      isFollowed: json['isFollowed'] == true || json['is_followed'] == true,
      followerCount: (json['followerCount'] as num?)?.toInt() ??
          (json['followers'] as num?)?.toInt() ??
          0,
      bookingCount: (json['bookingCount'] as num?)?.toInt() ??
          (json['bookings'] as num?)?.toInt() ??
          0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ??
          (json['distance'] as num?)?.toDouble(),
      priorityScore: (json['priorityScore'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'businessName': businessName,
        if (displayName != null) 'displayName': displayName,
        if (bio != null) 'bio': bio,
        if (city != null) 'city': city,
        if (address != null) 'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'kycStatus': kycStatus,
        'rating': rating,
        'reviewCount': reviewCount,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (user != null) 'user': user!.toJson(),
        'portfolioItems': portfolioItems.map((e) => e.toJson()).toList(),
        'isFollowed': isFollowed,
        'followerCount': followerCount,
        'bookingCount': bookingCount,
        if (distanceKm != null) 'distanceKm': distanceKm,
        if (priorityScore != null) 'priorityScore': priorityScore,
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
  final List<PortfolioItem> mediaItems;
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
    this.mediaItems = const [],
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

    final rawMedia = json['mediaUrls'] ?? json['media_urls'] ?? json['galleryImages'] ?? json['gallery_images'];
    final List<PortfolioItem> mediaList = [];
    final List<String> galleryList = [];

    if (rawMedia is List) {
      for (final item in rawMedia) {
        if (item is Map<String, dynamic>) {
          final pItem = PortfolioItem.fromJson(item);
          mediaList.add(pItem);
          galleryList.add(pItem.mediaUrl);
        } else if (item is String && item.isNotEmpty) {
          final isVid = item.toLowerCase().endsWith('.mp4') || item.toLowerCase().endsWith('.mov');
          mediaList.add(PortfolioItem(
            mediaUrl: item,
            mediaType: isVid ? 'video' : 'image',
          ));
          galleryList.add(item);
        }
      }
    }

    var rawCover = json['coverImageUrl']?.toString() ??
        json['cover_image_url']?.toString();
    if ((rawCover == null || rawCover.isEmpty) && galleryList.isNotEmpty) {
      rawCover = galleryList.first;
    }

    return EventPackage(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      coverImageUrl: rawCover,
      mediaItems: mediaList,
      galleryImages: galleryList,
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
  final List<PortfolioItem> mediaItems;
  final List<String> galleryImages;
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
    this.mediaItems = const [],
    this.galleryImages = const [],
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

    final rawMedia = json['mediaUrls'] ?? json['media_urls'] ?? json['galleryImages'] ?? json['gallery_images'];
    final List<PortfolioItem> mediaList = [];
    final List<String> galleryList = [];

    if (rawMedia is List) {
      for (final item in rawMedia) {
        if (item is Map<String, dynamic>) {
          final pItem = PortfolioItem.fromJson(item);
          mediaList.add(pItem);
          galleryList.add(pItem.mediaUrl);
        } else if (item is String && item.isNotEmpty) {
          final isVid = item.toLowerCase().endsWith('.mp4') || item.toLowerCase().endsWith('.mov');
          mediaList.add(PortfolioItem(
            mediaUrl: item,
            mediaType: isVid ? 'video' : 'image',
          ));
          galleryList.add(item);
        }
      }
    }

    var rawCover = json['coverImageUrl']?.toString() ??
        json['cover_image_url']?.toString();
    if ((rawCover == null || rawCover.isEmpty) && galleryList.isNotEmpty) {
      rawCover = galleryList.first;
    }

    return StandaloneService(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      coverImageUrl: rawCover,
      mediaItems: mediaList,
      galleryImages: galleryList,
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

// ── EventCategory (GET /master/event-categories) ────────────────────────────

class EventCategory {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final String? iconUrl;
  final bool isActive;
  final int sortOrder;
  final int eventCount;

  const EventCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    this.iconUrl,
    this.isActive = true,
    this.sortOrder = 0,
    this.eventCount = 0,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    int count = 0;
    if (json['_count'] is Map<String, dynamic>) {
      count = json['_count']['events'] as int? ?? 0;
    } else if (json['eventCount'] != null) {
      count = (json['eventCount'] as num).toInt();
    }

    return EventCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      icon: json['icon']?.toString(),
      iconUrl: json['iconUrl']?.toString() ?? json['icon_url']?.toString(),
      isActive: json['isActive'] == true || json['is_active'] == true,
      sortOrder: (json['sortOrder'] ?? json['sort_order'] ?? 0) as int,
      eventCount: count,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
        if (iconUrl != null) 'iconUrl': iconUrl,
        'isActive': isActive,
        'sortOrder': sortOrder,
      };
}

// ── FeeBreakdownModel (Dynamic Fee & Tax Breakdown) ─────────────────────────

class FeeBreakdownModel {
  final double ticketPrice;
  final double gstRate;
  final double gstAmount;
  final double ticketPriceWithGst;
  final double convenienceFee;
  final double convenienceFeeGst;
  final double totalConvenienceFee;
  final double totalAmountPaidByBuyer;
  final double? organizerPayout;
  final double? adminRevenue;

  const FeeBreakdownModel({
    required this.ticketPrice,
    required this.gstRate,
    required this.gstAmount,
    this.ticketPriceWithGst = 0,
    required this.convenienceFee,
    this.convenienceFeeGst = 0,
    required this.totalConvenienceFee,
    required this.totalAmountPaidByBuyer,
    this.organizerPayout,
    this.adminRevenue,
  });

  factory FeeBreakdownModel.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    final ticketPrice = parseNum(json['ticketPrice'] ?? json['ticketSellingPrice'] ?? json['basePrice']);
    final gstRate = parseNum(json['gstRate'] ?? json['gstPercentage'], 18.0);
    final gstAmount = parseNum(json['gstAmount'] ?? json['ticketGst']);
    final ticketPriceWithGst = parseNum(json['ticketPriceWithGst'], ticketPrice + gstAmount);
    final convenienceFee = parseNum(json['convenienceFee'] ?? json['platformCommission']);
    final convenienceFeeGst = parseNum(json['convenienceFeeGst'] ?? json['commissionTax']);
    final totalConvenienceFee = parseNum(json['totalConvenienceFee'], convenienceFee + convenienceFeeGst);
    final totalAmountPaidByBuyer = parseNum(json['totalAmountPaidByBuyer'], ticketPriceWithGst + totalConvenienceFee);

    return FeeBreakdownModel(
      ticketPrice: ticketPrice,
      gstRate: gstRate,
      gstAmount: gstAmount,
      ticketPriceWithGst: ticketPriceWithGst,
      convenienceFee: convenienceFee,
      convenienceFeeGst: convenienceFeeGst,
      totalConvenienceFee: totalConvenienceFee,
      totalAmountPaidByBuyer: totalAmountPaidByBuyer,
      organizerPayout: parseNum(json['organizerPayout']),
      adminRevenue: parseNum(json['adminRevenue']),
    );
  }

  Map<String, dynamic> toJson() => {
        'ticketPrice': ticketPrice,
        'gstRate': gstRate,
        'gstAmount': gstAmount,
        'ticketPriceWithGst': ticketPriceWithGst,
        'convenienceFee': convenienceFee,
        'convenienceFeeGst': convenienceFeeGst,
        'totalConvenienceFee': totalConvenienceFee,
        'totalAmountPaidByBuyer': totalAmountPaidByBuyer,
        if (organizerPayout != null) 'organizerPayout': organizerPayout,
        if (adminRevenue != null) 'adminRevenue': adminRevenue,
      };
}

// ── IndividualTicketModel ───────────────────────────────────────────────────

class IndividualTicketModel {
  final String id;
  final int ticketNumber;
  final String? qrCode;
  final String? accessToken;
  final bool isCheckedIn;
  final DateTime? checkedInAt;

  const IndividualTicketModel({
    required this.id,
    required this.ticketNumber,
    this.qrCode,
    this.accessToken,
    this.isCheckedIn = false,
    this.checkedInAt,
  });

  factory IndividualTicketModel.fromJson(Map<String, dynamic> json) {
    return IndividualTicketModel(
      id: json['id']?.toString() ?? '',
      ticketNumber: (json['ticketNumber'] ?? json['ticket_number'] ?? 1) as int,
      qrCode: json['qrCode']?.toString() ?? json['qr_code']?.toString(),
      accessToken: json['accessToken']?.toString() ?? json['access_token']?.toString(),
      isCheckedIn: json['isCheckedIn'] == true || json['is_checked_in'] == true,
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.tryParse(json['checkedInAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticketNumber': ticketNumber,
        if (qrCode != null) 'qrCode': qrCode,
        if (accessToken != null) 'accessToken': accessToken,
        'isCheckedIn': isCheckedIn,
        if (checkedInAt != null) 'checkedInAt': checkedInAt!.toIso8601String(),
      };
}

// ── UserRegistrationModel ───────────────────────────────────────────────────

class UserRegistrationModel {
  final String id;
  final int quantity;
  final String status; // 'CONFIRMED' | 'PENDING' | 'CANCELLED'
  final IndividualTicketModel? ticket;
  final List<IndividualTicketModel> tickets;
  final String? accessLink;
  final String? qrCodeToken;
  final bool approvalRequired;
  final String? message;

  const UserRegistrationModel({
    required this.id,
    this.quantity = 1,
    this.status = 'CONFIRMED',
    this.ticket,
    this.tickets = const [],
    this.accessLink,
    this.qrCodeToken,
    this.approvalRequired = false,
    this.message,
  });

  bool get isConfirmed => status.toUpperCase() == 'CONFIRMED';
  bool get isPending => status.toUpperCase() == 'PENDING';

  factory UserRegistrationModel.fromJson(Map<String, dynamic> json) {
    final ticketObj = json['ticket'] is Map<String, dynamic>
        ? IndividualTicketModel.fromJson(json['ticket'] as Map<String, dynamic>)
        : null;

    final ticketsList = json['tickets'] is List
        ? (json['tickets'] as List)
            .whereType<Map<String, dynamic>>()
            .map(IndividualTicketModel.fromJson)
            .toList()
        : (ticketObj != null ? [ticketObj] : <IndividualTicketModel>[]);

    return UserRegistrationModel(
      id: json['id']?.toString() ?? json['registrationId']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      status: json['status']?.toString().toUpperCase() ?? 'CONFIRMED',
      ticket: ticketObj,
      tickets: ticketsList,
      accessLink: json['accessLink']?.toString() ?? json['access_link']?.toString(),
      qrCodeToken: json['qrCodeToken']?.toString() ??
          json['qr_code_token']?.toString() ??
          ticketObj?.qrCode,
      approvalRequired: json['approvalRequired'] == true || json['approval_required'] == true,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'quantity': quantity,
        'status': status,
        if (ticket != null) 'ticket': ticket!.toJson(),
        'tickets': tickets.map((t) => t.toJson()).toList(),
        if (accessLink != null) 'accessLink': accessLink,
        if (qrCodeToken != null) 'qrCodeToken': qrCodeToken,
        'approvalRequired': approvalRequired,
        if (message != null) 'message': message,
      };
}

// ── TicketType / TicketTierModel ────────────────────────────────────────────

class TicketType {
  final String id;
  final String name;
  final String? description;
  final int priceInPaise;
  final int platformFeePaise;
  final int? quantity;
  final int soldCount;
  final int? remainingCount;
  final bool isSoldOut;
  final FeeBreakdownModel? feeBreakdown;

  const TicketType({
    required this.id,
    required this.name,
    this.description,
    required this.priceInPaise,
    this.platformFeePaise = 0,
    this.quantity,
    this.soldCount = 0,
    this.remainingCount,
    this.isSoldOut = false,
    this.feeBreakdown,
  });

  bool get isFree => priceInPaise == 0;
  double get priceInRupees => priceInPaise / 100.0;

  int get availableQuantity {
    if (remainingCount != null) return remainingCount!;
    if (quantity != null) {
      final rem = quantity! - soldCount;
      return rem > 0 ? rem : 0;
    }
    return 100;
  }

  factory TicketType.fromJson(Map<String, dynamic> json) {
    int parsedPrice = 0;
    if (json['priceInPaise'] != null || json['price_in_paise'] != null) {
      final v = json['priceInPaise'] ?? json['price_in_paise'];
      parsedPrice = v is num ? v.toInt() : (int.tryParse(v.toString()) ?? 0);
    } else if (json['price'] != null || json['priceInRupees'] != null || json['price_in_rupees'] != null) {
      final v = json['price'] ?? json['priceInRupees'] ?? json['price_in_rupees'];
      final numVal = v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);
      parsedPrice = (numVal * 100).round();
    }

    final qty = json['quantity'] as int?;
    final sold = (json['soldCount'] ?? json['sold_count'] ?? 0) as int;
    final rem = json['remainingCount'] as int? ?? (qty != null ? (qty - sold) : null);
    final soldOut = json['isSoldOut'] == true || (rem != null && rem <= 0);

    final feeObj = json['feeBreakdown'] is Map<String, dynamic>
        ? FeeBreakdownModel.fromJson(json['feeBreakdown'] as Map<String, dynamic>)
        : null;

    return TicketType(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'General Admission',
      description: json['description']?.toString(),
      priceInPaise: parsedPrice,
      platformFeePaise:
          json['platformFeePaise'] ?? json['platform_fee_paise'] ?? 0,
      quantity: qty,
      soldCount: sold,
      remainingCount: rem,
      isSoldOut: soldOut,
      feeBreakdown: feeObj,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'priceInPaise': priceInPaise,
        'platformFeePaise': platformFeePaise,
        if (quantity != null) 'quantity': quantity,
        'soldCount': soldCount,
        if (remainingCount != null) 'remainingCount': remainingCount,
        'isSoldOut': isSoldOut,
        if (feeBreakdown != null) 'feeBreakdown': feeBreakdown!.toJson(),
      };
}

// ── PublicEvent / EventModel ────────────────────────────────────────────────

class PublicEvent {
  final String id;
  final String title;
  final String slug;
  final String? description;
  final String? coverImageUrl;
  final String? categoryId;
  final Category? category;
  final EventMode mode;
  final ApprovalMode approvalMode;
  final String visibility;
  final String capacityType;
  final String? venueName;
  final String? venueAddress;
  final String? venueCity;
  final double? venueLat;
  final double? venueLng;
  final String? meetingUrl;
  final DateTime startDatetime;
  final DateTime? endDatetime;
  final String timezone;
  final int maxCapacity;
  final int minPricePaise;
  final int maxPricePaise;
  final String hostName;
  final String? hostProfilePhoto;
  final List<TicketType> ticketTypes;
  final UserRegistrationModel? userRegistration;

  const PublicEvent({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    this.coverImageUrl,
    this.categoryId,
    this.category,
    this.mode = EventMode.OFFLINE,
    this.approvalMode = ApprovalMode.INSTANT,
    this.visibility = 'PUBLIC',
    this.capacityType = 'LIMITED',
    this.venueName,
    this.venueAddress,
    this.venueCity,
    this.venueLat,
    this.venueLng,
    this.meetingUrl,
    required this.startDatetime,
    this.endDatetime,
    this.timezone = 'Asia/Kolkata',
    this.maxCapacity = 300,
    this.minPricePaise = 0,
    this.maxPricePaise = 0,
    this.hostName = 'Host Community',
    this.hostProfilePhoto,
    this.ticketTypes = const [],
    this.userRegistration,
  });

  bool get isOnline => mode == EventMode.ONLINE;
  bool get isOffline => mode == EventMode.OFFLINE;

  double get minPriceInRupees => minPricePaise / 100.0;
  double get maxPriceInRupees => maxPricePaise / 100.0;

  bool get hasUserRegistered => userRegistration != null;

  String get effectivePriceLabel {
    if (ticketTypes.isEmpty) {
      return minPricePaise == 0 ? 'Free Admission' : 'From ₹${(minPricePaise / 100).toStringAsFixed(0)}';
    }
    final freeTiers = ticketTypes.where((t) => t.isFree);
    final paidTiers = ticketTypes.where((t) => !t.isFree).toList();
    if (paidTiers.isEmpty) return 'Free Admission';
    if (freeTiers.isNotEmpty) return 'Free — ₹${paidTiers.map((t) => t.priceInRupees).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}';
    final minPaid = paidTiers.map((t) => t.priceInRupees).reduce((a, b) => a < b ? a : b);
    return 'From ₹${minPaid.toStringAsFixed(0)}';
  }

  factory PublicEvent.fromJson(Map<String, dynamic> json) {
    final hostObj = json['host'] is Map<String, dynamic> ? json['host'] : null;

    final catObj = json['category'] is Map<String, dynamic>
        ? Category.fromJson(json['category'] as Map<String, dynamic>)
        : null;

    final ticketsList = ((json['ticketTypes'] ?? json['ticket_types'] ?? json['tickets']) as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(TicketType.fromJson)
            .toList() ??
        const [];

    int parsedMinPaise = 0;
    if (json['minPricePaise'] != null || json['min_price_paise'] != null) {
      final v = json['minPricePaise'] ?? json['min_price_paise'];
      parsedMinPaise = v is num ? v.toInt() : (int.tryParse(v.toString()) ?? 0);
    } else if (json['minPrice'] != null || json['min_price'] != null || json['startingPrice'] != null || json['starting_price'] != null) {
      final v = json['minPrice'] ?? json['min_price'] ?? json['startingPrice'] ?? json['starting_price'];
      final numVal = v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);
      parsedMinPaise = (numVal * 100).round();
    } else if (json['priceInPaise'] != null || json['price_in_paise'] != null) {
      final v = json['priceInPaise'] ?? json['price_in_paise'];
      parsedMinPaise = v is num ? v.toInt() : (int.tryParse(v.toString()) ?? 0);
    } else if (json['price'] != null) {
      final v = json['price'];
      final numVal = v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);
      parsedMinPaise = (numVal * 100).round();
    }

    if (parsedMinPaise == 0 && ticketsList.isNotEmpty) {
      final activeTiers = ticketsList.where((t) => !t.isSoldOut).toList();
      final pool = activeTiers.isNotEmpty ? activeTiers : ticketsList;
      parsedMinPaise = pool.map((t) => t.priceInPaise).reduce((a, b) => a < b ? a : b);
    }

    int parsedMaxPaise = 0;
    if (json['maxPricePaise'] != null || json['max_price_paise'] != null) {
      final v = json['maxPricePaise'] ?? json['max_price_paise'];
      parsedMaxPaise = v is num ? v.toInt() : (int.tryParse(v.toString()) ?? 0);
    } else if (json['maxPrice'] != null || json['max_price'] != null) {
      final v = json['maxPrice'] ?? json['max_price'];
      final numVal = v is num ? v.toDouble() : (double.tryParse(v.toString()) ?? 0.0);
      parsedMaxPaise = (numVal * 100).round();
    }

    if (parsedMaxPaise == 0 && ticketsList.isNotEmpty) {
      parsedMaxPaise = ticketsList.map((t) => t.priceInPaise).reduce((a, b) => a > b ? a : b);
    }

    final regObj = json['userRegistration'] is Map<String, dynamic>
        ? UserRegistrationModel.fromJson(json['userRegistration'] as Map<String, dynamic>)
        : (json['registration'] is Map<String, dynamic>
            ? UserRegistrationModel.fromJson(json['registration'] as Map<String, dynamic>)
            : null);

    return PublicEvent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      coverImageUrl:
          json['coverImageUrl']?.toString() ?? json['cover_image_url']?.toString(),
      categoryId: json['categoryId']?.toString() ?? json['category_id']?.toString(),
      category: catObj,
      mode: (json['mode']?.toString().toUpperCase() == 'ONLINE')
          ? EventMode.ONLINE
          : EventMode.OFFLINE,
      approvalMode:
          (json['approvalMode']?.toString().toUpperCase().contains('APPROVAL') == true ||
                  json['approval_mode']?.toString().toUpperCase().contains('APPROVAL') == true)
              ? ApprovalMode.APPROVAL_REQUIRED
              : ApprovalMode.INSTANT,
      visibility: json['visibility']?.toString().toUpperCase() ?? 'PUBLIC',
      capacityType: json['capacityType']?.toString().toUpperCase() ?? 'LIMITED',
      venueName: json['venueName']?.toString() ?? json['venue_name']?.toString(),
      venueAddress:
          json['venueAddress']?.toString() ?? json['venue_address']?.toString(),
      venueCity: json['venueCity']?.toString() ?? json['venue_city']?.toString(),
      venueLat: (json['venueLat'] as num?)?.toDouble() ?? (json['venue_lat'] as num?)?.toDouble(),
      venueLng: (json['venueLng'] as num?)?.toDouble() ?? (json['venue_lng'] as num?)?.toDouble(),
      meetingUrl: json['meetingUrl']?.toString() ?? json['meeting_url']?.toString(),
      startDatetime: json['startDatetime'] != null
          ? DateTime.tryParse(json['startDatetime']) ?? DateTime.now()
          : DateTime.now().add(const Duration(days: 3)),
      endDatetime: json['endDatetime'] != null
          ? DateTime.tryParse(json['endDatetime'])
          : null,
      timezone: json['timezone']?.toString() ?? 'Asia/Kolkata',
      maxCapacity: json['maxCapacity'] ?? json['max_capacity'] ?? 300,
      minPricePaise: parsedMinPaise,
      maxPricePaise: parsedMaxPaise,
      hostName: hostObj?['name']?.toString() ??
          json['hostName']?.toString() ??
          json['host_name']?.toString() ??
          'Host Community',
      hostProfilePhoto: hostObj?['profilePhoto']?.toString() ??
          hostObj?['profile_photo']?.toString(),
      ticketTypes: ticketsList,
      userRegistration: regObj,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        if (description != null) 'description': description,
        if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
        if (categoryId != null) 'categoryId': categoryId,
        'mode': mode.name,
        'approvalMode': approvalMode.name,
        'visibility': visibility,
        if (venueName != null) 'venueName': venueName,
        if (venueAddress != null) 'venueAddress': venueAddress,
        if (venueCity != null) 'venueCity': venueCity,
        if (meetingUrl != null) 'meetingUrl': meetingUrl,
        'startDatetime': startDatetime.toIso8601String(),
        if (endDatetime != null) 'endDatetime': endDatetime!.toIso8601String(),
        'ticketTypes': ticketTypes.map((t) => t.toJson()).toList(),
        if (userRegistration != null) 'userRegistration': userRegistration!.toJson(),
      };
}

// ── TicketOrderResponse (POST /catalog/events/:id/create-ticket-order) ───────

class TicketOrderResponse {
  final String registrationId;
  final int quantity;
  final String? paymentId;
  final String gatewayOrderId;
  final int amountInPaise;
  final String currency;
  final String key;
  final FeeBreakdownModel? feeBreakdown;
  final bool approvalRequired;

  const TicketOrderResponse({
    required this.registrationId,
    required this.quantity,
    this.paymentId,
    required this.gatewayOrderId,
    required this.amountInPaise,
    required this.currency,
    required this.key,
    this.feeBreakdown,
    this.approvalRequired = false,
  });

  factory TicketOrderResponse.fromJson(Map<String, dynamic> json) {
    final feeObj = json['feeBreakdown'] is Map<String, dynamic>
        ? FeeBreakdownModel.fromJson(json['feeBreakdown'] as Map<String, dynamic>)
        : null;

    return TicketOrderResponse(
      registrationId: json['registrationId']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      paymentId: json['paymentId']?.toString(),
      gatewayOrderId: json['gatewayOrderId']?.toString() ?? '',
      amountInPaise: (json['amountInPaise'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      key: json['key']?.toString() ?? '',
      feeBreakdown: feeObj,
      approvalRequired: json['approvalRequired'] == true || json['approval_required'] == true,
    );
  }
}

// ── 🔍 Multi-Dimensional Search & Discovery Models ───────────────────────────

enum SearchSortBy {
  priority('priority', 'Recommended (Priority Boost)'),
  distance('distance', 'Nearest Distance'),
  priceAsc('price_asc', 'Price: Low to High'),
  priceDesc('price_desc', 'Price: High to Low'),
  rating('rating', 'Highest Rated'),
  popularity('popularity', 'Most Popular'),
  createdAt('created_at', 'Newest First');

  final String value;
  final String label;
  const SearchSortBy(this.value, this.label);

  static SearchSortBy fromString(String? val) {
    if (val == null) return SearchSortBy.priority;
    for (final s in SearchSortBy.values) {
      if (s.value == val || s.name == val) return s;
    }
    return SearchSortBy.priority;
  }
}

class SearchQuery {
  final String? search;
  final String? city;
  final double? lat;
  final double? lng;
  final double radiusKm;
  final String? categoryId;
  final String? subCategoryId;
  final int? minPrice; // In paise
  final int? maxPrice; // In paise
  final double? minRating;
  final String? startDate; // YYYY-MM-DD
  final String? endDate;   // YYYY-MM-DD
  final String? pricingUnit; // FIXED, PER_HEAD, PER_HOUR
  final String? eventMode;   // ONLINE, OFFLINE
  final SearchSortBy sortBy;
  final int page;
  final int limit;

  const SearchQuery({
    this.search,
    this.city,
    this.lat,
    this.lng,
    this.radiusKm = 50.0,
    this.categoryId,
    this.subCategoryId,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.startDate,
    this.endDate,
    this.pricingUnit,
    this.eventMode,
    this.sortBy = SearchSortBy.priority,
    this.page = 1,
    this.limit = 20,
  });

  SearchQuery copyWith({
    String? search,
    String? city,
    double? lat,
    double? lng,
    double? radiusKm,
    String? categoryId,
    String? subCategoryId,
    int? minPrice,
    int? maxPrice,
    double? minRating,
    String? startDate,
    String? endDate,
    String? pricingUnit,
    String? eventMode,
    SearchSortBy? sortBy,
    int? page,
    int? limit,
  }) {
    return SearchQuery(
      search: search ?? this.search,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusKm: radiusKm ?? this.radiusKm,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pricingUnit: pricingUnit ?? this.pricingUnit,
      eventMode: eventMode ?? this.eventMode,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final map = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy.value,
      'radiusKm': radiusKm,
    };
    if (search != null && search!.trim().isNotEmpty) map['search'] = search!.trim();
    if (city != null && city!.trim().isNotEmpty && city != 'All') map['city'] = city!.trim();
    if (lat != null && lng != null) {
      map['lat'] = lat;
      map['lng'] = lng;
    }
    if (categoryId != null && categoryId!.isNotEmpty && categoryId != 'All') {
      map['categoryId'] = categoryId;
    }
    if (subCategoryId != null && subCategoryId!.isNotEmpty && subCategoryId != 'All') {
      map['subCategoryId'] = subCategoryId;
    }
    if (minPrice != null && minPrice! > 0) map['minPrice'] = minPrice;
    if (maxPrice != null && maxPrice! > 0) map['maxPrice'] = maxPrice;
    if (minRating != null && minRating! > 0) map['minRating'] = minRating;
    if (startDate != null && startDate!.isNotEmpty) map['startDate'] = startDate;
    if (endDate != null && endDate!.isNotEmpty) map['endDate'] = endDate;
    if (pricingUnit != null && pricingUnit!.isNotEmpty && pricingUnit != 'ALL') {
      map['pricingUnit'] = pricingUnit;
    }
    if (eventMode != null && eventMode!.isNotEmpty && eventMode != 'ALL') {
      map['eventMode'] = eventMode;
    }
    return map;
  }
}

class AutocompleteResult {
  final List<EventPackage> packages;
  final List<StandaloneService> services;
  final List<PublicEvent> events;
  final List<OrganizerSummary> organizers;
  final List<Category> categories;

  const AutocompleteResult({
    this.packages = const [],
    this.services = const [],
    this.events = const [],
    this.organizers = const [],
    this.categories = const [],
  });

  bool get isEmpty =>
      packages.isEmpty &&
      services.isEmpty &&
      events.isEmpty &&
      organizers.isEmpty &&
      categories.isEmpty;

  bool get isNotEmpty => !isEmpty;

  int get totalCount =>
      packages.length +
      services.length +
      events.length +
      organizers.length +
      categories.length;

  factory AutocompleteResult.fromJson(Map<String, dynamic> json) {
    final suggestions = json['suggestions'] is Map<String, dynamic>
        ? json['suggestions'] as Map<String, dynamic>
        : json;

    return AutocompleteResult(
      packages: (suggestions['packages'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(EventPackage.fromJson)
              .toList() ??
          const [],
      services: (suggestions['services'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(StandaloneService.fromJson)
              .toList() ??
          const [],
      events: (suggestions['events'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(PublicEvent.fromJson)
              .toList() ??
          const [],
      organizers: (suggestions['organizers'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(OrganizerSummary.fromJson)
              .toList() ??
          const [],
      categories: (suggestions['categories'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(Category.fromJson)
              .toList() ??
          const [],
    );
  }
}

class UnifiedSearchResult {
  final int totalPackages;
  final int totalServices;
  final int totalOrganizers;
  final int totalEvents;
  final List<EventPackage> packages;
  final List<StandaloneService> services;
  final List<OrganizerSummary> organizers;
  final List<PublicEvent> events;

  const UnifiedSearchResult({
    this.totalPackages = 0,
    this.totalServices = 0,
    this.totalOrganizers = 0,
    this.totalEvents = 0,
    this.packages = const [],
    this.services = const [],
    this.organizers = const [],
    this.events = const [],
  });

  bool get isEmpty =>
      packages.isEmpty &&
      services.isEmpty &&
      organizers.isEmpty &&
      events.isEmpty;

  bool get isNotEmpty => !isEmpty;

  factory UnifiedSearchResult.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final results = json['results'] as Map<String, dynamic>? ?? json;

    final rawPkgs = results['packages'] ?? (results['data'] is Map ? results['data']['packages'] : null);
    final rawSrvs = results['services'] ?? (results['data'] is Map ? results['data']['services'] : null);
    final rawOrgs = results['organizers'] ?? (results['data'] is Map ? results['data']['organizers'] : null);
    final rawEvts = results['events'] ?? (results['data'] is Map ? results['data']['events'] : null);

    return UnifiedSearchResult(
      totalPackages: (summary['totalPackages'] ?? summary['packages'] ?? (rawPkgs is List ? rawPkgs.length : 0)) as int,
      totalServices: (summary['totalServices'] ?? summary['services'] ?? (rawSrvs is List ? rawSrvs.length : 0)) as int,
      totalOrganizers: (summary['totalOrganizers'] ?? summary['organizers'] ?? (rawOrgs is List ? rawOrgs.length : 0)) as int,
      totalEvents: (summary['totalEvents'] ?? summary['events'] ?? (rawEvts is List ? rawEvts.length : 0)) as int,
      packages: (rawPkgs as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(EventPackage.fromJson)
              .toList() ??
          const [],
      services: (rawSrvs as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(StandaloneService.fromJson)
              .toList() ??
          const [],
      organizers: (rawOrgs as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(OrganizerSummary.fromJson)
              .toList() ??
          const [],
      events: (rawEvts as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(PublicEvent.fromJson)
              .toList() ??
          const [],
    );
  }
}

class FollowToggleResponse {
  final bool isFollowed;
  final int followerCount;
  final String? message;

  const FollowToggleResponse({
    required this.isFollowed,
    required this.followerCount,
    this.message,
  });

  factory FollowToggleResponse.fromJson(Map<String, dynamic> json) {
    return FollowToggleResponse(
      isFollowed: json['isFollowing'] == true ||
          json['isFollowed'] == true ||
          json['is_followed'] == true,
      followerCount: (json['followerCount'] as num?)?.toInt() ??
          (json['followers'] as num?)?.toInt() ??
          0,
      message: json['message']?.toString(),
    );
  }
}

class FollowedOrganizerItem {
  final DateTime followedAt;
  final String organizerProfileId;
  final FollowedOrganizerDetail organizer;

  const FollowedOrganizerItem({
    required this.followedAt,
    required this.organizerProfileId,
    required this.organizer,
  });

  factory FollowedOrganizerItem.fromJson(Map<String, dynamic> json) {
    return FollowedOrganizerItem(
      followedAt: DateTime.tryParse(json['followedAt']?.toString() ?? '') ?? DateTime.now(),
      organizerProfileId: json['organizerProfileId']?.toString() ?? json['id']?.toString() ?? '',
      organizer: FollowedOrganizerDetail.fromJson(
        json['organizer'] is Map<String, dynamic>
            ? json['organizer'] as Map<String, dynamic>
            : json,
      ),
    );
  }
}

class FollowedOrganizerDetail {
  final String id;
  final String businessName;
  final String? displayName;
  final String? city;
  final String? bio;
  final String? organizerName;
  final String? profilePhoto;
  final int followerCount;
  final int packageCount;
  final int serviceCount;

  const FollowedOrganizerDetail({
    required this.id,
    required this.businessName,
    this.displayName,
    this.city,
    this.bio,
    this.organizerName,
    this.profilePhoto,
    required this.followerCount,
    required this.packageCount,
    required this.serviceCount,
  });

  factory FollowedOrganizerDetail.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return FollowedOrganizerDetail(
      id: json['id']?.toString() ?? '',
      businessName: json['businessName']?.toString() ?? json['name']?.toString() ?? 'Organizer',
      displayName: json['displayName']?.toString(),
      city: json['city']?.toString(),
      bio: json['bio']?.toString(),
      organizerName: user?['name']?.toString() ?? json['name']?.toString(),
      profilePhoto: user?['profilePhoto']?.toString() ??
          user?['avatarUrl']?.toString() ??
          json['avatarUrl']?.toString() ??
          json['profilePhoto']?.toString(),
      followerCount: (json['followerCount'] as num?)?.toInt() ??
          (json['followers'] as num?)?.toInt() ??
          0,
      packageCount: (json['packageCount'] as num?)?.toInt() ??
          (json['packages'] is List ? (json['packages'] as List).length : 0),
      serviceCount: (json['serviceCount'] as num?)?.toInt() ??
          (json['services'] is List ? (json['services'] as List).length : 0),
    );
  }

  OrganizerSummary toSummary() {
    return OrganizerSummary(
      id: id,
      businessName: businessName,
      displayName: displayName,
      city: city,
      bio: bio,
      kycStatus: 'APPROVED',
      rating: 5.0,
      reviewCount: 0,
      avatarUrl: profilePhoto,
      isFollowed: true,
      followerCount: followerCount,
      packageCount: packageCount,
      serviceCount: serviceCount,
    );
  }
}

