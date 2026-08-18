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

final selectedCityProvider = StateProvider<String>((_) => 'Mumbai');

final selectedCategoryFilterProvider = StateProvider<String?>((_) => null);

final catalogSearchQueryProvider = StateProvider<String>((_) => '');

enum CatalogTab { PACKAGES, SERVICES, EVENTS, ORGANIZERS }

final activeCatalogTabProvider = StateProvider<CatalogTab>((_) => CatalogTab.PACKAGES);

// ── Data Providers ────────────────────────────────────────────────────────

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getCategories();
});

final packagesProvider = FutureProvider<List<EventPackage>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final city = ref.watch(selectedCityProvider);
  return repo.getPackages(city: city);
});

final servicesProvider = FutureProvider<List<StandaloneService>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final city = ref.watch(selectedCityProvider);
  return repo.getServices(city: city);
});

final eventsProvider = FutureProvider<List<PublicEvent>>((ref) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getEvents();
});

// ── Single Item Detail Providers ──────────────────────────────────────────

final packageDetailProvider =
    FutureProvider.family<EventPackage?, String>((ref, id) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getPackageById(id);
});

final eventDetailProvider =
    FutureProvider.family<PublicEvent?, String>((ref, id) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getEventById(id);
});

final serviceDetailProvider =
    FutureProvider.family<StandaloneService?, String>((ref, id) async {
  final repo = ref.watch(catalogRepositoryProvider);
  return repo.getServiceById(id);
});

// ── Home Feed State ───────────────────────────────────────────────────────

class HomeFeedState {
  final List<Category> categories;
  final List<EventPackage> packages;
  final List<StandaloneService> services;
  final List<PublicEvent> events;

  const HomeFeedState({
    required this.categories,
    required this.packages,
    required this.services,
    required this.events,
  });
}

final homeFeedProvider = FutureProvider<HomeFeedState>((ref) async {
  final cats = await ref.watch(categoriesProvider.future);
  final pkgs = await ref.watch(packagesProvider.future);
  final srvs = await ref.watch(servicesProvider.future);
  final evts = await ref.watch(eventsProvider.future);

  return HomeFeedState(
    categories: cats,
    packages: pkgs,
    services: srvs,
    events: evts,
  );
});
