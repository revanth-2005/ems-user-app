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
        final list = _extractList(res.data, ['tickets', 'data', 'items', 'registrations', 'passes']);
        return list
            .whereType<Map<String, dynamic>>()
            .map(EventTicketPass.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── 💸 Ticket & Booking Cancellation & Refund Engine ───────────────────────

  Future<RefundQuote> getRegistrationRefundQuote(String registrationId) async {
    try {
      final res = await _dio.get('/registrations/$registrationId/refund-quote');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return RefundQuote.fromJson(
          res.data as Map<String, dynamic>,
          type: RefundTargetType.REGISTRATION,
        );
      }
      throw Exception('Failed to fetch refund quote: ${res.statusCode}');
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<CancellationResult> cancelRegistration(
    String registrationId, {
    String reason = 'Personal scheduling conflict',
  }) async {
    try {
      final res = await _dio.post(
        '/registrations/$registrationId/cancel',
        data: {'reason': reason},
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map<String, dynamic>) {
        return CancellationResult.fromJson(res.data as Map<String, dynamic>);
      }
      return CancellationResult(
        success: res.statusCode == 200,
        message: 'Registration cancellation processed',
        id: registrationId,
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<RefundQuote> getBookingRefundQuote(String bookingId) async {
    try {
      final res = await _dio.get('/bookings/$bookingId/refund-quote');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return RefundQuote.fromJson(
          res.data as Map<String, dynamic>,
          type: RefundTargetType.BOOKING,
        );
      }
      throw Exception('Failed to fetch refund quote: ${res.statusCode}');
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<CancellationResult> cancelBookingWithRefund(
    String bookingId, {
    String reason = 'Customer request',
  }) async {
    try {
      final res = await _dio.post(
        '/bookings/$bookingId/cancel',
        data: {'reason': reason},
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map<String, dynamic>) {
        return CancellationResult.fromJson(res.data as Map<String, dynamic>);
      }
      return CancellationResult(
        success: res.statusCode == 200,
        message: 'Booking cancelled successfully.',
        id: bookingId,
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<bool> cancelBooking(String bookingId, {String reason = 'Customer request'}) async {
    try {
      final res = await _dio.post(
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
    String? eventId,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.checkout,
        data: {
          if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
          'notes': notes ?? 'Booked via TrueGather App',
          if (eventId != null && eventId.isNotEmpty) 'eventId': eventId,
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
    required int amountInPaise,
    String paymentType = 'DEPOSIT',
    String currency = 'INR',
    String? bookingId,
    String? registrationId,
    String? subscriptionId,
    String? orderId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'amountInPaise': amountInPaise,
        'paymentType': paymentType,
        'currency': currency,
        if (bookingId != null) 'bookingId': bookingId,
        if (registrationId != null) 'registrationId': registrationId,
        if (subscriptionId != null) 'subscriptionId': subscriptionId,
        if (orderId != null) 'orderId': orderId,
      };
      final res = await _dio.post(
        ApiConstants.createPaymentOrder,
        data: payload,
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      throw Exception('Create payment order failed: ${res.statusCode}');
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
    String? endDate,
    String? startTime,
    String? endTime,
    int quantity = 1,
  }) async {
    try {
      final startDateStr = eventDate.length >= 10 ? eventDate.substring(0, 10) : eventDate;
      final endDateStr = endDate != null && endDate.isNotEmpty
          ? (endDate.length >= 10 ? endDate.substring(0, 10) : endDate)
          : startDateStr;

      final payload = <String, dynamic>{
        if (packageId != null && packageId.isNotEmpty) 'packageId': packageId,
        if (serviceId != null && serviceId.isNotEmpty) 'serviceId': serviceId,
        'startDate': startDateStr,
        'endDate': endDateStr,
        if (startTime != null && startTime.isNotEmpty) 'startTime': startTime,
        if (endTime != null && endTime.isNotEmpty) 'endTime': endTime,
        'quantity': quantity > 0 ? quantity : 1,
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

  Future<Map<String, dynamic>?> updateCartItemRemote({
    required String itemId,
    String? startDate,
    String? startTime,
    String? endTime,
    int? quantity,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (startDate != null)
          'startDate': startDate.length >= 10 ? startDate.substring(0, 10) : startDate,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (quantity != null) 'quantity': quantity,
      };
      final res = await _dio.put('${ApiConstants.cartItems}/$itemId', data: payload);
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

  Future<bool> clearCartRemote() async {
    try {
      final res = await _dio.delete(ApiConstants.cart);
      return res.statusCode == 200 || res.statusCode == 204;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}
