import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../app/app_providers.dart';
import '../../data/datasources/catalog_remote_datasource.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../domain/entities/catalog_entities.dart';
import '../../domain/repositories/catalog_repository.dart';

// ── Repository Provider ───────────────────────────────────────────────────

final catalogRemoteDataSourceProvider = Provider<CatalogRemoteDataSource>((ref) {
  final dio = ref.watch(dioClientProvider).dio;
  return CatalogRemoteDataSource(dio);
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepositoryImpl(
    remote: ref.watch(catalogRemoteDataSourceProvider),
  );
});

// ── State Filters ─────────────────────────────────────────────────────────

final selectedCityProvider = StateProvider<String>((_) => 'All');

final selectedCategoryFilterProvider = StateProvider<String?>((_) => null);

final selectedSubCategoryFilterProvider = StateProvider<String?>((_) => null);

final selectedPricingUnitFilterProvider = StateProvider<String?>((_) => null);

final catalogSearchQueryProvider = StateProvider<String>((_) => '');

final catalogSortByProvider = StateProvider<String>((_) => 'priority');

final minPriceFilterProvider = StateProvider<int?>((_) => null);

final maxPriceFilterProvider = StateProvider<int?>((_) => null);

final selectedDateFilterProvider = StateProvider<DateTime?>((_) => null);

final minRatingFilterProvider = StateProvider<double?>((_) => null);

final searchRadiusKmProvider = StateProvider<double>((_) => 50.0);

final userLatProvider = StateProvider<double?>((_) => null);

final userLngProvider = StateProvider<double?>((_) => null);

enum CatalogTab { ALL, PACKAGES, SERVICES, ORGANIZERS, EVENTS }

final activeCatalogTabProvider =
    StateProvider<CatalogTab>((_) => CatalogTab.ALL);

// ── Data Providers ────────────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getCategories();
});

// ── 🌐 Unified Overview Search Provider ───────────────────────────────────────

final unifiedSearchProvider = FutureProvider<UnifiedSearchResult>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final rawCity = ref.watch(selectedCityProvider);
  final city = (rawCity.isEmpty || rawCity == 'All') ? null : rawCity;
  final search = ref.watch(catalogSearchQueryProvider);
  final categoryId = ref.watch(selectedCategoryFilterProvider);
  final subCategoryId = ref.watch(selectedSubCategoryFilterProvider);
  final pricingUnit = ref.watch(selectedPricingUnitFilterProvider);
  final eventMode = ref.watch(selectedEventModeProvider);
  final sortBy = SearchSortBy.fromString(ref.watch(catalogSortByProvider));
  final minPrice = ref.watch(minPriceFilterProvider);
  final maxPrice = ref.watch(maxPriceFilterProvider);
  final minRating = ref.watch(minRatingFilterProvider);
  final radiusKm = ref.watch(searchRadiusKmProvider);
  final lat = ref.watch(userLatProvider);
  final lng = ref.watch(userLngProvider);

  final query = SearchQuery(
    search: search.isNotEmpty ? search : null,
    city: city,
    lat: lat,
    lng: lng,
    radiusKm: radiusKm,
    categoryId: categoryId,
    subCategoryId: subCategoryId,
    pricingUnit: pricingUnit,
    eventMode: eventMode == 'ALL' ? null : eventMode,
    sortBy: sortBy,
    minPrice: minPrice,
    maxPrice: maxPrice,
    minRating: minRating,
    limit: 10,
  );

  return repo.searchUnified(query);
});

// ── 🔍 Instant Autocomplete / Typeahead Provider ─────────────────────────────

final autocompleteSuggestionsProvider =
    FutureProvider.autoDispose.family<AutocompleteResult, String>((ref, query) async {
  if (query.trim().length < 2) return const AutocompleteResult();
  final repo = ref.watch(catalogRepositoryProvider);
  final lat = ref.watch(userLatProvider);
  final lng = ref.watch(userLngProvider);
  return repo.getAutocompleteSuggestions(query, lat: lat, lng: lng, limit: 5);
});

// ── Bundled Packages Provider ────────────────────────────────────────────────

