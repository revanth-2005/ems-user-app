import '../../domain/entities/catalog_entities.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_datasource.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogRemoteDataSource _remote;

  CatalogRepositoryImpl({
    required CatalogRemoteDataSource remote,
  }) : _remote = remote;

  @override
  Future<List<Category>> getCategories() => _remote.getCategories();

  @override
  Future<List<EventPackage>> getPackages({
    String? search,
    String? city,
    String? categoryId,
    String? subCategoryId,
    int? minPrice,
    int? maxPrice,
    String? sortBy,
    int page = 1,
    int limit = 20,
  }) =>
      _remote.getPackages(
        search: search,
        city: city,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sortBy: sortBy,
        page: page,
        limit: limit,
      );

  @override
  Future<EventPackage?> getPackageById(String idOrSlug) =>
      _remote.getPackageDetails(idOrSlug);

  @override
  Future<List<StandaloneService>> getServices({
    String? search,
    String? city,
    String? categoryId,
    String? subCategoryId,
    String? pricingUnit,
    int? minPrice,
    int? maxPrice,
    String? sortBy,
    int page = 1,
    int limit = 20,
  }) =>
      _remote.getServices(
        search: search,
        city: city,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        pricingUnit: pricingUnit,
        minPrice: minPrice,
        maxPrice: maxPrice,
        sortBy: sortBy,
        page: page,
        limit: limit,
      );

  @override
  Future<StandaloneService?> getServiceById(String idOrSlug) =>
      _remote.getServiceDetails(idOrSlug);

  @override
  Future<List<OrganizerSummary>> getOrganizers({
    String? search,
    String? city,
    int page = 1,
    int limit = 20,
  }) =>
      _remote.getOrganizers(
        search: search,
        city: city,
        page: page,
        limit: limit,
      );

  @override
  Future<OrganizerSummary?> getOrganizerById(String id) =>
      _remote.getOrganizerDetails(id);

  @override
  Future<Map<String, dynamic>> getOrganizerAvailability(
    String id, {
    String? startDate,
    String? endDate,
  }) =>
      _remote.getOrganizerAvailability(id, startDate: startDate, endDate: endDate);

  @override
  Future<List<PublicEvent>> getEvents({
    String? search,
    String? city,
    String? categoryId,
    int page = 1,
    int limit = 20,
  }) =>
      _remote.getEvents(
        search: search,
        city: city,
        categoryId: categoryId,
        page: page,
        limit: limit,
      );

  @override
  Future<PublicEvent?> getEventById(String idOrSlug) =>
      _remote.getEventDetails(idOrSlug);
}
