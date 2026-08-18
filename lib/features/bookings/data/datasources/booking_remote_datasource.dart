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

  Future<Map<String, dynamic>> processCheckout({
    String? couponCode,
    String? notes,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.checkout,
        data: {
          if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
          'notes': notes ?? 'Booked via EMS Mobile App',
        },
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      throw Exception('Checkout failed with status ${res.statusCode}');
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> createPaymentOrder({
    required String orderId,
    required int amountInPaise,
    String paymentType = 'DEPOSIT',
    String currency = 'INR',
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.createPaymentOrder,
        data: {
          'orderId': orderId,
          'amountInPaise': amountInPaise,
          'paymentType': paymentType,
          'currency': currency,
        },
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      throw Exception('Create payment order failed');
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String gatewayOrderId,
    required String gatewayPaymentId,
    required String gatewaySignature,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.verifyPayment,
        data: {
          'gatewayOrderId': gatewayOrderId,
          'gatewayPaymentId': gatewayPaymentId,
          'gatewaySignature': gatewaySignature,
        },
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      throw Exception('Payment verification failed');
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

  // ── Remote Cart Operations ──────────────────────────────────────────────────

  Future<Map<String, dynamic>?> addToCartRemote({
    String? packageId,
    String? serviceId,
    required String eventDate,
    String? startTime,
    String? endTime,
    int quantity = 1,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (packageId != null) 'packageId': packageId,
        if (serviceId != null) 'serviceId': serviceId,
        'eventDate': eventDate,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        'quantity': quantity,
      };
      final res = await _dio.post(ApiConstants.cartItems, data: payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return res.data is Map<String, dynamic> ? res.data as Map<String, dynamic> : null;
      }
      return null;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>?> getCartRemote() async {
    try {
      final res = await _dio.get(ApiConstants.cart);
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> removeCartItemRemote(String itemId) async {
    try {
      final res = await _dio.delete('${ApiConstants.cartItems}/$itemId');
      return res.statusCode == 200 || res.statusCode == 204;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}
