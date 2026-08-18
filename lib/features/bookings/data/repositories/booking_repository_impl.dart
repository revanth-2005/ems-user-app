import '../../domain/entities/booking_entities.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_local_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingLocalDataSource _local;

  BookingRepositoryImpl(this._local);

  @override
  Future<List<VendorBooking>> getMyBookings() async {
    return _local.getMyBookings();
  }

  @override
  Future<List<EventTicketPass>> getMyTickets() async {
    return _local.getMyTickets();
  }

  @override
  Future<bool> acceptReschedule(String bookingId) async {
    return _local.acceptReschedule(bookingId);
  }

  @override
  Future<bool> cancelBooking(String bookingId) async {
    return _local.cancelBooking(bookingId);
  }

  @override
  Future<bool> checkoutCart(CartState cart) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return true;
  }
}
