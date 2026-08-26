import '../entities/booking_entities.dart';

abstract class BookingRepository {
  Future<List<VendorBooking>> getMyBookings();
  Future<List<EventTicketPass>> getMyTickets();
  Future<bool> acceptReschedule(String bookingId);
  Future<bool> cancelBooking(String bookingId);
  Future<RefundQuote> getRegistrationRefundQuote(String registrationId);
  Future<CancellationResult> cancelRegistration(String registrationId, {String reason = 'Personal scheduling conflict'});
  Future<RefundQuote> getBookingRefundQuote(String bookingId);
  Future<CancellationResult> cancelBookingWithRefund(String bookingId, {String reason = 'Customer request'});
  Future<bool> checkoutCart(CartState cart);
  Future<Map<String, dynamic>?> addToCartRemote({
    String? packageId,
    String? serviceId,
    required String eventDate,
    String? endDate,
    String? startTime,
    String? endTime,
    int quantity = 1,
  });
  Future<Map<String, dynamic>?> getCartRemote();
  Future<Map<String, dynamic>?> updateCartItemRemote({
    required String itemId,
    String? startDate,
    String? startTime,
    String? endTime,
    int? quantity,
  });
  Future<bool> removeCartItemRemote(String itemId);
  Future<bool> clearCartRemote();
  Future<Map<String, dynamic>> processCheckout({
    String? couponCode,
    String? notes,
    String? eventId,
  });
  Future<Map<String, dynamic>> createPaymentOrder({
    required int amountInPaise,
    String paymentType = 'DEPOSIT',
    String currency = 'INR',
    String? bookingId,
    String? registrationId,
    String? subscriptionId,
    String? orderId,
  });
  Future<Map<String, dynamic>> verifyPayment({
    required String gatewayOrderId,
    required String gatewayPaymentId,
    required String gatewaySignature,
  });
}
