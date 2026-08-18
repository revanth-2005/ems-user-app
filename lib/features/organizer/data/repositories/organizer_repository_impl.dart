import '../../../bookings/domain/entities/booking_entities.dart';
import '../../domain/entities/organizer_entities.dart';
import '../../domain/repositories/organizer_repository.dart';
import '../datasources/organizer_local_datasource.dart';

class OrganizerRepositoryImpl implements OrganizerRepository {
  final OrganizerLocalDataSource _local;

  OrganizerRepositoryImpl(this._local);

  @override
  Future<OrganizerProfile> getProfile() async {
    return _local.getProfile();
  }

  @override
  Future<List<VendorBooking>> getBookingInbox() async {
    return _local.getInbox();
  }

  @override
  Future<bool> acceptBooking(String bookingId) async {
    return _local.acceptBooking(bookingId);
  }

  @override
  Future<bool> rejectBooking(String bookingId) async {
    return _local.rejectBooking(bookingId);
  }

  @override
  Future<bool> proposeReschedule(
      String bookingId, DateTime newDate, String note) async {
    return _local.proposeReschedule(bookingId, newDate, note);
  }

  @override
  Future<List<CatalogItem>> getCatalogItems() async {
    return _local.getCatalog();
  }

  @override
  Future<bool> toggleItemStatus(String itemId) async {
    return _local.toggleItemStatus(itemId);
  }

  @override
  Future<List<AvailabilitySlot>> getAvailability(DateTime month) async {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    return List.generate(daysInMonth, (index) {
      final date = DateTime(month.year, month.month, index + 1);
      final isBlocked = index == 4 || index == 18;
      return AvailabilitySlot(
        date: date,
        isBlocked: isBlocked,
        reason: isBlocked ? 'Booked for wedding' : null,
      );
    });
  }

  @override
  Future<bool> toggleDateBlocked(DateTime date, {String? reason}) async {
    return true;
  }

  @override
  Future<PayoutLedger> getPayoutLedger() async {
    return _local.getPayoutLedger();
  }

  @override
  Future<bool> submitKyc({
    required String businessName,
    required String panGst,
    required String bankAccount,
    required String ifsc,
  }) async {
    return _local.submitKyc(businessName, panGst, bankAccount, ifsc);
  }
}
