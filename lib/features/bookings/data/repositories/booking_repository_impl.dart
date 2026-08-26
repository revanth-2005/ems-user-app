import '../../domain/entities/booking_entities.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource _remote;

  BookingRepositoryImpl(this._remote);

  @override
  Future<List<VendorBooking>> getMyBookings() async {
    return _remote.getMyBookings();
  }

  @override
  Future<List<EventTicketPass>> getMyTickets() async {
    return _remote.getMyTickets();
  }

  @override
  Future<bool> acceptReschedule(String bookingId) async {
    return _remote.acceptReschedule(bookingId);
  }

  @override
  Future<bool> cancelBooking(String bookingId) async {
    return _remote.cancelBooking(bookingId);
  }

  @override
  Future<RefundQuote> getRegistrationRefundQuote(String registrationId) async {
    return _remote.getRegistrationRefundQuote(registrationId);
  }

  @override
  Future<CancellationResult> cancelRegistration(
    String registrationId, {
    String reason = 'Personal scheduling conflict',
  }) async {
    return _remote.cancelRegistration(registrationId, reason: reason);
  }

  @override
  Future<RefundQuote> getBookingRefundQuote(String bookingId) async {
    return _remote.getBookingRefundQuote(bookingId);
  }

  @override
  Future<CancellationResult> cancelBookingWithRefund(
    String bookingId, {
    String reason = 'Customer request',
  }) async {
    return _remote.cancelBookingWithRefund(bookingId, reason: reason);
  }

  @override
  Future<bool> checkoutCart(CartState cart) async {
    return _remote.checkoutCart(cart);
  }

  @override
  Future<Map<String, dynamic>?> addToCartRemote({
    String? packageId,
    String? serviceId,
    required String eventDate,
    String? endDate,
    String? startTime,
    String? endTime,
    int quantity = 1,
  }) async {
    return _remote.addToCartRemote(
      packageId: packageId,
      serviceId: serviceId,
      eventDate: eventDate,
      endDate: endDate,
      startTime: startTime,
      endTime: endTime,
      quantity: quantity,
    );
  }

  @override
  Future<Map<String, dynamic>?> getCartRemote() async {
    return _remote.getCartRemote();
  }

  @override
  Future<Map<String, dynamic>?> updateCartItemRemote({
    required String itemId,
    String? startDate,
    String? startTime,
    String? endTime,
    int? quantity,
  }) async {
    return _remote.updateCartItemRemote(
      itemId: itemId,
      startDate: startDate,
      startTime: startTime,
      endTime: endTime,
      quantity: quantity,
    );
  }

  @override
  Future<bool> removeCartItemRemote(String itemId) async {
    return _remote.removeCartItemRemote(itemId);
  }

  @override
  Future<bool> clearCartRemote() async {
    return _remote.clearCartRemote();
  }

  @override
  Future<Map<String, dynamic>> processCheckout({
    String? couponCode,
    String? notes,
    String? eventId,
  }) async {
    return _remote.processCheckout(
      couponCode: couponCode,
      notes: notes,
      eventId: eventId,
    );
  }

  @override
  Future<Map<String, dynamic>> createPaymentOrder({
    required int amountInPaise,
    String paymentType = 'DEPOSIT',
    String currency = 'INR',
    String? bookingId,
    String? registrationId,
    String? subscriptionId,
    String? orderId,
  }) async {
    return _remote.createPaymentOrder(
      amountInPaise: amountInPaise,
      paymentType: paymentType,
      currency: currency,
      bookingId: bookingId,
      registrationId: registrationId,
      subscriptionId: subscriptionId,
      orderId: orderId,
    );
  }

  @override
  Future<Map<String, dynamic>> verifyPayment({
    required String gatewayOrderId,
    required String gatewayPaymentId,
    required String gatewaySignature,
  }) async {
    return _remote.verifyPayment(
      gatewayOrderId: gatewayOrderId,
      gatewayPaymentId: gatewayPaymentId,
      gatewaySignature: gatewaySignature,
    );
  }
}
