import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../home/domain/entities/catalog_entities.dart';
import '../../../home/presentation/providers/catalog_providers.dart';
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

  Future<void> fetchCart() async {
    try {
      final repo = ref.read(bookingRepositoryProvider);
      final data = await repo.getCartRemote();
      if (data == null) return;

      final itemsRaw = data['items'] as List<dynamic>? ?? [];
      final parsedItems = <CartItem>[];

      for (final raw in itemsRaw) {
        if (raw is Map<String, dynamic>) {
          final itemDetails = raw['itemDetails'] as Map<String, dynamic>? ?? {};
          final orgProfile = raw['organizerProfile'] as Map<String, dynamic>? ?? {};

          final dateStr = raw['eventDate']?.toString() ?? raw['startDate']?.toString();
          final parsedDate = dateStr != null
              ? DateTime.tryParse(dateStr) ?? DateTime.now()
              : DateTime.now();

          parsedItems.add(
            CartItem(
              id: raw['id']?.toString() ?? '',
              packageId: raw['packageId']?.toString(),
              serviceId: raw['serviceId']?.toString(),
              eventDate: parsedDate,
              startTime: raw['startTime']?.toString() ?? '09:00',
              endTime: raw['endTime']?.toString() ?? '18:00',
              quantity: (raw['quantity'] as int?) ?? 1,
              priceInPaise: (raw['priceInPaise'] as int?) ??
                  (raw['totalItemPricePaise'] as int?) ??
                  0,
              depositRequiredPaise: (raw['depositRequiredPaise'] as int?) ?? 0,
              balanceDuePaise: (raw['balanceDuePaise'] as int?) ?? 0,
              itemName: itemDetails['name']?.toString() ?? 'Event Item',
              coverImageUrl: itemDetails['coverImageUrl']?.toString(),
              organizer: OrganizerSummary(
                id: orgProfile['id']?.toString() ?? '',
                businessName: orgProfile['businessName']?.toString() ??
                    orgProfile['displayName']?.toString() ??
                    'Organizer',
                city: orgProfile['city']?.toString() ?? '',
              ),
            ),
          );
        }
      }

      state = state.copyWith(items: parsedItems);
    } catch (_) {}
  }

  Future<void> addPackage(
    EventPackage pkg,
    DateTime eventDate, {
    String? startTime,
    String? endTime,
    int quantity = 1,
  }) async {
    final repo = ref.read(bookingRepositoryProvider);
    final dateStr =
        '${eventDate.year.toString().padLeft(4, '0')}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}';

    // 1. Call Backend API POST /cart/items
    String cartItemId = 'cart_${DateTime.now().millisecondsSinceEpoch}';
    try {
      final res = await repo.addToCartRemote(
        packageId: pkg.id,
        eventDate: dateStr,
        endDate: dateStr,
        startTime: startTime ?? '09:00',
        endTime: endTime ?? '18:00',
        quantity: quantity,
      );
      if (res != null && res['id'] != null) {
        cartItemId = res['id'].toString();
      }
    } catch (_) {
      // Local fallback if offline
    }

    final item = CartItem(
      id: cartItemId,
      packageId: pkg.id,
      itemName: pkg.name,
      coverImageUrl: pkg.coverImageUrl,
      priceInPaise: pkg.priceInPaise,
      depositRequiredPaise: pkg.advanceDepositFlat,
      balanceDuePaise: pkg.priceInPaise - pkg.advanceDepositFlat,
      eventDate: eventDate,
      startTime: startTime ?? '09:00',
      endTime: endTime ?? '18:00',
      quantity: quantity,
      organizer: pkg.organizer,
    );

    state = state.copyWith(items: [...state.items, item]);
  }

  Future<void> addService(
    StandaloneService srv,
    DateTime eventDate, {
    String? startTime,
    String? endTime,
    int quantity = 1,
  }) async {
    final repo = ref.read(bookingRepositoryProvider);
    final dateStr =
        '${eventDate.year.toString().padLeft(4, '0')}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}';

    // 1. Call Backend API POST /cart/items
    String cartItemId = 'cart_${DateTime.now().millisecondsSinceEpoch}';
    try {
      final res = await repo.addToCartRemote(
        serviceId: srv.id,
        eventDate: dateStr,
        endDate: dateStr,
        startTime: startTime ?? '10:00',
        endTime: endTime ?? '14:00',
        quantity: quantity,
      );
      if (res != null && res['id'] != null) {
        cartItemId = res['id'].toString();
      }
    } catch (_) {
      // Local fallback if offline
    }

    final deposit = srv.depositRequiredPaise > 0
        ? srv.depositRequiredPaise
        : srv.priceInPaise;
    final item = CartItem(
      id: cartItemId,
      serviceId: srv.id,
      itemName: srv.name,
      coverImageUrl: srv.coverImageUrl,
      priceInPaise: srv.priceInPaise,
      depositRequiredPaise: deposit,
      balanceDuePaise: srv.priceInPaise - deposit,
      eventDate: eventDate,
      startTime: startTime ?? '10:00',
      endTime: endTime ?? '14:00',
      quantity: quantity,
      organizer: srv.organizer,
    );

    state = state.copyWith(items: [...state.items, item]);
  }

  Future<void> addEvent(
    PublicEvent event, {
    TicketType? ticketType,
    int quantity = 1,
  }) async {
    final selectedTier = ticketType ??
        (event.ticketTypes.isNotEmpty ? event.ticketTypes.first : null);
    final price = selectedTier?.priceInPaise ?? event.minPricePaise;
    final tierName = selectedTier?.name ?? 'General Pass';

    String cartItemId = 'cart_evt_${DateTime.now().millisecondsSinceEpoch}';

    // 1. If it's a free pass or registration, hit the register API
    try {
      if (selectedTier != null && selectedTier.isFree) {
        final catalogRepo = ref.read(catalogRepositoryProvider);
        final res = await catalogRepo.registerForEvent(
          eventId: event.id,
          ticketTypeId: selectedTier.id,
          quantity: quantity,
        );
        if (res.containsKey('id') || res.containsKey('registrationId')) {
          cartItemId = (res['registrationId'] ?? res['id']).toString();
        }
        ref.invalidate(myTicketsProvider);
      }
    } catch (_) {}

    final item = CartItem(
      id: cartItemId,
      itemName: '${event.title}${selectedTier != null ? " ($tierName)" : ""}',
      coverImageUrl: event.coverImageUrl,
      priceInPaise: price,
      depositRequiredPaise: price,
      balanceDuePaise: 0,
      eventDate: event.startDatetime,
      startTime: DateFormatter.formatTime(event.startDatetime),
      endTime: event.endDatetime != null
          ? DateFormatter.formatTime(event.endDatetime!)
          : '23:00',
      quantity: quantity,
      organizer: OrganizerSummary(
        id: event.id,
        businessName: event.hostName,
        displayName: event.hostName,
        city: event.venueCity ?? '',
      ),
    );

    state = state.copyWith(items: [...state.items, item]);
  }

  Future<void> updateItemQuantity(String itemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItem(itemId);
      return;
    }

    // 1. Optimistically update local state
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.id == itemId) {
          return i.copyWith(quantity: newQuantity);
        }
        return i;
      }).toList(),
    );

    // 2. Call PUT /cart/items/:id
    try {
      final repo = ref.read(bookingRepositoryProvider);
      await repo.updateCartItemRemote(
        itemId: itemId,
        quantity: newQuantity,
      );
      // 3. Resync totals from server
      await fetchCart();
    } catch (_) {}
  }

  Future<void> updateItemDateTime(
    String itemId, {
    DateTime? startDate,
    String? startTime,
    String? endTime,
  }) async {
    final dateStr = startDate != null
        ? '${startDate.year.toString().padLeft(4, '0')}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}'
        : null;

    // 1. Optimistically update local state
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.id == itemId) {
          return i.copyWith(
            eventDate: startDate ?? i.eventDate,
            startTime: startTime ?? i.startTime,
            endTime: endTime ?? i.endTime,
          );
        }
        return i;
      }).toList(),
    );

    // 2. Call PUT /cart/items/:id
    try {
      final repo = ref.read(bookingRepositoryProvider);
      await repo.updateCartItemRemote(
        itemId: itemId,
        startDate: dateStr,
        startTime: startTime,
        endTime: endTime,
      );
      // 3. Resync from server
      await fetchCart();
    } catch (_) {}
  }

  Future<void> removeItem(String itemId) async {
    state = state.copyWith(
      items: state.items.where((i) => i.id != itemId).toList(),
    );
    try {
      final repo = ref.read(bookingRepositoryProvider);
      await repo.removeCartItemRemote(itemId);
    } catch (_) {}
  }

  bool applyCoupon(String code) {
    if (code.toUpperCase() == 'SPHERE10') {
      final discount = (state.totalDepositPaise * 0.10).round();
      state =
          state.copyWith(appliedCoupon: 'SPHERE10', discountPaise: discount);
      return true;
    }
    return false;
  }

  void removeCoupon() {
    state = state.copyWith(appliedCoupon: null, discountPaise: 0);
  }

  Future<void> clearCart() async {
    state = const CartState();
    try {
      final repo = ref.read(bookingRepositoryProvider);
      await repo.clearCartRemote();
    } catch (_) {}
  }
}
