import '../../../auth/domain/entities/user_entity.dart';
import '../../../bookings/domain/entities/booking_entities.dart';
import '../../domain/entities/organizer_entities.dart';
import '../../domain/repositories/organizer_repository.dart';
import '../datasources/organizer_local_datasource.dart';
import '../datasources/organizer_remote_datasource.dart';

class OrganizerRepositoryImpl implements OrganizerRepository {
  final OrganizerRemoteDataSource _remote;
  final OrganizerLocalDataSource _local;

  OrganizerRepositoryImpl(this._remote, [OrganizerLocalDataSource? local])
      : _local = local ?? OrganizerLocalDataSource();

  @override
  Future<OrganizerProfile> getProfile() async {
    try {
      final remoteProfile = await _remote.getProfile();
      _local.updateProfile(remoteProfile);
      return remoteProfile;
    } catch (_) {
      return _local.getProfile();
    }
  }

  @override
  Future<void> updateProfile(OrganizerProfile profile) async {
    _local.updateProfile(profile);
  }

  @override
  Future<void> setKycStatusForTesting(
    KycStatus status, {
    String? reason,
    bool? isSetupComplete,
  }) async {
    _local.setKycStatus(status, reason: reason, isSetupComplete: isSetupComplete);
  }

  @override
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
  }) async {
    try {
      await _remote.submitKyc(
        businessName: businessName,
        panGst: panGst,
        bankAccount: bankAccount,
        ifsc: ifsc,
      );
    } catch (_) {}
    return _local.submitKyc(
      businessName: businessName,
      displayName: displayName,
      bio: bio,
      city: city,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      categories: categories,
      panGst: panGst,
      bankAccount: bankAccount,
      ifsc: ifsc,
      accountHolder: accountHolder,
    );
  }

  @override
  Future<OrganizerProfile> resubmitKyc({
    required String businessName,
    required String panGst,
    required String bankAccount,
    required String ifsc,
    required String accountHolder,
  }) async {
    try {
      // Remote call if backend is available
    } catch (_) {}
    return _local.resubmitKyc(
      businessName: businessName,
      panGst: panGst,
      bankAccount: bankAccount,
      ifsc: ifsc,
      accountHolder: accountHolder,
    );
  }

  @override
  Future<OrganizerProfile> setOperationalMode(OperationalMode mode) async {
    return _local.setOperationalMode(mode);
  }

  @override
  Future<OrganizerProfile> selectSubscriptionTier(SubscriptionTier tier) async {
    return _local.selectSubscriptionTier(tier);
  }

  // ── Packages ───────────────────────────────────────────────────────────────

  @override
  Future<List<OrganizerPackage>> getPackages() async {
    return _local.getPackages();
  }

  @override
  Future<OrganizerPackage> createPackage(OrganizerPackage pkg) async {
    return _local.createPackage(pkg);
  }

  @override
  Future<OrganizerPackage> updatePackage(OrganizerPackage pkg) async {
    return _local.updatePackage(pkg);
  }

  @override
  Future<bool> togglePackageStatus(String id) async {
    return _local.togglePackageStatus(id);
  }

  // ── Standalone Services ────────────────────────────────────────────────────

  @override
  Future<List<OrganizerService>> getServices() async {
    return _local.getServices();
  }

  @override
  Future<OrganizerService> createService(OrganizerService srv) async {
    return _local.createService(srv);
  }

  @override
  Future<OrganizerService> updateService(OrganizerService srv) async {
    return _local.updateService(srv);
  }

  @override
  Future<bool> toggleServiceStatus(String id) async {
    return _local.toggleServiceStatus(id);
  }

  // ── Portfolio ──────────────────────────────────────────────────────────────

  @override
  Future<List<PortfolioMediaItem>> getPortfolio() async {
    return _local.getPortfolio();
  }

  @override
  Future<PortfolioMediaItem> addPortfolioMedia(PortfolioMediaItem item) async {
    return _local.addPortfolioMedia(item);
  }

  @override
  Future<bool> deletePortfolioMedia(String id) async {
    return _local.deletePortfolioMedia(id);
  }

  // ── Bookings & SLA ─────────────────────────────────────────────────────────

  @override
  Future<List<VendorBooking>> getBookingInbox() async {
    try {
      final remote = await _remote.getInbox();
      if (remote.isNotEmpty) return remote;
    } catch (_) {}
    return _local.getInbox();
  }

  @override
  Future<bool> acceptBooking(String bookingId) async {
    try {
      await _remote.acceptBooking(bookingId);
    } catch (_) {}
    return _local.acceptBooking(bookingId);
  }

  @override
  Future<bool> rejectBooking(String bookingId, {String? reason}) async {
    try {
      await _remote.rejectBooking(bookingId);
    } catch (_) {}
    return _local.rejectBooking(bookingId, reason: reason);
  }

  @override
  Future<bool> proposeReschedule(
      String bookingId, DateTime newDate, String note) async {
    try {
      await _remote.proposeReschedule(bookingId, newDate, note);
    } catch (_) {}
    return _local.proposeReschedule(bookingId, newDate, note);
  }

  // ── Availability Calendar ──────────────────────────────────────────────────

  @override
  Future<List<AvailabilitySlot>> getAvailability(DateTime month) async {
    try {
      final remote = await _remote.getAvailability(month);
      if (remote.isNotEmpty) return remote;
    } catch (_) {}
    return _local.getAvailability(month);
  }

  @override
  Future<bool> toggleDateBlocked(DateTime date, {String? reason}) async {
    try {
      await _remote.toggleDateBlocked(date, reason: reason);
    } catch (_) {}
    return _local.toggleDateBlocked(date, reason: reason);
  }

  // ── Payout Ledger ──────────────────────────────────────────────────────────

  @override
  Future<PayoutLedger> getPayoutLedger() async {
    try {
      return await _remote.getPayoutLedger();
    } catch (_) {
      return _local.getPayoutLedger();
    }
  }

  // ── Legacy Catalog Methods ─────────────────────────────────────────────────

  @override
  Future<List<CatalogItem>> getCatalogItems() async {
    return _local.getCatalog();
  }

  @override
  Future<bool> toggleItemStatus(String itemId) async {
    try {
      await _remote.toggleItemStatus(itemId);
    } catch (_) {}
    return _local.toggleItemStatus(itemId);
  }
}
