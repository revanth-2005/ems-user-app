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
