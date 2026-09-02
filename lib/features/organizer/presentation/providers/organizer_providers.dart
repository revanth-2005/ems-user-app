import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../bookings/domain/entities/booking_entities.dart';
import '../../data/datasources/organizer_local_datasource.dart';
import '../../data/datasources/organizer_remote_datasource.dart';
import '../../data/repositories/organizer_repository_impl.dart';
import '../../domain/entities/organizer_entities.dart';
import '../../domain/repositories/organizer_repository.dart';

// ── Shared Local Data Source Singleton ───────────────────────────────────────

final organizerLocalDataSourceProvider = Provider<OrganizerLocalDataSource>((_) {
  return OrganizerLocalDataSource();
});

// ── Repository Provider ──────────────────────────────────────────────────────

final organizerRemoteDataSourceProvider =
    Provider<OrganizerRemoteDataSource>((_) {
  return OrganizerRemoteDataSource(DioClient.instance.dio);
});

final organizerRepositoryProvider = Provider<OrganizerRepository>((ref) {
  final remote = ref.watch(organizerRemoteDataSourceProvider);
  final local = ref.watch(organizerLocalDataSourceProvider);
  return OrganizerRepositoryImpl(remote, local);
});

// ── Profile Notifier ─────────────────────────────────────────────────────────

final organizerProfileProvider =
    AsyncNotifierProvider<OrganizerProfileNotifier, OrganizerProfile>(
        OrganizerProfileNotifier.new);

class OrganizerProfileNotifier extends AsyncNotifier<OrganizerProfile> {
  @override
  Future<OrganizerProfile> build() async {
    final repo = ref.watch(organizerRepositoryProvider);
    return repo.getProfile();
  }

  Future<void> refreshProfile() async {
    final repo = ref.read(organizerRepositoryProvider);
    state = const AsyncLoading();
    state = AsyncData(await repo.getProfile());
  }

  Future<void> setKycStatusForTesting(
    KycStatus status, {
    String? reason,
    String? rejectionReason,
    bool? isSetupComplete,
  }) async {
    final repo = ref.read(organizerRepositoryProvider);
    await repo.setKycStatusForTesting(
      status,
      reason: rejectionReason ?? reason,
      isSetupComplete: isSetupComplete,
    );
    state = AsyncData(await repo.getProfile());
  }

  Future<void> submitKyc({
    required String businessName,
    required String displayName,
    required String bio,
    required String city,
    required String contactEmail,
    required String contactPhone,
    required List<String> categories,
    required String panGst,
    required String bankAccount,
    required String ifsc,
    required String accountHolder,
  }) async {
    final repo = ref.read(organizerRepositoryProvider);
    state = const AsyncLoading();
    final updated = await repo.submitKyc(
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
    state = AsyncData(updated);
  }

  Future<void> resubmitKyc({
    required String businessName,
    required String panGst,
    required String bankAccount,
    required String ifsc,
    required String accountHolder,
  }) async {
    final repo = ref.read(organizerRepositoryProvider);
    state = const AsyncLoading();
    final updated = await repo.resubmitKyc(
      businessName: businessName,
      panGst: panGst,
      bankAccount: bankAccount,
      ifsc: ifsc,
      accountHolder: accountHolder,
    );
    state = AsyncData(updated);
  }

  Future<void> setOperationalMode(OperationalMode mode) async {
    final repo = ref.read(organizerRepositoryProvider);
    final updated = await repo.setOperationalMode(mode);
    state = AsyncData(updated);
  }

  Future<void> selectSubscriptionTier(SubscriptionTier tier) async {
    final repo = ref.read(organizerRepositoryProvider);
    final updated = await repo.selectSubscriptionTier(tier);
    state = AsyncData(updated);
  }
}

// ── Packages Notifier ────────────────────────────────────────────────────────

final organizerPackagesProvider =
    AsyncNotifierProvider<OrganizerPackagesNotifier, List<OrganizerPackage>>(
        OrganizerPackagesNotifier.new);

class OrganizerPackagesNotifier extends AsyncNotifier<List<OrganizerPackage>> {
  @override
  Future<List<OrganizerPackage>> build() async {
    final repo = ref.watch(organizerRepositoryProvider);
    return repo.getPackages();
  }

  Future<void> createPackage(OrganizerPackage pkg) async {
    final repo = ref.read(organizerRepositoryProvider);
    await repo.createPackage(pkg);
    state = AsyncData(await repo.getPackages());
    // Refresh profile count
    ref.read(organizerProfileProvider.notifier).refreshProfile();
  }

  Future<void> updatePackage(OrganizerPackage pkg) async {
    final repo = ref.read(organizerRepositoryProvider);
    await repo.updatePackage(pkg);
    state = AsyncData(await repo.getPackages());
  }

