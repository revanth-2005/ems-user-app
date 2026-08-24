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

  bool get isVideo =>
      mediaType.toLowerCase() == 'video' ||
      mediaUrl.toLowerCase().endsWith('.mp4') ||
      mediaUrl.toLowerCase().endsWith('.mov');

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
    final rawPrice = json['priceInPaise'] ?? json['price_in_paise'] ?? 0;
    final parsedPrice = rawPrice is num ? rawPrice.toInt() : (int.tryParse(rawPrice.toString()) ?? 0);
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
      return minPricePaise == 0 ? 'Free Pass' : 'From ₹${(minPricePaise / 100).toStringAsFixed(0)}';
    }
    final freeTiers = ticketTypes.where((t) => t.isFree);
    final paidTiers = ticketTypes.where((t) => !t.isFree).toList();
    if (paidTiers.isEmpty) return 'Free Pass';
    if (freeTiers.isNotEmpty) return 'Free — ₹${paidTiers.map((t) => t.priceInRupees).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}';
    final minPaid = paidTiers.map((t) => t.priceInRupees).reduce((a, b) => a < b ? a : b);
    return 'From ₹${minPaid.toStringAsFixed(0)}';
  }

  factory PublicEvent.fromJson(Map<String, dynamic> json) {
    final hostObj = json['host'] is Map<String, dynamic> ? json['host'] : null;

    final catObj = json['category'] is Map<String, dynamic>
        ? Category.fromJson(json['category'] as Map<String, dynamic>)
        : null;

    final rawMin = json['minPricePaise'] ?? json['min_price_paise'] ?? 0;
    final rawMax = json['maxPricePaise'] ?? json['max_price_paise'] ?? 0;

    final regObj = json['userRegistration'] is Map<String, dynamic>
        ? UserRegistrationModel.fromJson(json['userRegistration'] as Map<String, dynamic>)
        : (json['registration'] is Map<String, dynamic>
            ? UserRegistrationModel.fromJson(json['registration'] as Map<String, dynamic>)
            : null);

    final ticketsList = (json['ticketTypes'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(TicketType.fromJson)
            .toList() ??
        const [];

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
      minPricePaise: rawMin is num ? rawMin.toInt() : (int.tryParse(rawMin.toString()) ?? 0),
      maxPricePaise: rawMax is num ? rawMax.toInt() : (int.tryParse(rawMax.toString()) ?? 0),
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
