import '../../../home/domain/entities/catalog_entities.dart';

// ── Host Event Lifecycle Status ───────────────────────────────────────────────

enum HostEventStatus {
  DRAFT,
  PENDING_APPROVAL,
  PUBLISHED,
  LIVE,
  COMPLETED,
  CANCELLED,
}

// ── Main Host Event Model ─────────────────────────────────────────────────────

class HostEventItem {
  final String id;
  final String title;
  final String slug;
  final String? description;
  final String? coverImageUrl;
  final String status;
  final EventMode mode;
  final String visibility; // 'PUBLIC' | 'PRIVATE'
  final ApprovalMode approvalMode;
  final String capacityType; // 'LIMITED' | 'UNLIMITED'
  final int maxCapacity;
  final String? venueName;
  final String? venueAddress;
  final String? venueCity;
  final double? venueLat;
  final double? venueLng;
  final String? meetingUrl;
  final String? meetingPassword;
  final DateTime startDatetime;
  final DateTime? endDatetime;
  final String timezone;
  final String? categoryId;
  final EventCategory? category;
  final int registeredCount;
  final List<TicketType> ticketTypes;
  final List<HostRegistration> registrations;

  const HostEventItem({
    required this.id,
    required this.title,
    this.slug = '',
    this.description,
    this.coverImageUrl,
    this.status = 'DRAFT',
    this.mode = EventMode.OFFLINE,
    this.visibility = 'PUBLIC',
    this.approvalMode = ApprovalMode.INSTANT,
    this.capacityType = 'LIMITED',
    this.maxCapacity = 300,
    this.venueName,
    this.venueAddress,
    this.venueCity,
    this.venueLat,
    this.venueLng,
    this.meetingUrl,
    this.meetingPassword,
    required this.startDatetime,
    this.endDatetime,
    this.timezone = 'Asia/Kolkata',
    this.categoryId,
    this.category,
    this.registeredCount = 0,
    this.ticketTypes = const [],
    this.registrations = const [],
  });

  // Backward compatibility alias for legacy views
  DateTime get eventDate => startDatetime;
  String get venue => venueName ?? venueCity ?? (isOnline ? 'Online Virtual Stream' : 'Auditorium Hall');
  int get totalCapacity => maxCapacity;

  bool get isOnline => mode == EventMode.ONLINE;
  bool get isOffline => mode == EventMode.OFFLINE;

  bool get isDraft => status.toUpperCase() == 'DRAFT';
  bool get isPendingApproval => status.toUpperCase() == 'PENDING_APPROVAL';
  bool get isPublished => status.toUpperCase() == 'PUBLISHED';
  bool get isLive =>
      status.toUpperCase() == 'LIVE' ||
      (isPublished &&
          DateTime.now().isAfter(startDatetime) &&
          (endDatetime == null || DateTime.now().isBefore(endDatetime!)));
  bool get isCompleted =>
      status.toUpperCase() == 'COMPLETED' ||
      (endDatetime != null && DateTime.now().isAfter(endDatetime!));
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  /// Total registered attendees count
  int get totalRegistrations {
    if (registeredCount > 0) return registeredCount;
    if (registrations.isNotEmpty) return registrations.length;
    return ticketTypes.fold<int>(0, (sum, t) => sum + t.soldCount);
  }

  /// Total checked in count across registrations
  int get checkedInCount {
    var count = 0;
    for (final reg in registrations) {
      if (reg.status == 'CHECKED_IN') {
        count += reg.quantity;
      } else {
        for (final t in reg.tickets) {
          if (t.isCheckedIn) count++;
        }
      }
    }
    return count;
  }

  /// Total ticket revenue in paise
  int get revenueInPaise {
    return ticketTypes.fold<int>(
      0,
      (sum, t) => sum + (t.soldCount * t.priceInPaise),
    );
  }

  /// Pending approvals count
  int get pendingApprovalsCount {
    return registrations.where((r) => r.status.toUpperCase() == 'PENDING').length;
  }

