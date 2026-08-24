import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../../domain/entities/host_entities.dart';

class HostRemoteDataSource {
  final Dio _dio;
  HostRemoteDataSource(this._dio);

  List<dynamic> _extractList(dynamic data, List<String> possibleKeys) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in possibleKeys) {
        if (data[key] is List) return data[key] as List;
      }
      if (data['data'] is List) return data['data'] as List;
      if (data['items'] is List) return data['items'] as List;
      if (data['events'] is List) return data['events'] as List;
      if (data['registrations'] is List) return data['registrations'] as List;
    }
    return const [];
  }

  // ── Hosted Events List & Details ──────────────────────────────────────────

  Future<List<HostEventItem>> getEvents() async {
    try {
      final res = await _dio.get(ApiConstants.hostEvents);
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['events', 'data', 'items']);
        return list
            .whereType<Map<String, dynamic>>()
            .map(HostEventItem.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<HostEventItem?> getEventDetails(String id) async {
    try {
      final res = await _dio.get('${ApiConstants.hostEvents}/$id');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return HostEventItem.fromJson(res.data as Map<String, dynamic>);
      }
      final list = await getEvents();
      return list.firstWhere(
        (e) => e.id == id || e.slug == id,
        orElse: () => throw const NetworkException('Event not found'),
      );
    } on DioException catch (e) {
      try {
        final list = await getEvents();
        return list.firstWhere((e) => e.id == id || e.slug == id);
      } catch (_) {}
      throw NetworkException.fromDioError(e);
    }
  }

  // ── Event Lifecycle Actions ───────────────────────────────────────────────

  Future<HostEventItem> createEvent(CreateEventRequest req) async {
    try {
      final res = await _dio.post(ApiConstants.hostEvents, data: req.toJson());
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map<String, dynamic>) {
        return HostEventItem.fromJson(res.data as Map<String, dynamic>);
      }
      throw const NetworkException('Failed to create event');
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<HostEventItem> updateEvent(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('${ApiConstants.hostEvents}/$id', data: data);
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return HostEventItem.fromJson(res.data as Map<String, dynamic>);
      }
      throw const NetworkException('Failed to update event');
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<HostEventItem> publishEvent(String id) async {
    try {
      final res = await _dio.patch('${ApiConstants.hostEvents}/$id/publish');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return HostEventItem.fromJson(res.data as Map<String, dynamic>);
      }
      return HostEventItem(
        id: id,
        title: 'Published Event',
        status: 'PUBLISHED',
        startDatetime: DateTime.now(),
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── Google Meet Auto-Generator ────────────────────────────────────────────

  Future<GenerateMeetResponse> generateMeetRoom(String title) async {
    try {
      final res = await _dio.post(
        ApiConstants.hostGenerateMeet,
        data: {'title': title},
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map<String, dynamic>) {
        return GenerateMeetResponse.fromJson(res.data as Map<String, dynamic>);
      }
      throw const NetworkException('Failed to generate Google Meet room');
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── Ticket Tiers Manager ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> createTicketTier(
    String eventId,
    CreateTicketTierRequest tier,
  ) async {
    try {
      final res = await _dio.post(
        '${ApiConstants.hostEvents}/$eventId/ticket-types',
        data: tier.toJson(),
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      throw const NetworkException('Failed to create ticket tier');
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateTicketTier(
    String ticketTypeId,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.put(
        '${ApiConstants.hostEvents}/ticket-types/$ticketTypeId',
        data: data,
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      throw const NetworkException('Failed to update ticket tier');
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> deleteTicketTier(String ticketTypeId) async {
    try {
      final res = await _dio.delete(
        '${ApiConstants.hostEvents}/ticket-types/$ticketTypeId',
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── Attendee Approval Queue ───────────────────────────────────────────────

  Future<List<HostRegistration>> getAttendeeQueue(
    String eventId, {
    String? status,
  }) async {
    try {
      final path = ApiConstants.hostAttendeeQueue.replaceAll('{id}', eventId);
      final res = await _dio.get(
        path,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
        },
      );
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['registrations', 'attendees', 'data', 'items']);
        return list
            .whereType<Map<String, dynamic>>()
            .map(HostRegistration.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> approveRegistration(
    String registrationId, {
    String? hostMessage,
  }) async {
    try {
      final path = ApiConstants.hostApproveRegistration.replaceAll('{id}', registrationId);
      final res = await _dio.patch(
        path,
        data: {
          if (hostMessage != null && hostMessage.isNotEmpty) 'hostMessage': hostMessage,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> declineRegistration(
    String registrationId, {
    String? hostMessage,
  }) async {
    try {
      final path = ApiConstants.hostDeclineRegistration.replaceAll('{id}', registrationId);
      final res = await _dio.patch(
        path,
        data: {
          if (hostMessage != null && hostMessage.isNotEmpty) 'hostMessage': hostMessage,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── Check-In Scanner & Gate System ────────────────────────────────────────

  Future<CheckInResponse> checkInAttendee(String eventId, String qrCode) async {
    try {
      final path = ApiConstants.hostCheckIn.replaceAll('{id}', eventId);
      final res = await _dio.post(path, data: {'qrCode': qrCode.trim()});
      if (res.data is Map<String, dynamic>) {
        return CheckInResponse.fromJson(res.data as Map<String, dynamic>);
      }
      return CheckInResponse(
        success: res.statusCode == 200 || res.statusCode == 201,
        message: 'Pass checked in successfully',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return CheckInResponse.fromJson(data);
      }
      final errMsg = data is Map && data['message'] != null
          ? data['message'].toString()
          : (e.message ?? 'Check-in validation failed');
      return CheckInResponse(
        success: false,
        isDuplicate: false,
        message: errMsg,
      );
    } catch (e) {
      return CheckInResponse(
        success: false,
        isDuplicate: false,
        message: e.toString(),
      );
    }
  }

  Future<BulkCheckInResponse> bulkCheckIn(
    String eventId, {
    required String registrationId,
    int? count,
  }) async {
    try {
      final path = ApiConstants.hostCheckInBulk.replaceAll('{id}', eventId);
      final res = await _dio.post(
        path,
        data: {
          'registrationId': registrationId,
          if (count != null && count > 0) 'count': count,
        },
      );
      if (res.data is Map<String, dynamic>) {
        return BulkCheckInResponse.fromJson(res.data as Map<String, dynamic>);
      }
      return const BulkCheckInResponse(
        success: true,
        message: 'Bulk check-in completed',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return BulkCheckInResponse.fromJson(data);
      }
      throw NetworkException.fromDioError(e);
    }
  }

  Future<GateCheckInStats> getCheckInStats(String eventId) async {
    try {
      final path = ApiConstants.hostCheckInStats.replaceAll('{id}', eventId);
      final res = await _dio.get(path);
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return GateCheckInStats.fromJson(res.data as Map<String, dynamic>);
      }
      return GateCheckInStats(eventId: eventId, eventTitle: 'Event Gate');
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getCalendarLink(String eventId) async {
    try {
      final path = ApiConstants.eventCalendarLink.replaceAll('{id}', eventId);
      final res = await _dio.get(path);
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return const {};
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // Legacy support for older screens
  Future<List<AttendeeRecord>> getAttendees(String eventId) async {
    try {
      final list = await getAttendeeQueue(eventId);
      return list
          .map((r) => AttendeeRecord(
                id: r.id,
                attendeeName: r.userName,
                attendeeEmail: r.userEmail,
                ticketType: r.ticketTypeName,
                qrCode: r.tickets.isNotEmpty ? (r.tickets.first.qrCode ?? '') : '',
                isCheckedIn: r.isCheckedIn,
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<QrCheckInResult> scanQrCode(String eventId, String qrData) async {
    try {
      final res = await checkInAttendee(eventId, qrData);
      return QrCheckInResult(
        status: res.status,
        message: res.message,
        attendee: AttendeeRecord(
          id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
          attendeeName: res.attendeeName ?? 'Attendee',
          attendeeEmail: res.attendeeEmail ?? '',
          ticketType: res.ticketTypeName ?? 'Pass',
          qrCode: qrData,
          isCheckedIn: res.success,
          checkedInAt: res.checkedInAt,
        ),
      );
    } catch (e) {
      return QrCheckInResult(
        status: CheckInResultStatus.INVALID,
        message: e.toString(),
      );
    }
  }

  Future<bool> manualCheckIn(String eventId, String attendeeId) async {
    try {
      final res = await checkInAttendee(eventId, attendeeId);
      return res.success;
    } catch (_) {
      return false;
    }
  }
}


