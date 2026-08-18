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
  Future<bool> checkoutCart(CartState cart) async {
    return _remote.checkoutCart(cart);
  }

  @override
  Future<Map<String, dynamic>?> addToCartRemote({
    String? packageId,
    String? serviceId,
    required String eventDate,
    String? startTime,
    String? endTime,
    int quantity = 1,
  }) async {
    return _remote.addToCartRemote(
      packageId: packageId,
      serviceId: serviceId,
      eventDate: eventDate,
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
  Future<bool> removeCartItemRemote(String itemId) async {
    return _remote.removeCartItemRemote(itemId);
  }

  @override
  Future<Map<String, dynamic>> processCheckout({
    String? couponCode,
    String? notes,
  }) async {
    return _remote.processCheckout(couponCode: couponCode, notes: notes);
  }

  @override
  Future<Map<String, dynamic>> createPaymentOrder({
    required String orderId,
    required int amountInPaise,
    String paymentType = 'DEPOSIT',
    String currency = 'INR',
  }) async {
    return _remote.createPaymentOrder(
      orderId: orderId,
      amountInPaise: amountInPaise,
      paymentType: paymentType,
      currency: currency,
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
