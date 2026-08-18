import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../home/domain/entities/catalog_entities.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/entities/booking_entities.dart';
import '../../domain/repositories/booking_repository.dart';

// ── Repository Provider ───────────────────────────────────────────────────

final bookingRemoteDataSourceProvider = Provider<BookingRemoteDataSource>((_) {
  return BookingRemoteDataSource(DioClient.instance.dio);
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl(ref.watch(bookingRemoteDataSourceProvider));
});

// ── My Bookings Notifier ──────────────────────────────────────────────────

final myBookingsProvider =
    AsyncNotifierProvider<MyBookingsNotifier, List<VendorBooking>>(
        MyBookingsNotifier.new);

class MyBookingsNotifier extends AsyncNotifier<List<VendorBooking>> {
  @override
  Future<List<VendorBooking>> build() async {
    final repo = ref.watch(bookingRepositoryProvider);
    return repo.getMyBookings();
  }

  Future<void> acceptReschedule(String bookingId) async {
    final repo = ref.read(bookingRepositoryProvider);
    await repo.acceptReschedule(bookingId);
    state = AsyncData(await repo.getMyBookings());
  }

  Future<void> cancelBooking(String bookingId) async {
    final repo = ref.read(bookingRepositoryProvider);
    await repo.cancelBooking(bookingId);
    state = AsyncData(await repo.getMyBookings());
  }
}

// ── Tickets Provider ──────────────────────────────────────────────────────

final myTicketsProvider = FutureProvider<List<EventTicketPass>>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getMyTickets();
});

// ── Cart Notifier ─────────────────────────────────────────────────────────

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState();
  }

  void addPackage(EventPackage pkg, DateTime eventDate) {
    final item = CartItem(
      id: 'cart_${DateTime.now().millisecondsSinceEpoch}',
      packageId: pkg.id,
      itemName: pkg.name,
      coverImageUrl: pkg.coverImageUrl,
      priceInPaise: pkg.priceInPaise,
      depositRequiredPaise: pkg.advanceDepositFlat,
      balanceDuePaise: pkg.priceInPaise - pkg.advanceDepositFlat,
      eventDate: eventDate,
      organizer: pkg.organizer,
    );

    state = state.copyWith(items: [...state.items, item]);
  }

  void addService(StandaloneService srv, DateTime eventDate) {
    final item = CartItem(
      id: 'cart_${DateTime.now().millisecondsSinceEpoch}',
      serviceId: srv.id,
      itemName: srv.name,
      coverImageUrl: srv.coverImageUrl,
      priceInPaise: srv.priceInPaise,
      depositRequiredPaise: srv.depositRequiredPaise,
      balanceDuePaise: srv.priceInPaise - srv.depositRequiredPaise,
      eventDate: eventDate,
      organizer: srv.organizer,
    );

    state = state.copyWith(items: [...state.items, item]);
  }

  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((i) => i.id != itemId).toList(),
    );
  }

  bool applyCoupon(String code) {
    if (code.toUpperCase() == 'SPHERE10') {
      final discount = (state.totalDepositPaise * 0.10).round();
      state = state.copyWith(appliedCoupon: 'SPHERE10', discountPaise: discount);
      return true;
    }
    return false;
  }

  void removeCoupon() {
    state = state.copyWith(appliedCoupon: null, discountPaise: 0);
  }

  void clearCart() {
    state = const CartState();
  }
}
