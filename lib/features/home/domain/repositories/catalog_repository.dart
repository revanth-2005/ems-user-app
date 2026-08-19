import '../entities/catalog_entities.dart';

abstract class CatalogRepository {
  Future<List<Category>> getCategories();

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
  });

  Future<EventPackage?> getPackageById(String idOrSlug);

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
  });

  Future<StandaloneService?> getServiceById(String idOrSlug);

  Future<List<OrganizerSummary>> getOrganizers({
    String? search,
    String? city,
    int page = 1,
    int limit = 20,
  });

  Future<OrganizerSummary?> getOrganizerById(String id);

  Future<Map<String, dynamic>> getOrganizerAvailability(
    String id, {
    String? startDate,
    String? endDate,
  });

  Future<List<PublicEvent>> getEvents({
    String? search,
    String? city,
    String? categoryId,
    int page = 1,
    int limit = 20,
  });

  Future<PublicEvent?> getEventById(String idOrSlug);
  Future<Map<String, dynamic>> registerForEvent({
    required String eventId,
    String? ticketTypeId,
    int quantity = 1,
    String? couponCode,
  });
}
