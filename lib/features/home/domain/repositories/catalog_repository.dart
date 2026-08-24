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

  Future<List<EventCategory>> getEventCategories();

  Future<List<PublicEvent>> getEvents({
    String? search,
    String? city,
    String? categoryId,
    String? mode,
    int page = 1,
    int limit = 20,
  });

  Future<PublicEvent?> getEventById(String idOrSlug);

  Future<FeeBreakdownModel?> calculateEventFee({
    required String categoryId,
    required double price,
  });

  Future<Map<String, dynamic>> registerForEvent({
    required String eventId,
    String? ticketTypeId,
    int quantity = 1,
    String? attendeeNote,
    String? couponCode,
  });

  Future<TicketOrderResponse> createTicketOrder({
    required String eventId,
    required String ticketTypeId,
    int quantity = 1,
    String? attendeeNote,
  });

  Future<Map<String, dynamic>> verifyPayment({
    required String gatewayOrderId,
    required String gatewayPaymentId,
    required String gatewaySignature,
  });

  // ── 🔍 Search & Multi-Dimensional Discovery ─────────────────────────────────

  Future<AutocompleteResult> getAutocompleteSuggestions(
    String query, {
    double? lat,
    double? lng,
    int limit = 5,
  });

  Future<UnifiedSearchResult> searchUnified(SearchQuery query);

  Future<List<EventPackage>> searchPackages(SearchQuery query);

  Future<List<StandaloneService>> searchServices(SearchQuery query);

  Future<List<OrganizerSummary>> searchOrganizers(SearchQuery query);

  Future<List<PublicEvent>> searchEvents(SearchQuery query);

  // ── ⭐ Follow / Unfollow Organizers ─────────────────────────────────────────

  Future<FollowToggleResponse> toggleFollowOrganizer(
    String organizerId,
    bool currentFollowState,
  );

  Future<bool> getFollowStatus(String organizerId);

  Future<List<OrganizerSummary>> getFollowedOrganizers({
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<List<Map<String, dynamic>>> getOrganizerFollowers(
    String organizerId, {
    int page = 1,
    int limit = 20,
  });
}
