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
  Future<List<EventCategory>> getEventCategories() =>
      _remote.getEventCategories();

  @override
  Future<List<PublicEvent>> getEvents({
    String? search,
    String? city,
    String? categoryId,
    String? mode,
    int page = 1,
    int limit = 20,
  }) =>
      _remote.getEvents(
        search: search,
        city: city,
        categoryId: categoryId,
        mode: mode,
        page: page,
        limit: limit,
      );

  @override
  Future<PublicEvent?> getEventById(String idOrSlug) =>
      _remote.getEventDetails(idOrSlug);

  @override
  Future<FeeBreakdownModel?> calculateEventFee({
    required String categoryId,
    required double price,
  }) =>
      _remote.calculateEventFee(
        categoryId: categoryId,
        price: price,
      );

  @override
  Future<Map<String, dynamic>> registerForEvent({
    required String eventId,
    String? ticketTypeId,
    int quantity = 1,
    String? attendeeNote,
    String? couponCode,
  }) =>
      _remote.registerForEvent(
        eventId: eventId,
        ticketTypeId: ticketTypeId,
        quantity: quantity,
        attendeeNote: attendeeNote,
        couponCode: couponCode,
      );

  @override
  Future<TicketOrderResponse> createTicketOrder({
    required String eventId,
    required String ticketTypeId,
    int quantity = 1,
    String? attendeeNote,
  }) =>
      _remote.createTicketOrder(
        eventId: eventId,
        ticketTypeId: ticketTypeId,
        quantity: quantity,
        attendeeNote: attendeeNote,
      );

  @override
  Future<Map<String, dynamic>> verifyPayment({
    required String gatewayOrderId,
    required String gatewayPaymentId,
    required String gatewaySignature,
  }) =>
      _remote.verifyPayment(
        gatewayOrderId: gatewayOrderId,
        gatewayPaymentId: gatewayPaymentId,
        gatewaySignature: gatewaySignature,
      );

  // ── 🔍 Search & Multi-Dimensional Discovery ─────────────────────────────────

  @override
  Future<AutocompleteResult> getAutocompleteSuggestions(
    String query, {
    double? lat,
    double? lng,
    int limit = 5,
  }) =>
      _remote.getAutocompleteSuggestions(
        query,
        lat: lat,
        lng: lng,
        limit: limit,
      );

  @override
  Future<UnifiedSearchResult> searchUnified(SearchQuery query) =>
      _remote.searchUnified(query);

  @override
  Future<List<EventPackage>> searchPackages(SearchQuery query) =>
      _remote.searchPackages(query);

  @override
  Future<List<StandaloneService>> searchServices(SearchQuery query) =>
      _remote.searchServices(query);

  @override
  Future<List<OrganizerSummary>> searchOrganizers(SearchQuery query) =>
      _remote.searchOrganizers(query);

  @override
  Future<List<PublicEvent>> searchEvents(SearchQuery query) =>
      _remote.searchEvents(query);

  // ── ⭐ Follow / Unfollow Organizers ─────────────────────────────────────────

  @override
  Future<FollowToggleResponse> toggleFollowOrganizer(
    String organizerId,
    bool currentFollowState,
  ) =>
      _remote.toggleFollowOrganizer(organizerId, currentFollowState);

  @override
  Future<bool> getFollowStatus(String organizerId) =>
      _remote.getFollowStatus(organizerId);

  @override
  Future<List<OrganizerSummary>> getFollowedOrganizers({
    int page = 1,
    int limit = 20,
    String? search,
  }) =>
      _remote.getFollowedOrganizers(page: page, limit: limit, search: search);

  @override
  Future<List<Map<String, dynamic>>> getOrganizerFollowers(
    String organizerId, {
    int page = 1,
    int limit = 20,
  }) =>
      _remote.getOrganizerFollowers(organizerId, page: page, limit: limit);
}
