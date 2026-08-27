import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../../domain/entities/catalog_entities.dart';

class CatalogRemoteDataSource {
  final Dio _dio;
  CatalogRemoteDataSource(this._dio);

  List<dynamic> _extractList(dynamic data, List<String> possibleKeys) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      for (final key in possibleKeys) {
        if (data[key] is List) return data[key] as List;
      }
      if (data['data'] is List) return data['data'] as List;
      if (data['items'] is List) return data['items'] as List;
      if (data['results'] is List) return data['results'] as List;
    }
    return const [];
  }

  Map<String, dynamic>? _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return data;
    }
    return null;
  }

  // ── Categories & Subcategories (GET /admin/categories & /master/categories) ──

  Future<List<Category>> getCategories() async {
    try {
      Response res;
      try {
        res = await _dio.get(ApiConstants.masterCategories);
      } catch (_) {
        res = await _dio.get('/admin/categories');
      }
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['categories', 'data', 'items']);
        return list
            .whereType<Map<String, dynamic>>()
            .map(Category.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── Bundled Packages (GET /catalog/packages & /catalog/packages/:idOrSlug) ──

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
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search?.trim().isNotEmpty == true) params['search'] = search!.trim();
      if (city?.trim().isNotEmpty == true && city != 'All') params['city'] = city!.trim();
      if (categoryId?.trim().isNotEmpty == true) params['categoryId'] = categoryId!.trim();
      if (subCategoryId?.trim().isNotEmpty == true) params['subCategoryId'] = subCategoryId!.trim();
      if (minPrice != null && minPrice > 0) params['minPrice'] = minPrice;
      if (maxPrice != null && maxPrice > 0) params['maxPrice'] = maxPrice;
      if (sortBy?.trim().isNotEmpty == true) params['sortBy'] = sortBy!.trim();

      final res = await _dio.get(
        ApiConstants.catalogPackages,
        queryParameters: params,
      );
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['packages', 'data', 'items']);
        return list
            .whereType<Map<String, dynamic>>()
            .map(EventPackage.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<EventPackage?> getPackageDetails(String idOrSlug) async {
    try {
      final res = await _dio.get('${ApiConstants.catalogPackages}/$idOrSlug');
      if (res.statusCode == 200) {
        final data = _extractMap(res.data);
        if (data != null) {
          return EventPackage.fromJson(data);
        }
      }
      return null;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── Standalone Services (GET /catalog/services & /catalog/services/:idOrSlug)

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
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search?.trim().isNotEmpty == true) params['search'] = search!.trim();
      if (city?.trim().isNotEmpty == true && city != 'All') params['city'] = city!.trim();
      if (categoryId?.trim().isNotEmpty == true) params['categoryId'] = categoryId!.trim();
      if (subCategoryId?.trim().isNotEmpty == true) params['subCategoryId'] = subCategoryId!.trim();
      if (pricingUnit?.trim().isNotEmpty == true) params['pricingUnit'] = pricingUnit!.trim();
      if (minPrice != null && minPrice > 0) params['minPrice'] = minPrice;
      if (maxPrice != null && maxPrice > 0) params['maxPrice'] = maxPrice;
      if (sortBy?.trim().isNotEmpty == true) params['sortBy'] = sortBy!.trim();

      final res = await _dio.get(
        ApiConstants.catalogServices,
        queryParameters: params,
      );
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['services', 'data', 'items']);
        return list
            .whereType<Map<String, dynamic>>()
            .map(StandaloneService.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<StandaloneService?> getServiceDetails(String idOrSlug) async {
    try {
      final res = await _dio.get('${ApiConstants.catalogServices}/$idOrSlug');
      if (res.statusCode == 200) {
        final data = _extractMap(res.data);
        if (data != null) {
          return StandaloneService.fromJson(data);
        }
      }
      return null;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── Organizers Directory (GET /catalog/organizers & /catalog/organizers/:id) 

  Future<List<OrganizerSummary>> getOrganizers({
    String? search,
    String? city,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search?.trim().isNotEmpty == true) params['search'] = search!.trim();
      if (city?.trim().isNotEmpty == true && city != 'All') params['city'] = city!.trim();

      final res = await _dio.get(
        ApiConstants.catalogOrganizers,
        queryParameters: params,
      );
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['organizers', 'data', 'items']);
        return list
            .whereType<Map<String, dynamic>>()
            .map(OrganizerSummary.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<OrganizerSummary?> getOrganizerDetails(String id) async {
    try {
      final res = await _dio.get('${ApiConstants.catalogOrganizers}/$id');
      if (res.statusCode == 200) {
        final data = _extractMap(res.data);
        if (data != null) {
          return OrganizerSummary.fromJson(data);
        }
      }
      return null;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getOrganizerAvailability(
    String id, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (startDate != null) params['startDate'] = startDate;
      if (endDate != null) params['endDate'] = endDate;

      final res = await _dio.get(
        '${ApiConstants.catalogOrganizers}/$id/availability',
        queryParameters: params,
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return const {};
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── Event Categories (GET /master/event-categories) ─────────────────────────

  Future<List<EventCategory>> getEventCategories() async {
    try {
      final res = await _dio.get(ApiConstants.masterEventCategories);
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['eventCategories', 'categories', 'data', 'items']);
        return list
            .whereType<Map<String, dynamic>>()
            .map(EventCategory.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── Public Events (GET /catalog/events & /catalog/events/:idOrSlug) ──────────

  Future<List<PublicEvent>> getEvents({
    String? search,
    String? city,
    String? categoryId,
    String? mode,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search?.trim().isNotEmpty == true) params['search'] = search!.trim();
      if (city?.trim().isNotEmpty == true && city != 'All') params['city'] = city!.trim();
      if (categoryId?.trim().isNotEmpty == true) params['categoryId'] = categoryId!.trim();
      if (mode?.trim().isNotEmpty == true && mode != 'ALL') params['mode'] = mode!.trim();

      final res = await _dio.get(
        ApiConstants.catalogEvents,
        queryParameters: params,
      );
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['events', 'data', 'items']);
        return list
            .whereType<Map<String, dynamic>>()
            .map(PublicEvent.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<PublicEvent?> getEventDetails(String idOrSlug) async {
    try {
      final res = await _dio.get('${ApiConstants.catalogEvents}/$idOrSlug');
      if (res.statusCode == 200) {
        final data = _extractMap(res.data);
        if (data != null) {
          return PublicEvent.fromJson(data);
        }
      }
      // Fallback: If single event returns 401 (requires auth) or not found, lookup via public catalog
      final list = await getEvents(limit: 50);
      for (final item in list) {
        if (item.id == idOrSlug || item.slug == idOrSlug) {
          return item;
        }
      }
      return null;
    } on DioException catch (e) {
      try {
        final list = await getEvents(limit: 50);
        for (final item in list) {
          if (item.id == idOrSlug || item.slug == idOrSlug) {
            return item;
          }
        }
      } catch (_) {}
      throw NetworkException.fromDioError(e);
    }
  }

  // ── Calculate Ticket Fee & Taxes (GET /catalog/events/calculate-fee) ─────────

  Future<FeeBreakdownModel?> calculateEventFee({
    required String categoryId,
    required double price,
  }) async {
    try {
      final res = await _dio.get(
        ApiConstants.calculateEventFee,
        queryParameters: {
          'categoryId': categoryId,
          'price': price,
        },
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return FeeBreakdownModel.fromJson(res.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── Register for Free Ticket (POST /catalog/events/:id/register) ─────────────

  Future<Map<String, dynamic>> registerForEvent({
    required String eventId,
    String? ticketTypeId,
    int quantity = 1,
    String? attendeeNote,
    String? couponCode,
  }) async {
    try {
      final res = await _dio.post(
        '${ApiConstants.catalogEvents}/$eventId/register',
        data: {
          if (ticketTypeId != null) 'ticketTypeId': ticketTypeId,
          'quantity': quantity,
          if (attendeeNote != null && attendeeNote.isNotEmpty) 'attendeeNote': attendeeNote,
          if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
        },
      );
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return const {};
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── Create Paid Ticket Order (POST /catalog/events/:id/create-ticket-order) ──

  Future<TicketOrderResponse> createTicketOrder({
    required String eventId,
    required String ticketTypeId,
    int quantity = 1,
    String? attendeeNote,
  }) async {
    try {
      final res = await _dio.post(
        '${ApiConstants.catalogEvents}/$eventId/create-ticket-order',
        data: {
          'ticketTypeId': ticketTypeId,
          'quantity': quantity,
          if (attendeeNote != null && attendeeNote.isNotEmpty) 'attendeeNote': attendeeNote,
        },
      );
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data is Map<String, dynamic>) {
        return TicketOrderResponse.fromJson(res.data as Map<String, dynamic>);
      }
      throw const NetworkException('Invalid response from ticket order server');
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── Verify Payment Post-Checkout (POST /payments/verify) ────────────────────

  Future<Map<String, dynamic>> verifyPayment({
    required String gatewayOrderId,
    required String gatewayPaymentId,
    required String gatewaySignature,
  }) async {
    try {
      final res = await _dio.post(
        ApiConstants.verifyPayment,
        data: {
          'gatewayOrderId': gatewayOrderId,
          'gatewayPaymentId': gatewayPaymentId,
          'gatewaySignature': gatewaySignature,
        },
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return const {};
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── 🔍 Instant Typeahead / Autocomplete (GET /search/autocomplete) ─────────

  Future<AutocompleteResult> getAutocompleteSuggestions(
    String query, {
    double? lat,
    double? lng,
    int limit = 5,
  }) async {
    if (query.trim().length < 2) return const AutocompleteResult();
    try {
      final res = await _dio.get(
        ApiConstants.searchAutocomplete,
        queryParameters: {
          'q': query.trim(),
          'limit': limit,
          if (lat != null && lng != null) 'lat': lat,
          if (lat != null && lng != null) 'lng': lng,
        },
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return AutocompleteResult.fromJson(res.data as Map<String, dynamic>);
      }
      return const AutocompleteResult();
    } catch (_) {
      // Don't throw for autocomplete failures, gracefully return empty
      return const AutocompleteResult();
    }
  }

  // ── 🌐 Unified Overview Search (GET /search/unified) ───────────────────────

  Future<UnifiedSearchResult> searchUnified(SearchQuery query) async {
    try {
      final res = await _dio.get(
        ApiConstants.searchUnified,
        queryParameters: query.toQueryParams(),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return UnifiedSearchResult.fromJson(res.data as Map<String, dynamic>);
      }
      return const UnifiedSearchResult();
    } on DioException catch (e) {
      // If unified search is 404/error, fallback to fetching in parallel
      try {
        final pkgs = await getPackages(
          search: query.search,
          city: query.city,
          categoryId: query.categoryId,
          minPrice: query.minPrice,
          maxPrice: query.maxPrice,
          limit: 5,
        );
        final svcs = await getServices(
          search: query.search,
          city: query.city,
          categoryId: query.categoryId,
          pricingUnit: query.pricingUnit,
          minPrice: query.minPrice,
          maxPrice: query.maxPrice,
          limit: 5,
        );
        final orgs = await getOrganizers(
          search: query.search,
          city: query.city,
          limit: 5,
        );
        final evts = await getEvents(
          search: query.search,
          city: query.city,
          categoryId: query.categoryId,
          mode: query.eventMode,
          limit: 5,
        );
        return UnifiedSearchResult(
          totalPackages: pkgs.length,
          totalServices: svcs.length,
          totalOrganizers: orgs.length,
          totalEvents: evts.length,
          packages: pkgs,
          services: svcs,
          organizers: orgs,
          events: evts,
        );
      } catch (_) {}
      throw NetworkException.fromDioError(e);
    }
  }

  // ── 📦 Search Bundled Packages (GET /search/packages) ──────────────────────

  Future<List<EventPackage>> searchPackages(SearchQuery query) async {
    try {
      Response res;
      try {
        res = await _dio.get(
          ApiConstants.searchPackages,
          queryParameters: query.toQueryParams(),
        );
      } catch (_) {
        res = await _dio.get(
          ApiConstants.catalogPackages,
          queryParameters: query.toQueryParams(),
        );
      }
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['packages', 'data', 'items', 'results']);
        return list
            .whereType<Map<String, dynamic>>()
            .map(EventPackage.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── 🛠️ Search Standalone Services (GET /search/services) ───────────────────

  Future<List<StandaloneService>> searchServices(SearchQuery query) async {
    try {
      Response res;
      try {
        res = await _dio.get(
          ApiConstants.searchServices,
          queryParameters: query.toQueryParams(),
        );
      } catch (_) {
        res = await _dio.get(
          ApiConstants.catalogServices,
          queryParameters: query.toQueryParams(),
        );
      }
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['services', 'data', 'items', 'results']);
        return list
            .whereType<Map<String, dynamic>>()
            .map(StandaloneService.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── 🏢 Search Organizers Directory (GET /search/organizers) ────────────────

  Future<List<OrganizerSummary>> searchOrganizers(SearchQuery query) async {
    try {
      Response res;
      try {
        res = await _dio.get(
          ApiConstants.searchOrganizers,
          queryParameters: query.toQueryParams(),
        );
      } catch (_) {
        res = await _dio.get(
          ApiConstants.catalogOrganizers,
          queryParameters: query.toQueryParams(),
        );
      }
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['organizers', 'data', 'items', 'results']);
        return list
            .whereType<Map<String, dynamic>>()
            .map(OrganizerSummary.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── 🎟️ Search Public Events (GET /search/events) ───────────────────────────

  Future<List<PublicEvent>> searchEvents(SearchQuery query) async {
    try {
      Response res;
      try {
        res = await _dio.get(
          ApiConstants.searchEvents,
          queryParameters: query.toQueryParams(),
        );
      } catch (_) {
        res = await _dio.get(
          ApiConstants.catalogEvents,
          queryParameters: query.toQueryParams(),
        );
      }
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['events', 'data', 'items', 'results']);
        return list
            .whereType<Map<String, dynamic>>()
            .map(PublicEvent.fromJson)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── ⭐ Follow / Unfollow Organizer (POST /organizers/:id/follow & unfollow) ─

  Future<FollowToggleResponse> toggleFollowOrganizer(
    String organizerId,
    bool currentFollowState,
  ) async {
    try {
      final endpoint = currentFollowState
          ? ApiConstants.unfollowOrganizer.replaceAll('{id}', organizerId)
          : ApiConstants.followOrganizer.replaceAll('{id}', organizerId);

      Response res;
      try {
        res = await _dio.post(endpoint);
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 404) {
          // Fallback to /catalog/organizers/{id}/follow if mounted under catalog
          final fallback = '/catalog$endpoint';
          res = await _dio.post(fallback);
        } else {
          rethrow;
        }
      }

      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data is Map<String, dynamic>) {
        return FollowToggleResponse.fromJson(res.data as Map<String, dynamic>);
      }
      return FollowToggleResponse(
        isFollowed: !currentFollowState,
        followerCount: 0,
      );
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── ⭐ Check Follow Status (GET /organizers/:id/follow-status) ──────────────

  Future<bool> getFollowStatus(String organizerId) async {
    try {
      final endpoint = ApiConstants.followStatus.replaceAll('{id}', organizerId);
      final res = await _dio.get(endpoint);
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data['isFollowed'] == true || res.data['is_followed'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── ⭐ Get Followed Organizers (GET /users/me/followed-organizers) ──────────

  Future<List<OrganizerSummary>> getFollowedOrganizers({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (search?.trim().isNotEmpty == true) params['search'] = search!.trim();

      final res = await _dio.get(
        ApiConstants.followedOrganizers,
        queryParameters: params,
      );
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['organizers', 'data', 'items']);
        return list.whereType<Map<String, dynamic>>().map((item) {
          if (item['organizer'] is Map<String, dynamic>) {
            return FollowedOrganizerItem.fromJson(item).organizer.toSummary();
          }
          return OrganizerSummary.fromJson(item);
        }).toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  // ── ⭐ Get Organizer Followers (GET /organizers/:id/followers) ─────────────

  Future<List<Map<String, dynamic>>> getOrganizerFollowers(
    String organizerId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final endpoint = ApiConstants.organizerFollowers.replaceAll('{id}', organizerId);
      final res = await _dio.get(
        endpoint,
        queryParameters: {'page': page, 'limit': limit},
      );
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['followers', 'data', 'items']);
        return list.whereType<Map<String, dynamic>>().toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}

