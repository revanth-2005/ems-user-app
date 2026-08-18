import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../bookings/domain/entities/booking_entities.dart';
import '../../data/datasources/organizer_local_datasource.dart';
import '../../data/repositories/organizer_repository_impl.dart';
import '../../domain/entities/organizer_entities.dart';
import '../../domain/repositories/organizer_repository.dart';

// ── Repository Provider ───────────────────────────────────────────────────

final organizerLocalDataSourceProvider =
    Provider<OrganizerLocalDataSource>((_) {
  return OrganizerLocalDataSource();
});

final organizerRepositoryProvider = Provider<OrganizerRepository>((ref) {
  return OrganizerRepositoryImpl(ref.watch(organizerLocalDataSourceProvider));
});

// ── Profile Provider ──────────────────────────────────────────────────────

final organizerProfileProvider =
    FutureProvider<OrganizerProfile>((ref) async {
  final repo = ref.watch(organizerRepositoryProvider);
  return repo.getProfile();
});

// ── Booking Inbox Notifier ────────────────────────────────────────────────

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
  }

  Future<void> rejectBooking(String bookingId) async {
    final repo = ref.read(organizerRepositoryProvider);
    await repo.rejectBooking(bookingId);
    state = AsyncData(await repo.getBookingInbox());
  }

  Future<void> proposeReschedule(
      String bookingId, DateTime newDate, String note) async {
    final repo = ref.read(organizerRepositoryProvider);
    await repo.proposeReschedule(bookingId, newDate, note);
    state = AsyncData(await repo.getBookingInbox());
  }
}

// ── Catalog Manager Notifier ──────────────────────────────────────────────

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

// ── Payout Ledger Provider ────────────────────────────────────────────────

final payoutLedgerProvider = FutureProvider<PayoutLedger>((ref) async {
  final repo = ref.watch(organizerRepositoryProvider);
  return repo.getPayoutLedger();
});

// ── Availability Provider ─────────────────────────────────────────────────

final selectedCalendarMonthProvider = StateProvider<DateTime>((_) => DateTime.now());

final organizerAvailabilityProvider =
    FutureProvider<List<AvailabilitySlot>>((ref) async {
  final repo = ref.watch(organizerRepositoryProvider);
  final month = ref.watch(selectedCalendarMonthProvider);
  return repo.getAvailability(month);
});
