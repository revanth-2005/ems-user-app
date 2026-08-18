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
}
