import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/network_exception.dart';
import '../../domain/entities/catalog_entities.dart';

class CatalogRemoteDataSource {
  final Dio _dio;
  CatalogRemoteDataSource(this._dio);

  Future<List<Category>> getCategories() async {
    try {
      final res = await _dio.get(ApiConstants.masterCategories);
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List)
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
      if (res.statusCode == 200 && res.data['data'] != null) {
        return (res.data['data'] as List)
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
      if (res.statusCode == 200 && res.data['data'] != null) {
        return (res.data['data'] as List)
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
      if (res.statusCode == 200 && res.data['data'] != null) {
        return (res.data['data'] as List)
            .map((e) => PublicEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    }
  }
}
