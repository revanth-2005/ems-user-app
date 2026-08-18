import '../entities/catalog_entities.dart';

abstract class CatalogRepository {
  Future<List<Category>> getCategories();
  Future<List<EventPackage>> getPackages({String city = 'Mumbai'});
  Future<List<StandaloneService>> getServices({String city = 'Mumbai'});
  Future<List<PublicEvent>> getEvents();
  Future<EventPackage?> getPackageById(String id);
  Future<PublicEvent?> getEventById(String id);
  Future<StandaloneService?> getServiceById(String id);
}