  Future<bool> togglePackageStatus(String id) async {
    final repo = ref.read(organizerRepositoryProvider);
    final success = await repo.togglePackageStatus(id);
    state = AsyncData(await repo.getPackages());
    ref.read(organizerProfileProvider.notifier).refreshProfile();
    return success;
  }
}

// ── Standalone Services Notifier ─────────────────────────────────────────────

final organizerServicesProvider =
    AsyncNotifierProvider<OrganizerServicesNotifier, List<OrganizerService>>(
        OrganizerServicesNotifier.new);

class OrganizerServicesNotifier extends AsyncNotifier<List<OrganizerService>> {
  @override
  Future<List<OrganizerService>> build() async {
    final repo = ref.watch(organizerRepositoryProvider);
    return repo.getServices();
  }

  Future<void> createService(OrganizerService srv) async {
    final repo = ref.read(organizerRepositoryProvider);
    await repo.createService(srv);
    state = AsyncData(await repo.getServices());
    ref.read(organizerProfileProvider.notifier).refreshProfile();
  }

  Future<void> updateService(OrganizerService srv) async {
    final repo = ref.read(organizerRepositoryProvider);
    await repo.updateService(srv);
    state = AsyncData(await repo.getServices());
  }

  Future<bool> toggleServiceStatus(String id) async {
    final repo = ref.read(organizerRepositoryProvider);
    final success = await repo.toggleServiceStatus(id);
    state = AsyncData(await repo.getServices());
    ref.read(organizerProfileProvider.notifier).refreshProfile();
    return success;
  }
}

// ── Portfolio Notifier ───────────────────────────────────────────────────────

final organizerPortfolioProvider =
    AsyncNotifierProvider<OrganizerPortfolioNotifier, List<PortfolioMediaItem>>(
        OrganizerPortfolioNotifier.new);

class OrganizerPortfolioNotifier extends AsyncNotifier<List<PortfolioMediaItem>> {
  @override
  Future<List<PortfolioMediaItem>> build() async {
    final repo = ref.watch(organizerRepositoryProvider);
    return repo.getPortfolio();
  }

  Future<void> addMedia(PortfolioMediaItem item) async {
    final repo = ref.read(organizerRepositoryProvider);
    await repo.addPortfolioMedia(item);
    state = AsyncData(await repo.getPortfolio());
  }

  Future<void> deleteMedia(String id) async {
    final repo = ref.read(organizerRepositoryProvider);
    await repo.deletePortfolioMedia(id);
    state = AsyncData(await repo.getPortfolio());
  }
}

// ── Booking Inbox Notifier ────────────────────────────────────────────────────

final bookingInboxProvider =
    AsyncNotifierProvider<BookingInboxNotifier, List<VendorBooking>>(
        BookingInboxNotifier.new);

class BookingInboxNotifier extends AsyncNotifier<List<VendorBooking>> {
  @override
  Future<List<VendorBooking>> build() async {
    final repo = ref.watch(organizerRepositoryProvider);
    return repo.getBookingInbox();
  }

  Future<void> acceptBooking(String bookingId) async {
    final repo = ref.read(organizerRepositoryProvider);
    await repo.acceptBooking(bookingId);
    state = AsyncData(await repo.getBookingInbox());
    ref.invalidate(organizerAvailabilityProvider);
  }

  Future<void> rejectBooking(String bookingId, {String? reason}) async {
    final repo = ref.read(organizerRepositoryProvider);
    await repo.rejectBooking(bookingId, reason: reason);
    state = AsyncData(await repo.getBookingInbox());
  }

  Future<void> proposeReschedule(
      String bookingId, DateTime newDate, String note) async {
    final repo = ref.read(organizerRepositoryProvider);
    await repo.proposeReschedule(bookingId, newDate, note);
    state = AsyncData(await repo.getBookingInbox());
  }
}

// ── Availability Provider ─────────────────────────────────────────────────────

final selectedCalendarMonthProvider =
    StateProvider<DateTime>((_) => DateTime.now());

final organizerAvailabilityProvider =
    FutureProvider<List<AvailabilitySlot>>((ref) async {
  final repo = ref.watch(organizerRepositoryProvider);
  final month = ref.watch(selectedCalendarMonthProvider);
  return repo.getAvailability(month);
});

// ── Payout Ledger Provider ────────────────────────────────────────────────────

final payoutLedgerProvider = FutureProvider<PayoutLedger>((ref) async {
  final repo = ref.watch(organizerRepositoryProvider);
  return repo.getPayoutLedger();
});

// ── Legacy Catalog Manager Notifier ───────────────────────────────────────────

final catalogManagerProvider =
    AsyncNotifierProvider<CatalogManagerNotifier, List<CatalogItem>>(
        CatalogManagerNotifier.new);

class CatalogManagerNotifier extends AsyncNotifier<List<CatalogItem>> {
  @override
  Future<List<CatalogItem>> build() async {
    final repo = ref.watch(organizerRepositoryProvider);
    return repo.getCatalogItems();
  }

  Future<void> toggleItem(String itemId) async {
    final repo = ref.read(organizerRepositoryProvider);
    await repo.toggleItemStatus(itemId);
    state = AsyncData(await repo.getCatalogItems());
  }
}
