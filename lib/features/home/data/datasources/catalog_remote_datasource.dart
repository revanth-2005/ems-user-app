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

  // ── Categories & Subcategories (GET /master/categories) ───────────────────

  Future<List<Category>> getCategories() async {
    try {
      final res = await _dio.get(ApiConstants.masterCategories);
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

  // ── Public Events (GET /catalog/events & /catalog/events/:idOrSlug) ──────────

  Future<List<PublicEvent>> getEvents({
    String? search,
    String? city,
    String? categoryId,
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
      return null;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> registerForEvent({
    required String eventId,
    String? ticketTypeId,
    int quantity = 1,
    String? couponCode,
  }) async {
    try {
      final res = await _dio.post(
        '${ApiConstants.catalogEvents}/$eventId/register',
        data: {
          if (ticketTypeId != null) 'ticketTypeId': ticketTypeId,
          'quantity': quantity,
          if (couponCode != null) 'couponCode': couponCode,
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
}
