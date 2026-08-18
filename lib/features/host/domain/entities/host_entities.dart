import '../../../home/domain/entities/catalog_entities.dart';

class HostEventItem {
  final String id;
  final String title;
  final DateTime eventDate;
  final String venue;
  final int totalRegistrations;
  final int checkedInCount;
  final int totalCapacity;
  final int revenueInPaise;
  final bool isLive;
  final String? coverImageUrl;
  final List<TicketType> ticketTiers;

  const HostEventItem({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.venue,
    required this.totalRegistrations,
    required this.checkedInCount,
    required this.totalCapacity,
    required this.revenueInPaise,
    this.isLive = true,
    this.coverImageUrl,
    this.ticketTiers = const [],
  });

  factory HostEventItem.fromJson(Map<String, dynamic> json) {
    return HostEventItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? 'Live Event',
      eventDate: json['eventDate'] != null ? DateTime.tryParse(json['eventDate'].toString()) ?? DateTime.now() : DateTime.now(),
      venue: json['venue'] ?? json['venueName'] ?? 'Auditorium Hall',
      totalRegistrations: (json['totalRegistrations'] ?? json['total_registrations'] ?? 0) as int,
      checkedInCount: (json['checkedInCount'] ?? json['checked_in_count'] ?? 0) as int,
      totalCapacity: (json['totalCapacity'] ?? json['total_capacity'] ?? 500) as int,
      revenueInPaise: (json['revenueInPaise'] ?? json['revenue_in_paise'] ?? 0) as int,
      isLive: json['isLive'] ?? json['is_live'] ?? true,
      coverImageUrl: json['coverImageUrl'] ?? json['cover_image_url'],
      ticketTiers: (json['ticketTiers'] as List<dynamic>?)
              ?.map((e) => TicketType.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'eventDate': eventDate.toIso8601String(),
        'venue': venue,
        'totalRegistrations': totalRegistrations,
        'checkedInCount': checkedInCount,
        'totalCapacity': totalCapacity,
        'revenueInPaise': revenueInPaise,
        'isLive': isLive,
        'coverImageUrl': coverImageUrl,
        'ticketTiers': ticketTiers.map((e) => e.toJson()).toList(),
      };

  HostEventItem copyWith({
    String? id,
    String? title,
    DateTime? eventDate,
    String? venue,
    int? totalRegistrations,
    int? checkedInCount,
    int? totalCapacity,
    int? revenueInPaise,
    bool? isLive,
    String? coverImageUrl,
    List<TicketType>? ticketTiers,
  }) {
    return HostEventItem(
      id: id ?? this.id,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      venue: venue ?? this.venue,
      totalRegistrations: totalRegistrations ?? this.totalRegistrations,
      checkedInCount: checkedInCount ?? this.checkedInCount,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      revenueInPaise: revenueInPaise ?? this.revenueInPaise,
      isLive: isLive ?? this.isLive,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      ticketTiers: ticketTiers ?? this.ticketTiers,
    );
  }
}

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
      attendeeName: json['attendeeName'] ?? json['name'] ?? 'Attendee',
      attendeeEmail: json['attendeeEmail'] ?? json['email'] ?? '',
      ticketType: json['ticketType'] ?? json['ticket_type'] ?? 'General',
      qrCode: json['qrCode'] ?? json['qr_code'] ?? '',
      isCheckedIn: json['isCheckedIn'] ?? json['is_checked_in'] ?? false,
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

enum CheckInResultStatus { VALID, ALREADY_CHECKED_IN, INVALID }

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