final packagesProvider = FutureProvider<List<EventPackage>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final rawCity = ref.watch(selectedCityProvider);
  final city = (rawCity.isEmpty || rawCity == 'All') ? null : rawCity;
  final categoryId = ref.watch(selectedCategoryFilterProvider);
  final subCategoryId = ref.watch(selectedSubCategoryFilterProvider);
  final search = ref.watch(catalogSearchQueryProvider);
  final sortBy = SearchSortBy.fromString(ref.watch(catalogSortByProvider));
  final minPrice = ref.watch(minPriceFilterProvider);
  final maxPrice = ref.watch(maxPriceFilterProvider);
  final minRating = ref.watch(minRatingFilterProvider);
  final radiusKm = ref.watch(searchRadiusKmProvider);
  final lat = ref.watch(userLatProvider);
  final lng = ref.watch(userLngProvider);

  final query = SearchQuery(
    search: search.isNotEmpty ? search : null,
    city: city,
    lat: lat,
    lng: lng,
    radiusKm: radiusKm,
    categoryId: categoryId,
    subCategoryId: subCategoryId,
    sortBy: sortBy,
    minPrice: minPrice,
    maxPrice: maxPrice,
    minRating: minRating,
  );

  return repo.searchPackages(query);
});

// ── Standalone Services Provider ─────────────────────────────────────────────

final servicesProvider = FutureProvider<List<StandaloneService>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final rawCity = ref.watch(selectedCityProvider);
  final city = (rawCity.isEmpty || rawCity == 'All') ? null : rawCity;
  final categoryId = ref.watch(selectedCategoryFilterProvider);
  final subCategoryId = ref.watch(selectedSubCategoryFilterProvider);
  final pricingUnit = ref.watch(selectedPricingUnitFilterProvider);
  final search = ref.watch(catalogSearchQueryProvider);
  final sortBy = SearchSortBy.fromString(ref.watch(catalogSortByProvider));
  final minPrice = ref.watch(minPriceFilterProvider);
  final maxPrice = ref.watch(maxPriceFilterProvider);
  final minRating = ref.watch(minRatingFilterProvider);
  final radiusKm = ref.watch(searchRadiusKmProvider);
  final lat = ref.watch(userLatProvider);
  final lng = ref.watch(userLngProvider);

  final query = SearchQuery(
    search: search.isNotEmpty ? search : null,
    city: city,
    lat: lat,
    lng: lng,
    radiusKm: radiusKm,
    categoryId: categoryId,
    subCategoryId: subCategoryId,
    pricingUnit: pricingUnit,
    sortBy: sortBy,
    minPrice: minPrice,
    maxPrice: maxPrice,
    minRating: minRating,
  );

  return repo.searchServices(query);
});

// ── Organizers Directory Provider ───────────────────────────────────────────

final organizersProvider = FutureProvider<List<OrganizerSummary>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final rawCity = ref.watch(selectedCityProvider);
  final city = (rawCity.isEmpty || rawCity == 'All') ? null : rawCity;
  final search = ref.watch(catalogSearchQueryProvider);
  final sortBy = SearchSortBy.fromString(ref.watch(catalogSortByProvider));
  final radiusKm = ref.watch(searchRadiusKmProvider);
  final lat = ref.watch(userLatProvider);
  final lng = ref.watch(userLngProvider);

  final query = SearchQuery(
    search: search.isNotEmpty ? search : null,
    city: city,
    lat: lat,
    lng: lng,
    radiusKm: radiusKm,
    sortBy: sortBy,
  );

  return repo.searchOrganizers(query);
});

// ── Event Specific Filters & State ────────────────────────────────────────

final selectedEventModeProvider = StateProvider<String>((_) => 'ALL'); // 'ALL' | 'OFFLINE' | 'ONLINE'

final selectedEventCategoryProvider = StateProvider<String?>((_) => null);

final eventSearchQueryProvider = StateProvider<String>((_) => '');

final eventCategoriesProvider = FutureProvider<List<EventCategory>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getEventCategories();
});