  /// Formatted Price Range Summary
  String get priceSummaryLabel {
    if (ticketTypes.isEmpty) return 'Free';
    final hasFree = ticketTypes.any((t) => t.isFree);
    final paidTiers = ticketTypes.where((t) => !t.isFree).toList();
    if (paidTiers.isEmpty) return 'Free Pass';
    paidTiers.sort((a, b) => a.priceInPaise.compareTo(b.priceInPaise));
    final minPrice = (paidTiers.first.priceInPaise / 100.0).toStringAsFixed(0);
    return hasFree ? 'Free - ₹$minPrice' : 'From ₹$minPrice';
  }

  factory HostEventItem.fromJson(Map<String, dynamic> json) {
    final catObj = json['category'] is Map<String, dynamic>
        ? EventCategory.fromJson(json['category'] as Map<String, dynamic>)
        : null;

    final ticketsList = (json['ticketTypes'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(TicketType.fromJson)
            .toList() ??
        const [];

    final regsList = (json['registrations'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(HostRegistration.fromJson)
            .toList() ??
        const [];

    final rawCount = json['_count'];
    final countRegistrations = rawCount is Map<String, dynamic>
        ? (rawCount['registrations'] as num?)?.toInt() ?? 0
        : (json['totalRegistrations'] as num?)?.toInt() ?? 0;

    return HostEventItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Event',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      coverImageUrl:
          json['coverImageUrl']?.toString() ?? json['cover_image_url']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'DRAFT',
      mode: (json['mode']?.toString().toUpperCase() == 'ONLINE')
          ? EventMode.ONLINE
          : EventMode.OFFLINE,
      visibility: json['visibility']?.toString().toUpperCase() ?? 'PUBLIC',
      approvalMode: (json['approvalMode']?.toString().toUpperCase().contains('APPROVAL') == true ||
              json['approval_mode']?.toString().toUpperCase().contains('APPROVAL') == true)
          ? ApprovalMode.APPROVAL_REQUIRED
          : ApprovalMode.INSTANT,
      capacityType: json['capacityType']?.toString().toUpperCase() ?? 'LIMITED',
      maxCapacity: (json['maxCapacity'] as num?)?.toInt() ??
          (json['max_capacity'] as num?)?.toInt() ??
          (json['totalCapacity'] as num?)?.toInt() ??
          300,
      venueName: json['venueName']?.toString() ?? json['venue_name']?.toString() ?? json['venue']?.toString(),
      venueAddress: json['venueAddress']?.toString() ?? json['venue_address']?.toString(),
      venueCity: json['venueCity']?.toString() ?? json['venue_city']?.toString(),
      venueLat: (json['venueLat'] as num?)?.toDouble() ?? (json['venue_lat'] as num?)?.toDouble(),
      venueLng: (json['venueLng'] as num?)?.toDouble() ?? (json['venue_lng'] as num?)?.toDouble(),
      meetingUrl: json['meetingUrl']?.toString() ?? json['meeting_url']?.toString(),
      meetingPassword: json['meetingPassword']?.toString() ?? json['meeting_password']?.toString(),
      startDatetime: json['startDatetime'] != null
          ? DateTime.tryParse(json['startDatetime']) ?? DateTime.now()
          : (json['eventDate'] != null
              ? DateTime.tryParse(json['eventDate']) ?? DateTime.now()
              : DateTime.now()),
      endDatetime: json['endDatetime'] != null ? DateTime.tryParse(json['endDatetime']) : null,
      timezone: json['timezone']?.toString() ?? 'Asia/Kolkata',
      categoryId: json['categoryId']?.toString() ?? json['category_id']?.toString(),
      category: catObj,
      registeredCount: countRegistrations,
      ticketTypes: ticketsList,
      registrations: regsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        if (description != null) 'description': description,
        if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
        'status': status,
        'mode': mode.name,
        'visibility': visibility,
        'approvalMode': approvalMode == ApprovalMode.APPROVAL_REQUIRED
            ? 'APPROVAL_REQUIRED'
            : 'INSTANT_CONFIRM',
        'capacityType': capacityType,
        'maxCapacity': maxCapacity,
        if (venueName != null) 'venueName': venueName,
        if (venueAddress != null) 'venueAddress': venueAddress,
        if (venueCity != null) 'venueCity': venueCity,
        if (venueLat != null) 'venueLat': venueLat,
        if (venueLng != null) 'venueLng': venueLng,
        if (meetingUrl != null) 'meetingUrl': meetingUrl,
        if (meetingPassword != null) 'meetingPassword': meetingPassword,
        'startDatetime': startDatetime.toIso8601String(),
        if (endDatetime != null) 'endDatetime': endDatetime!.toIso8601String(),
        'timezone': timezone,
        if (categoryId != null) 'categoryId': categoryId,
      };

  HostEventItem copyWith({
    String? id,
    String? title,
    String? slug,
    String? description,
    String? coverImageUrl,
    String? status,
    EventMode? mode,
    String? visibility,
    ApprovalMode? approvalMode,
    String? capacityType,
    int? maxCapacity,
    String? venueName,
    String? venueAddress,
    String? venueCity,
    double? venueLat,
    double? venueLng,
    String? meetingUrl,
    String? meetingPassword,
    DateTime? startDatetime,
    DateTime? endDatetime,
    String? timezone,
    String? categoryId,
    EventCategory? category,
    int? registeredCount,
    List<TicketType>? ticketTypes,
    List<HostRegistration>? registrations,
  }) {
    return HostEventItem(
      id: id ?? this.id,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      visibility: visibility ?? this.visibility,
      approvalMode: approvalMode ?? this.approvalMode,
      capacityType: capacityType ?? this.capacityType,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      venueName: venueName ?? this.venueName,
      venueAddress: venueAddress ?? this.venueAddress,
      venueCity: venueCity ?? this.venueCity,
      venueLat: venueLat ?? this.venueLat,
      venueLng: venueLng ?? this.venueLng,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      meetingPassword: meetingPassword ?? this.meetingPassword,
      startDatetime: startDatetime ?? this.startDatetime,
      endDatetime: endDatetime ?? this.endDatetime,
      timezone: timezone ?? this.timezone,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      registeredCount: registeredCount ?? this.registeredCount,
      ticketTypes: ticketTypes ?? this.ticketTypes,
      registrations: registrations ?? this.registrations,
    );
  }
}

// ── Host Registration & Attendee Model ────────────────────────────────────────

class HostRegistration {
  final String id;
  final String status; // 'CONFIRMED' | 'PENDING' | 'REJECTED' | 'CHECKED_IN' | 'CANCELLED'
  final int quantity;
  final String? attendeeNote;
  final String? hostMessage;
  final DateTime createdAt;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String? userAvatar;
  final String ticketTypeName;
  final int pricePaidPaise;
  final List<IndividualTicketModel> tickets;

  const HostRegistration({
    required this.id,
    required this.status,
    this.quantity = 1,
    this.attendeeNote,
    this.hostMessage,
    required this.createdAt,
    this.userName = 'Attendee',
    this.userEmail = '',
    this.userPhone = '',
    this.userAvatar,
    this.ticketTypeName = 'General Pass',
    this.pricePaidPaise = 0,
    this.tickets = const [],
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isConfirmed => status.toUpperCase() == 'CONFIRMED';
  bool get isCheckedIn => status.toUpperCase() == 'CHECKED_IN';
  bool get isRejected => status.toUpperCase() == 'REJECTED';

  factory HostRegistration.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'] as Map<String, dynamic>?;
    final ticketTypeObj = json['ticketType'] as Map<String, dynamic>?;

    final ticketsList = (json['tickets'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(IndividualTicketModel.fromJson)
            .toList() ??
        const [];

    return HostRegistration(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString().toUpperCase() ?? 'CONFIRMED',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      attendeeNote: json['attendeeNote']?.toString() ?? json['attendee_note']?.toString(),
      hostMessage: json['hostMessage']?.toString() ?? json['host_message']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      userName: userObj?['name']?.toString() ??
          json['attendeeName']?.toString() ??
          json['userName']?.toString() ??
          'Attendee',
      userEmail: userObj?['email']?.toString() ??
          json['attendeeEmail']?.toString() ??
          json['userEmail']?.toString() ??
          '',
      userPhone: userObj?['phone']?.toString() ??
          json['attendeePhone']?.toString() ??
          json['userPhone']?.toString() ??
          '',
      userAvatar: userObj?['profilePhoto']?.toString() ?? userObj?['avatar']?.toString(),
      ticketTypeName: ticketTypeObj?['name']?.toString() ??
          json['ticketTypeName']?.toString() ??
          'General Pass',
      pricePaidPaise: (ticketTypeObj?['priceInPaise'] as num?)?.toInt() ??
          (json['pricePaidPaise'] as num?)?.toInt() ??
          0,
      tickets: ticketsList,
    );
  }
}

// ── Legacy AttendeeRecord for backward compatibility ───────────────────────────

class AttendeeRecord {
  final String id;
  final String attendeeName;
  final String attendeeEmail;
  final String ticketType;
  final String qrCode;
  final bool isCheckedIn;
  final DateTime? checkedInAt;

  const AttendeeRecord({
    required this.id,
    required this.attendeeName,
    required this.attendeeEmail,
    required this.ticketType,
    required this.qrCode,
    this.isCheckedIn = false,
    this.checkedInAt,
  });

  factory AttendeeRecord.fromJson(Map<String, dynamic> json) {
    return AttendeeRecord(
      id: json['id']?.toString() ?? '',
      attendeeName: json['attendeeName'] ?? json['name'] ?? json['user']?['name'] ?? 'Attendee',
      attendeeEmail: json['attendeeEmail'] ?? json['email'] ?? json['user']?['email'] ?? '',
      ticketType: json['ticketType']?['name'] ?? json['ticketType'] ?? 'General',
      qrCode: json['qrCode'] ?? json['qr_code'] ?? '',
      isCheckedIn: json['isCheckedIn'] ?? json['status'] == 'CHECKED_IN' ?? false,
      checkedInAt: json['checkedInAt'] != null ? DateTime.tryParse(json['checkedInAt'].toString()) : null,
    );
  }

  AttendeeRecord copyWith({
    String? id,
    String? attendeeName,
    String? attendeeEmail,
    String? ticketType,
    String? qrCode,
    bool? isCheckedIn,
    DateTime? checkedInAt,
  }) {
    return AttendeeRecord(
      id: id ?? this.id,
      attendeeName: attendeeName ?? this.attendeeName,
      attendeeEmail: attendeeEmail ?? this.attendeeEmail,
      ticketType: ticketType ?? this.ticketType,
      qrCode: qrCode ?? this.qrCode,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkedInAt: checkedInAt ?? this.checkedInAt,
    );
  }
}

// ── Requests & DTOs ───────────────────────────────────────────────────────────

class CreateEventRequest {
  final String title;
  final String categoryId;
  final String? description;
  final String? coverImageUrl;
  final String mode; // 'OFFLINE' | 'ONLINE'
  final String visibility; // 'PUBLIC' | 'PRIVATE'
  final String approvalMode; // 'INSTANT_CONFIRM' | 'APPROVAL_REQUIRED'
  final String capacityType; // 'LIMITED' | 'UNLIMITED'
  final int maxCapacity;
  final String? venueName;
  final String? venueAddress;
  final String? venueCity;
  final double? venueLat;
  final double? venueLng;
  final String? meetingUrl;
  final String? meetingPassword;
  final DateTime startDatetime;
  final DateTime? endDatetime;
  final String timezone;

  const CreateEventRequest({
    required this.title,
    required this.categoryId,
    this.description,
    this.coverImageUrl,
    this.mode = 'OFFLINE',
    this.visibility = 'PUBLIC',
    this.approvalMode = 'INSTANT_CONFIRM',
    this.capacityType = 'LIMITED',
    this.maxCapacity = 300,
    this.venueName,
    this.venueAddress,
    this.venueCity,
    this.venueLat,
    this.venueLng,
    this.meetingUrl,
    this.meetingPassword,
    required this.startDatetime,
    this.endDatetime,
    this.timezone = 'Asia/Kolkata',
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'categoryId': categoryId,
        if (description != null && description!.isNotEmpty) 'description': description,
        if (coverImageUrl != null && coverImageUrl!.isNotEmpty) 'coverImageUrl': coverImageUrl,
        'mode': mode,
        'visibility': visibility,
        'approvalMode': approvalMode,
        'capacityType': capacityType,
        'maxCapacity': maxCapacity,
        if (venueName != null && venueName!.isNotEmpty) 'venueName': venueName,
        if (venueAddress != null && venueAddress!.isNotEmpty) 'venueAddress': venueAddress,
        if (venueCity != null && venueCity!.isNotEmpty) 'venueCity': venueCity,
        if (venueLat != null) 'venueLat': venueLat,
        if (venueLng != null) 'venueLng': venueLng,
        if (meetingUrl != null && meetingUrl!.isNotEmpty) 'meetingUrl': meetingUrl,
        if (meetingPassword != null && meetingPassword!.isNotEmpty) 'meetingPassword': meetingPassword,
        'startDatetime': startDatetime.toUtc().toIso8601String(),
        if (endDatetime != null) 'endDatetime': endDatetime!.toUtc().toIso8601String(),
        'timezone': timezone,
      };
}

class CreateTicketTierRequest {
  final String name;
  final String? description;
  final int priceInPaise;
  final int? quantity;
  final DateTime? saleStartsAt;
  final DateTime? saleEndsAt;
  final bool isActive;

  const CreateTicketTierRequest({
    required this.name,
    this.description,
    this.priceInPaise = 0,
    this.quantity,
    this.saleStartsAt,
    this.saleEndsAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null && description!.isNotEmpty) 'description': description,
        'priceInPaise': priceInPaise,
        if (quantity != null) 'quantity': quantity,
        if (saleStartsAt != null) 'saleStartsAt': saleStartsAt!.toUtc().toIso8601String(),
        if (saleEndsAt != null) 'saleEndsAt': saleEndsAt!.toUtc().toIso8601String(),
        'isActive': isActive,
      };
}

class GenerateMeetResponse {
  final String meetUrl;
  final String? calendarEventId;
  final String message;

  const GenerateMeetResponse({
    required this.meetUrl,
    this.calendarEventId,
    required this.message,
  });

  factory GenerateMeetResponse.fromJson(Map<String, dynamic> json) {
    return GenerateMeetResponse(
      meetUrl: json['meetUrl']?.toString() ?? json['meet_url']?.toString() ?? '',
      calendarEventId: json['calendarEventId']?.toString(),
      message: json['message']?.toString() ?? 'Meet room created successfully!',
    );
  }
}

enum CheckInResultStatus { VALID, ALREADY_CHECKED_IN, INVALID }

class CheckInAttendeeInfo {
  final String id;
  final String name;
  final String email;
  final String? phone;

  const CheckInAttendeeInfo({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory CheckInAttendeeInfo.fromJson(Map<String, dynamic> json) {
    return CheckInAttendeeInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['attendeeName']?.toString() ?? 'Attendee',
      email: json['email']?.toString() ?? json['attendeeEmail']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['attendeePhone']?.toString(),
    );
  }
}

class CheckInTicketTypeInfo {
  final String id;
  final String name;
  final int priceInPaise;

  const CheckInTicketTypeInfo({
    required this.id,
    required this.name,
    this.priceInPaise = 0,
  });

  factory CheckInTicketTypeInfo.fromJson(dynamic json) {
    if (json is String) {
      return CheckInTicketTypeInfo(id: '', name: json);
    }
    if (json is Map<String, dynamic>) {
      return CheckInTicketTypeInfo(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'General Pass',
        priceInPaise: (json['priceInPaise'] as num?)?.toInt() ?? 0,
      );
    }
    return const CheckInTicketTypeInfo(id: '', name: 'General Pass');
  }
}

class CheckInGroupSummary {
  final int totalPassesBooked;
  final int checkedInPasses;
  final int remainingPasses;

  const CheckInGroupSummary({
    this.totalPassesBooked = 1,
    this.checkedInPasses = 1,
    this.remainingPasses = 0,
  });

  factory CheckInGroupSummary.fromJson(Map<String, dynamic> json) {
    return CheckInGroupSummary(
      totalPassesBooked: (json['totalPassesBooked'] as num?)?.toInt() ??
          (json['total_passes_booked'] as num?)?.toInt() ??
          1,
      checkedInPasses: (json['checkedInPasses'] as num?)?.toInt() ??
          (json['checked_in_passes'] as num?)?.toInt() ??
          1,
      remainingPasses: (json['remainingPasses'] as num?)?.toInt() ??
          (json['remaining_passes'] as num?)?.toInt() ??
          0,
    );
  }
}

class CheckInResponse {
  final bool success;
  final bool isDuplicate;
  final String message;
  final DateTime? checkedInAt;
  final String? ticketId;
  final int? ticketNumber;
  final String? registrationId;
  final CheckInAttendeeInfo? attendee;
  final CheckInTicketTypeInfo? ticketType;
  final CheckInGroupSummary? groupSummary;

  const CheckInResponse({
    required this.success,
    this.isDuplicate = false,
    required this.message,
    this.checkedInAt,
    this.ticketId,
    this.ticketNumber,
    this.registrationId,
    this.attendee,
    this.ticketType,
    this.groupSummary,
  });

  CheckInResultStatus get status {
    if (success) return CheckInResultStatus.VALID;
    if (isDuplicate) return CheckInResultStatus.ALREADY_CHECKED_IN;
    return CheckInResultStatus.INVALID;
  }

  String? get attendeeName => attendee?.name;
  String? get attendeeEmail => attendee?.email;
  String? get attendeePhone => attendee?.phone;
  String? get ticketTypeName => ticketType?.name;

  factory CheckInResponse.fromJson(Map<String, dynamic> json) {
    final isDup = json['isDuplicate'] == true || json['is_duplicate'] == true;
    final isSucc = json['success'] == true;

    CheckInAttendeeInfo? attendeeObj;
    if (json['attendee'] is Map<String, dynamic>) {
      attendeeObj = CheckInAttendeeInfo.fromJson(json['attendee'] as Map<String, dynamic>);
    } else if (json['attendeeName'] != null) {
      attendeeObj = CheckInAttendeeInfo(
        id: json['attendeeId']?.toString() ?? '',
        name: json['attendeeName']?.toString() ?? 'Attendee',
        email: json['attendeeEmail']?.toString() ?? '',
        phone: json['attendeePhone']?.toString(),
      );
    }

    CheckInTicketTypeInfo? ticketTypeObj;
    if (json['ticketType'] != null) {
      ticketTypeObj = CheckInTicketTypeInfo.fromJson(json['ticketType']);
    }

    CheckInGroupSummary? groupObj;
    if (json['groupSummary'] is Map<String, dynamic>) {
      groupObj = CheckInGroupSummary.fromJson(json['groupSummary'] as Map<String, dynamic>);
    }

    return CheckInResponse(
      success: isSucc,
      isDuplicate: isDup,
      message: json['message']?.toString() ??
          (isSucc
              ? '✅ ENTRY VERIFIED & CHECKED IN'
              : (isDup ? '⚠️ DUPLICATE SCAN ATTEMPT!' : 'Invalid QR token')),
      checkedInAt: json['checkedInAt'] != null ? DateTime.tryParse(json['checkedInAt'].toString()) : null,
      ticketId: json['ticketId']?.toString(),
      ticketNumber: (json['ticketNumber'] as num?)?.toInt(),
      registrationId: json['registrationId']?.toString(),
      attendee: attendeeObj,
      ticketType: ticketTypeObj,
      groupSummary: groupObj,
    );
  }
}

class BulkCheckInResponse {
  final bool success;
  final String message;
  final int countCheckedIn;
  final CheckInGroupSummary? groupSummary;
  final CheckInAttendeeInfo? attendee;
  final String? ticketType;

  const BulkCheckInResponse({
    required this.success,
    required this.message,
    this.countCheckedIn = 0,
    this.groupSummary,
    this.attendee,
    this.ticketType,
  });

  factory BulkCheckInResponse.fromJson(Map<String, dynamic> json) {
    CheckInAttendeeInfo? attObj;
    if (json['attendee'] is Map<String, dynamic>) {
      attObj = CheckInAttendeeInfo.fromJson(json['attendee'] as Map<String, dynamic>);
    }

    CheckInGroupSummary? groupObj;
    if (json['groupSummary'] is Map<String, dynamic>) {
      groupObj = CheckInGroupSummary.fromJson(json['groupSummary'] as Map<String, dynamic>);
    }

    return BulkCheckInResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? 'Bulk check-in completed',
      countCheckedIn: (json['countCheckedIn'] as num?)?.toInt() ??
          (json['count_checked_in'] as num?)?.toInt() ??
          0,
      groupSummary: groupObj,
      attendee: attObj,
      ticketType: json['ticketType']?.toString(),
    );
  }
}

class RecentCheckInItem {
  final String ticketId;
  final int ticketNumber;
  final DateTime? checkedInAt;
  final String attendeeName;
  final String attendeeEmail;
  final String ticketType;

  const RecentCheckInItem({
    required this.ticketId,
    required this.ticketNumber,
    this.checkedInAt,
    required this.attendeeName,
    required this.attendeeEmail,
    required this.ticketType,
  });

  factory RecentCheckInItem.fromJson(Map<String, dynamic> json) {
    return RecentCheckInItem(
      ticketId: json['ticketId']?.toString() ?? '',
      ticketNumber: (json['ticketNumber'] as num?)?.toInt() ?? 1,
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.tryParse(json['checkedInAt'].toString())
          : null,
      attendeeName: json['attendeeName']?.toString() ?? 'Attendee',
      attendeeEmail: json['attendeeEmail']?.toString() ?? '',
      ticketType: json['ticketType']?.toString() ?? 'General Pass',
    );
  }
}

class GateCheckInStats {
  final String eventId;
  final String eventTitle;
  final int totalTicketsSold;
  final int totalCheckedIn;
  final int remainingAttendees;
  final double checkInPercentage;
  final int duplicateAttempts;
  final List<RecentCheckInItem> recentCheckIns;

  const GateCheckInStats({
    required this.eventId,
    required this.eventTitle,
    this.totalTicketsSold = 0,
    this.totalCheckedIn = 0,
    this.remainingAttendees = 0,
    this.checkInPercentage = 0.0,
    this.duplicateAttempts = 0,
    this.recentCheckIns = const [],
  });

  factory GateCheckInStats.fromJson(Map<String, dynamic> json) {
    final recents = (json['recentCheckIns'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(RecentCheckInItem.fromJson)
            .toList() ??
        const [];

    return GateCheckInStats(
      eventId: json['eventId']?.toString() ?? '',
      eventTitle: json['eventTitle']?.toString() ?? 'Event Gate',
      totalTicketsSold: (json['totalTicketsSold'] as num?)?.toInt() ?? 0,
      totalCheckedIn: (json['totalCheckedIn'] as num?)?.toInt() ?? 0,
      remainingAttendees: (json['remainingAttendees'] as num?)?.toInt() ?? 0,
      checkInPercentage: (json['checkInPercentage'] as num?)?.toDouble() ?? 0.0,
      duplicateAttempts: (json['duplicateAttempts'] as num?)?.toInt() ?? 0,
      recentCheckIns: recents,
    );
  }
}

class QrCheckInResult {
  final CheckInResultStatus status;
  final AttendeeRecord? attendee;
  final String message;

  const QrCheckInResult({
    required this.status,
    this.attendee,
    required this.message,
  });
}
