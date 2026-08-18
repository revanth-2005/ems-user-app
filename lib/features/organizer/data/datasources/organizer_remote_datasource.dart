import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../../../bookings/domain/entities/booking_entities.dart';
import '../../domain/entities/organizer_entities.dart';

class OrganizerRemoteDataSource {
  final Dio _dio;
  OrganizerRemoteDataSource(this._dio);

  List<dynamic> _extractList(dynamic data, List<String> possibleKeys) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in possibleKeys) {
        if (data[key] is List) return data[key] as List;
      }
      if (data['data'] is List) return data['data'] as List;
      if (data['items'] is List) return data['items'] as List;
    }
    return const [];
  }

  Future<OrganizerProfile> getProfile() async {
    try {
      final res = await _dio.get(ApiConstants.userProfile);
      return OrganizerProfile.fromJson(res.data is Map<String, dynamic> ? res.data : {});
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<List<VendorBooking>> getInbox() async {
    try {
      final res = await _dio.get(ApiConstants.organizerBookings);
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['bookings', 'data', 'items']);
        return list
            .map((e) => VendorBooking.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> acceptBooking(String bookingId) async {
    try {
      final res = await _dio.patch('/organizer/bookings/$bookingId/accept');
      return res.statusCode == 200;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> rejectBooking(String bookingId) async {
    try {
      final res = await _dio.patch('/organizer/bookings/$bookingId/reject');
      return res.statusCode == 200;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> proposeReschedule(
      String bookingId, DateTime newDate, String note) async {
    try {
      final res = await _dio.patch(
        '/organizer/bookings/$bookingId/reschedule',
        data: {
          'proposedDate': newDate.toIso8601String(),
          'note': note,
        },
      );
      return res.statusCode == 200;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<List<CatalogItem>> getCatalog() async {
    try {
      final res = await _dio.get(ApiConstants.organizerPackages);
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['packages', 'services', 'data', 'items']);
        return list
            .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> toggleItemStatus(String itemId) async {
    try {
      final res = await _dio.patch('/organizer/catalog/$itemId/toggle-status');
      return res.statusCode == 200;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<List<AvailabilitySlot>> getAvailability(DateTime month) async {
    try {
      final monthStr = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      final res = await _dio.get(
        ApiConstants.organizerAvailability,
        queryParameters: {'month': monthStr},
      );
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['slots', 'data', 'availability']);
        return list
            .map((e) => AvailabilitySlot.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> toggleDateBlocked(DateTime date, {String? reason}) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final res = await _dio.post(
        ApiConstants.organizerAvailability,
        data: {
          'date': dateStr,
          'reason': reason ?? 'Blocked by organizer',
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<PayoutLedger> getPayoutLedger() async {
    try {
      final res = await _dio.get(ApiConstants.organizerPayouts);
      return PayoutLedger.fromJson(res.data is Map<String, dynamic> ? res.data : {});
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> submitKyc({
    required String businessName,
    required String panGst,
    required String bankAccount,
    required String ifsc,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.organizerRegister,
        data: {
          'businessName': businessName,
          'panGst': panGst,
          'bankAccount': bankAccount,
          'ifsc': ifsc,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}
