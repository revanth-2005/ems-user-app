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
    }
    return const [];
  }

  Future<List<HostEventItem>> getEvents() async {
    try {
      final res = await _dio.get(ApiConstants.hostEvents);
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['events', 'data', 'items']);
        return list
            .map((e) => HostEventItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<HostEventItem> createEvent(HostEventItem event) async {
    try {
      final res = await _dio.post(ApiConstants.hostEvents, data: event.toJson());
      return HostEventItem.fromJson(res.data is Map<String, dynamic> ? res.data : {});
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<List<AttendeeRecord>> getAttendees(String eventId) async {
    try {
      final path = ApiConstants.hostAttendeeQueue.replaceAll('{id}', eventId);
      final res = await _dio.get(path);
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['attendees', 'data', 'items']);
        return list
            .map((e) => AttendeeRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<QrCheckInResult> scanQrCode(String eventId, String qrData) async {
    try {
      final path = ApiConstants.hostCheckIn.replaceAll('{id}', eventId);
      final res = await _dio.post(path, data: {'qrCode': qrData});
      if (res.statusCode == 200) {
        return QrCheckInResult(
          status: CheckInResultStatus.VALID,
          message: 'Pass verified! Welcome to the event.',
          attendee: res.data != null && res.data is Map<String, dynamic>
              ? AttendeeRecord.fromJson(res.data as Map<String, dynamic>)
              : null,
        );
      }
      return QrCheckInResult(
        status: CheckInResultStatus.INVALID,
        message: res.data?['message'] ?? 'Invalid or used ticket pass.',
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> manualCheckIn(String eventId, String attendeeId) async {
    try {
      final path = ApiConstants.hostCheckIn.replaceAll('{id}', eventId);
      final res = await _dio.post(path, data: {'attendeeId': attendeeId});
      return res.statusCode == 200;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}