final eventsProvider = FutureProvider<List<PublicEvent>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final rawCity = ref.watch(selectedCityProvider);
  final city = (rawCity.isEmpty || rawCity == 'All') ? null : rawCity;
  final categoryId = ref.watch(selectedEventCategoryProvider);
  final mode = ref.watch(selectedEventModeProvider);
  final search = ref.watch(eventSearchQueryProvider);
  final sortBy = SearchSortBy.fromString(ref.watch(catalogSortByProvider));
  final radiusKm = ref.watch(searchRadiusKmProvider);
  final lat = ref.watch(userLatProvider);
  final lng = ref.watch(userLngProvider);

  final query = SearchQuery(
    search: search.isNotEmpty ? search : null,
    city: city,
    lat: lat,
    lng: lng,
    radiusKm: radiusKm,
    categoryId: categoryId,
    eventMode: mode == 'ALL' ? null : mode,
    sortBy: sortBy,
    limit: 100,
  );

  final list = await repo.searchEvents(query);
  return List<PublicEvent>.from(list.reversed);
});

final eventFeeCalculatorProvider =
    FutureProvider.autoDispose.family<FeeBreakdownModel?, ({String categoryId, double price})>((ref, args) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.calculateEventFee(
    categoryId: args.categoryId,
    price: args.price,
  );
});

// ── Single Item Detail Providers ──────────────────────────────────────────

final packageDetailProvider =
    FutureProvider.autoDispose.family<EventPackage?, String>((ref, idOrSlug) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getPackageById(idOrSlug);
});

final serviceDetailProvider =
    FutureProvider.autoDispose.family<StandaloneService?, String>((ref, idOrSlug) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getServiceById(idOrSlug);
});

final organizerDetailProvider =
    FutureProvider.autoDispose.family<OrganizerSummary?, String>((ref, id) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getOrganizerById(id);
});

final organizerAvailabilityProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getOrganizerAvailability(id);
});

final eventDetailProvider =
    FutureProvider.autoDispose.family<PublicEvent?, String>((ref, idOrSlug) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final direct = await repo.getEventById(idOrSlug);
  if (direct != null) return direct;

  final cachedEvents = ref.watch(eventsProvider).valueOrNull ?? [];
  for (final e in cachedEvents) {
    if (e.id == idOrSlug || e.slug == idOrSlug) {
      return e;
    }
  }
  return null;
});

// ── ⭐ Follow / Unfollow Organizers State & Providers ─────────────────────────

class OrganizerFollowState {
  final bool isFollowed;
  final int followerCount;
  final bool isLoading;

  const OrganizerFollowState({
    required this.isFollowed,
    required this.followerCount,
    this.isLoading = false,
  });

