import '../../../auth/domain/entities/user_entity.dart';
import '../../../bookings/domain/entities/booking_entities.dart';
import '../entities/organizer_entities.dart';

abstract class OrganizerRepository {
  Future<OrganizerProfile> getProfile();
  Future<void> updateProfile(OrganizerProfile profile);
  Future<void> setKycStatusForTesting(
    KycStatus status, {
    String? reason,
    bool? isSetupComplete,
  });
  Future<OrganizerProfile> submitKyc({
    required String businessName,
    String displayName = '',
    String bio = '',
    String city = 'Mumbai',
    String contactEmail = '',
    String contactPhone = '',
    List<String> categories = const ['Wedding Planners'],
    required String panGst,
    required String bankAccount,
    required String ifsc,
    String accountHolder = '',
  });
  Future<OrganizerProfile> resubmitKyc({
    required String businessName,
    required String panGst,
    required String bankAccount,
    required String ifsc,
    required String accountHolder,
  });
  Future<OrganizerProfile> setOperationalMode(OperationalMode mode);
  Future<OrganizerProfile> selectSubscriptionTier(SubscriptionTier tier);

  // ── Packages ───────────────────────────────────────────────────────────────
  Future<List<OrganizerPackage>> getPackages();
  Future<OrganizerPackage> createPackage(OrganizerPackage pkg);
  Future<OrganizerPackage> updatePackage(OrganizerPackage pkg);
  Future<bool> togglePackageStatus(String id);

  // ── Standalone Services ────────────────────────────────────────────────────
  Future<List<OrganizerService>> getServices();
  Future<OrganizerService> createService(OrganizerService srv);
  Future<OrganizerService> updateService(OrganizerService srv);
  Future<bool> toggleServiceStatus(String id);

  // ── Portfolio ──────────────────────────────────────────────────────────────
  Future<List<PortfolioMediaItem>> getPortfolio();
  Future<PortfolioMediaItem> addPortfolioMedia(PortfolioMediaItem item);
  Future<bool> deletePortfolioMedia(String id);

  // ── Bookings & SLA ─────────────────────────────────────────────────────────
  Future<List<VendorBooking>> getBookingInbox();
  Future<bool> acceptBooking(String bookingId);
  Future<bool> rejectBooking(String bookingId, {String? reason});
  Future<bool> proposeReschedule(String bookingId, DateTime newDate, String note);

  // ── Availability Calendar ──────────────────────────────────────────────────
  Future<List<AvailabilitySlot>> getAvailability(DateTime month);
  Future<bool> toggleDateBlocked(DateTime date, {String? reason});

  // ── Payout Ledger ──────────────────────────────────────────────────────────
  Future<PayoutLedger> getPayoutLedger();

  // ── Legacy Catalog Methods ─────────────────────────────────────────────────
  Future<List<CatalogItem>> getCatalogItems();
  Future<bool> toggleItemStatus(String itemId);
}
