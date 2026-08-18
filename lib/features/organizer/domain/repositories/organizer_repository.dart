import '../../../bookings/domain/entities/booking_entities.dart';
import '../entities/organizer_entities.dart';

abstract class OrganizerRepository {
  Future<OrganizerProfile> getProfile();
  Future<List<VendorBooking>> getBookingInbox();
  Future<bool> acceptBooking(String bookingId);
  Future<bool> rejectBooking(String bookingId);
  Future<bool> proposeReschedule(String bookingId, DateTime newDate, String note);
  Future<List<CatalogItem>> getCatalogItems();
  Future<bool> toggleItemStatus(String itemId);
  Future<List<AvailabilitySlot>> getAvailability(DateTime month);
  Future<bool> toggleDateBlocked(DateTime date, {String? reason});
  Future<PayoutLedger> getPayoutLedger();
  Future<bool> submitKyc({
    required String businessName,
    required String panGst,
    required String bankAccount,
    required String ifsc,
  });
}
