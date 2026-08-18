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

  Future<List<Category>> getCategories() async {
    try {
      final res = await _dio.get(ApiConstants.masterCategories);
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['categories', 'data', 'items']);
        return list
            .map((e) => Category.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<List<EventPackage>> getPackages({String city = 'Mumbai'}) async {
    try {
      final res = await _dio.get(
        ApiConstants.catalogPackages,
        queryParameters: {'city': city},
      );
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['packages', 'data', 'items']);
        return list
            .map((e) => EventPackage.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<List<StandaloneService>> getServices({String city = 'Mumbai'}) async {
    try {
      final res = await _dio.get(
        ApiConstants.catalogServices,
        queryParameters: {'city': city},
      );
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['services', 'data', 'items']);
        return list
            .map((e) => StandaloneService.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }

  Future<List<PublicEvent>> getEvents() async {
    try {
      final res = await _dio.get(ApiConstants.catalogEvents);
      if (res.statusCode == 200) {
        final list = _extractList(res.data, ['events', 'data', 'items']);
        return list
            .map((e) => PublicEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}
