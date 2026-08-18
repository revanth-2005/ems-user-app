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

final catalogSortByProvider = StateProvider<String>((_) => 'createdAt_desc');

final minPriceFilterProvider = StateProvider<int?>((_) => null);

final maxPriceFilterProvider = StateProvider<int?>((_) => null);

enum CatalogTab { PACKAGES, SERVICES, ORGANIZERS, EVENTS }

final activeCatalogTabProvider =
    StateProvider<CatalogTab>((_) => CatalogTab.PACKAGES);

// ── Data Providers ────────────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getCategories();
});

final packagesProvider = FutureProvider<List<EventPackage>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final rawCity = ref.watch(selectedCityProvider);
  final city = (rawCity.isEmpty || rawCity == 'All') ? null : rawCity;
  final categoryId = ref.watch(selectedCategoryFilterProvider);
  final subCategoryId = ref.watch(selectedSubCategoryFilterProvider);
  final search = ref.watch(catalogSearchQueryProvider);
  final sortBy = ref.watch(catalogSortByProvider);
  final minPrice = ref.watch(minPriceFilterProvider);
  final maxPrice = ref.watch(maxPriceFilterProvider);

  return repo.getPackages(
    city: city,
    categoryId: categoryId,
    subCategoryId: subCategoryId,
    search: search,
    sortBy: sortBy,
    minPrice: minPrice,
    maxPrice: maxPrice,
  );
});

final servicesProvider = FutureProvider<List<StandaloneService>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final rawCity = ref.watch(selectedCityProvider);
  final city = (rawCity.isEmpty || rawCity == 'All') ? null : rawCity;
  final categoryId = ref.watch(selectedCategoryFilterProvider);
  final subCategoryId = ref.watch(selectedSubCategoryFilterProvider);
  final pricingUnit = ref.watch(selectedPricingUnitFilterProvider);
  final search = ref.watch(catalogSearchQueryProvider);
  final sortBy = ref.watch(catalogSortByProvider);
  final minPrice = ref.watch(minPriceFilterProvider);
  final maxPrice = ref.watch(maxPriceFilterProvider);

  return repo.getServices(
    city: city,
    categoryId: categoryId,
    subCategoryId: subCategoryId,
    pricingUnit: pricingUnit,
    search: search,
    sortBy: sortBy,
    minPrice: minPrice,
    maxPrice: maxPrice,
  );
});

final organizersProvider = FutureProvider<List<OrganizerSummary>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final rawCity = ref.watch(selectedCityProvider);
  final city = (rawCity.isEmpty || rawCity == 'All') ? null : rawCity;
  final search = ref.watch(catalogSearchQueryProvider);

  return repo.getOrganizers(
    city: city,
    search: search,
  );
});

final eventsProvider = FutureProvider<List<PublicEvent>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final rawCity = ref.watch(selectedCityProvider);
  final city = (rawCity.isEmpty || rawCity == 'All') ? null : rawCity;
  final categoryId = ref.watch(selectedCategoryFilterProvider);
  final search = ref.watch(catalogSearchQueryProvider);

  return repo.getEvents(
    city: city,
    categoryId: categoryId,
    search: search,
  );
});

// ── Single Item Detail Providers ──────────────────────────────────────────

final packageDetailProvider =
    FutureProvider.family<EventPackage?, String>((ref, idOrSlug) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getPackageById(idOrSlug);
});

final serviceDetailProvider =
    FutureProvider.family<StandaloneService?, String>((ref, idOrSlug) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getServiceById(idOrSlug);
});

final organizerDetailProvider =
    FutureProvider.family<OrganizerSummary?, String>((ref, id) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getOrganizerById(id);
});

final organizerAvailabilityProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getOrganizerAvailability(id);
});

final eventDetailProvider =
    FutureProvider.family<PublicEvent?, String>((ref, idOrSlug) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getEventById(idOrSlug);
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

  return HomeFeedState(
    categories: cats,
    packages: pkgs,
    services: srvs,
    organizers: orgs,
    events: evts,
  );
});