  OrganizerFollowState copyWith({
    bool? isFollowed,
    int? followerCount,
    bool? isLoading,
  }) {
    return OrganizerFollowState(
      isFollowed: isFollowed ?? this.isFollowed,
      followerCount: followerCount ?? this.followerCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class OrganizerFollowArgs {
  final String id;
  final bool initialFollow;
  final int initialFollowerCount;

  const OrganizerFollowArgs({
    required this.id,
    this.initialFollow = false,
    this.initialFollowerCount = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizerFollowArgs &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class OrganizerFollowNotifier extends StateNotifier<OrganizerFollowState> {
  final CatalogRepository _repo;
  final String _organizerId;
  final Ref _ref;

  OrganizerFollowNotifier(
    this._repo,
    this._organizerId,
    this._ref, {
    required bool initialFollow,
    required int initialFollowerCount,
  }) : super(OrganizerFollowState(
          isFollowed: initialFollow,
          followerCount: initialFollowerCount,
        ));

  void syncState(bool isFollowed, int followerCount) {
    if (!state.isLoading && state.isFollowed != isFollowed) {
      state = state.copyWith(
        isFollowed: isFollowed,
        followerCount: followerCount > 0 ? followerCount : state.followerCount,
      );
    }
  }

  Future<void> toggleFollow({
    void Function(String message, {bool isError})? onMessage,
  }) async {
    if (state.isLoading) return;
    final prev = state;
    final nextFollow = !prev.isFollowed;
    final nextCount = nextFollow
        ? (prev.followerCount + 1)
        : (prev.followerCount > 0 ? prev.followerCount - 1 : 0);

    // 1. Immediate optimistic UI state update locally & globally (0ms instant transition)
    state = state.copyWith(
      isFollowed: nextFollow,
      followerCount: nextCount,
      isLoading: true,
    );

    if (nextFollow) {
      _ref.read(followedOrganizerIdsProvider.notifier).add(_organizerId);
    } else {
      _ref.read(followedOrganizerIdsProvider.notifier).remove(_organizerId);
    }

    // Provide immediate optimistic SnackBar feedback
    if (onMessage != null) {
      onMessage(
        nextFollow ? 'Following organizer...' : 'Unfollowed organizer',
        isError: false,
      );
    }

    try {
      final res = await _repo.toggleFollowOrganizer(_organizerId, prev.isFollowed);
      state = OrganizerFollowState(
        isFollowed: res.isFollowed,
        followerCount: res.followerCount >= 0 ? res.followerCount : nextCount,
        isLoading: false,
      );

      if (res.isFollowed) {
        _ref.read(followedOrganizerIdsProvider.notifier).add(_organizerId);
      } else {
        _ref.read(followedOrganizerIdsProvider.notifier).remove(_organizerId);
      }

      // Immediately invalidate followed list so all screens show updated data
      _ref.invalidate(followedOrganizersProvider);

      if (onMessage != null && res.message != null && res.message!.isNotEmpty) {
        onMessage(res.message!, isError: false);
      }
    } catch (e) {
      // Revert optimistic change on network failure
      state = prev;
      if (prev.isFollowed) {
        _ref.read(followedOrganizerIdsProvider.notifier).add(_organizerId);
      } else {
        _ref.read(followedOrganizerIdsProvider.notifier).remove(_organizerId);
      }

      String errorMsg = 'Failed to update follow status';
      final errStr = e.toString();
      if (errStr.contains('401') || errStr.toLowerCase().contains('unauthorized')) {
        errorMsg = 'Please log in to follow organizers';
      } else if (errStr.isNotEmpty) {
        errorMsg = errStr.replaceAll('Exception:', '').trim();
      }
      if (onMessage != null) {
        onMessage(errorMsg, isError: true);
      }
    }
  }
}

final organizerFollowProvider = StateNotifierProvider.autoDispose
    .family<OrganizerFollowNotifier, OrganizerFollowState, OrganizerFollowArgs>(
  (ref, args) {
    final repo = ref.watch(catalogRepositoryProvider);
    return OrganizerFollowNotifier(
      repo,
      args.id,
      ref,
      initialFollow: args.initialFollow,
      initialFollowerCount: args.initialFollowerCount,
    );
  },
);

final followedOrganizersProvider =
    FutureProvider<List<OrganizerSummary>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getFollowedOrganizers();
});

class FollowedOrganizerIdsNotifier extends StateNotifier<Set<String>> {
  FollowedOrganizerIdsNotifier() : super(const <String>{});

  void setIds(Set<String> ids) {
    state = ids;
  }

  void add(String id) {
    state = {...state, id};
  }

  void remove(String id) {
    state = state.where((item) => item != id).toSet();
  }
}

final followedOrganizerIdsProvider =
    StateNotifierProvider<FollowedOrganizerIdsNotifier, Set<String>>((ref) {
  final notifier = FollowedOrganizerIdsNotifier();

  ref.listen<AsyncValue<List<OrganizerSummary>>>(
    followedOrganizersProvider,
    (prev, next) {
      next.whenData((list) {
        notifier.setIds(list.map((o) => o.id).toSet());
      });
    },
    fireImmediately: true,
  );

  return notifier;
});

// ── Home Feed State ───────────────────────────────────────────────────────

class HomeFeedState {
  final List<Category> categories;
  final List<EventPackage> packages;
  final List<StandaloneService> services;
  final List<OrganizerSummary> organizers;
  final List<PublicEvent> events;

  const HomeFeedState({
    required this.categories,
    required this.packages,
    required this.services,
    required this.organizers,
    required this.events,
  });
}

final homeFeedProvider = FutureProvider<HomeFeedState>((ref) async {
  final cats = await ref.watch(categoriesProvider.future);
  final pkgs = await ref.watch(packagesProvider.future);
  final srvs = await ref.watch(servicesProvider.future);
  final orgs = await ref.watch(organizersProvider.future);
  final evts = await ref.watch(eventsProvider.future);

  // Place newest events first so freshly created events appear immediately in hero
  final orderedEvents = List<PublicEvent>.from(evts.reversed);

  return HomeFeedState(
    categories: cats,
    packages: pkgs,
    services: srvs,
    organizers: orgs,
    events: orderedEvents,
  );
});

