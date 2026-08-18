import '../../../bookings/domain/entities/booking_entities.dart';
import '../../domain/entities/organizer_entities.dart';
import '../../domain/repositories/organizer_repository.dart';
import '../datasources/organizer_remote_datasource.dart';

class OrganizerRepositoryImpl implements OrganizerRepository {
  final OrganizerRemoteDataSource _remote;

  OrganizerRepositoryImpl(this._remote);

  @override
  Future<OrganizerProfile> getProfile() async {
    return _remote.getProfile();
  }

  @override
  Future<List<VendorBooking>> getBookingInbox() async {
    return _remote.getInbox();
  }

  @override
  Future<bool> acceptBooking(String bookingId) async {
    return _remote.acceptBooking(bookingId);
  }

  @override
  Future<bool> rejectBooking(String bookingId) async {
    return _remote.rejectBooking(bookingId);
  }

  @override
  Future<bool> proposeReschedule(
      String bookingId, DateTime newDate, String note) async {
    return _remote.proposeReschedule(bookingId, newDate, note);
  }

  @override
  Future<List<CatalogItem>> getCatalogItems() async {
    return _remote.getCatalog();
  }

  @override
  Future<bool> toggleItemStatus(String itemId) async {
    return _remote.toggleItemStatus(itemId);
  }

  @override
  Future<List<AvailabilitySlot>> getAvailability(DateTime month) async {
    return _remote.getAvailability(month);
  }

  @override
  Future<bool> toggleDateBlocked(DateTime date, {String? reason}) async {
    return _remote.toggleDateBlocked(date, reason: reason);
  }

  @override
  Future<PayoutLedger> getPayoutLedger() async {
    return _remote.getPayoutLedger();
  }

  @override
  Future<bool> submitKyc({
    required String businessName,
    required String panGst,
    required String bankAccount,
    required String ifsc,
  }) async {
    return _remote.submitKyc(
      businessName: businessName,
      panGst: panGst,
      bankAccount: bankAccount,
      ifsc: ifsc,
    );
  }
}
