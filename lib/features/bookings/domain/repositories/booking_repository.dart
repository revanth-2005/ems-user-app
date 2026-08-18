import '../entities/booking_entities.dart';

abstract class BookingRepository {
  Future<List<VendorBooking>> getMyBookings();
  Future<List<EventTicketPass>> getMyTickets();
  Future<bool> acceptReschedule(String bookingId);
  Future<bool> cancelBooking(String bookingId);
  Future<bool> checkoutCart(CartState cart);
  Future<Map<String, dynamic>?> addToCartRemote({
    String? packageId,
    String? serviceId,
    required String eventDate,
    String? startTime,
    String? endTime,
    int quantity = 1,
  });
  Future<Map<String, dynamic>?> getCartRemote();
  Future<bool> removeCartItemRemote(String itemId);
  Future<Map<String, dynamic>> processCheckout({
    String? couponCode,
    String? notes,
  });
  Future<Map<String, dynamic>> createPaymentOrder({
    required String orderId,
    required int amountInPaise,
    String paymentType = 'DEPOSIT',
    String currency = 'INR',
  });
  Future<Map<String, dynamic>> verifyPayment({
    required String gatewayOrderId,
    required String gatewayPaymentId,
    required String gatewaySignature,
  });
}
