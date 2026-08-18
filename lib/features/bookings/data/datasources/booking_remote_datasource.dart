import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../../domain/entities/booking_entities.dart';

class BookingRemoteDataSource {
  final Dio _dio;
  BookingRemoteDataSource(this._dio);

  List<dynamic> _extractList(dynamic data, List<String> possibleKeys) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in possibleKeys) {
        if (data[key] is List) return data[key] as List;
      }
      if (data['data'] is List) return data['data'] as List;
      if (data['items'] is List) return data['items'] as List;
      if (data['bookings'] is List) return data['bookings'] as List;
    }
    return const [];
  }

  Future<List<VendorBooking>> getMyBookings() async {
    try {
      final res = await _dio.get(ApiConstants.myBookings);
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

  Future<List<EventTicketPass>> getMyTickets() async {
    try {
      final res = await _dio.get(ApiConstants.myTickets);
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['tickets', 'data', 'items']);
        return list
            .map((e) => EventTicketPass.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> cancelBooking(String bookingId, {String reason = 'Customer request'}) async {
    try {
      final res = await _dio.patch(
        '/bookings/$bookingId/cancel',
        data: {'reason': reason},
      );
      return res.statusCode == 200;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> acceptReschedule(String bookingId) async {
    try {
      final res = await _dio.patch(
        '/bookings/$bookingId/accept-reschedule',
      );
      return res.statusCode == 200;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> checkoutCart(CartState cart) async {
    try {
      final res = await _dio.post(
        ApiConstants.checkout,
        data: {
          'couponCode': cart.appliedCoupon,
          'notes': 'Booked from mobile app',
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}
