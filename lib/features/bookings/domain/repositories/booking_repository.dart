import '../entities/booking_entities.dart';

abstract class BookingRepository {
  Future<List<VendorBooking>> getMyBookings();
  Future<List<EventTicketPass>> getMyTickets();
  Future<bool> acceptReschedule(String bookingId);
  Future<bool> cancelBooking(String bookingId);
  Future<bool> checkoutCart(CartState cart);
}
